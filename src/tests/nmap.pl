#!/usr/bin/perl -w
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );
use cpi_filename qw( text_to_filename );

our $screen;

#Starting Nmap 7.92 ( https://nmap.org ) at 2024-07-29 10:07 EDT
#Nmap scan report for ws0 (10.1.0.30)
#Host is up (0.00081s latency).
#Not shown: 845 closed tcp ports (conn-refused), 147 filtered tcp ports (no-response), 7 filtered tcp ports (host-unreach)
#PORT   STATE SERVICE
#22/tcp open  ssh
#MAC Address: 1C:69:7A:99:B1:AA (EliteGroup Computer Systems)
#Nmap done: 1 IP address (1 host up) scanned in 2.19 seconds

#device_debug(__FILE__,__LINE__,"Start eval");
#########################################################################
#	Return command to generate data to standard output.		#
#########################################################################
$cpi_drivers::this->{test} = sub
    {
    my( $test ) = @_;
    #device_debug(__FILE__,__LINE__,"Start test");
    #device_debug(__FILE__,__LINE__,"End test");
    return( $test->{file} ? "cat $test->{file}" : "nmap -sT $test->{address}" );
    #return "nmap -sT $test->{address}";
    };

##########################################################################
##	Parse to setup for finding matching.				#
##########################################################################
#$cpi_drivers::this->{parse} = sub
#    {
#    my( $test, $result ) = @_;
#    my %whats_open;
#    my $host_name;
#    my $host_ip;
#    my $host_ptr;
#
#    #device_debug(__FILE__,__LINE__,"Start parse");
#    return "white/red timeout" if(/scan report/ms);
#
#    foreach my $ln ( split(/\n/ms,$result) )
#	{
#	if( $ln =~ /scan report for\s+(.*)\s+\(([\d\.]+)\)$/ )
#	    {
#	    $host_name	= $1;
#	    $host_ip	= $2;
#	    $host_ptr	= { name=>$host_name, ip=>$host_ip };
#	    }
#	elsif( $ln =~ /Host is up \((.*)\s+latency\)/ )
#	    { $host_ptr->{ latency } = $1; }
#	elsif( $ln =~ /MAC Address:\s+(.*?)\s+/ )
#	    { $host_ptr->{ mac } = $1; }
#	elsif( $ln =~ /^(\d+)\/(\w+)\s+(\w+)\s+(\w+)$/ )
#	    {
#	    my( $portnum, $portprot, $state, $porttext ) = ($1,$2,$3,$4);
#	    next if( $state ne "open" );
#	    push( @{$whats_open{$portnum}},		$host_ptr );
#	    push( @{$whats_open{"$portnum/$portprot"}},	$host_ptr );
#	    push( @{$whats_open{$porttext}},		$host_ptr );
#	    }
#	}
#    $test->{whats_open} = \%whats_open;
#   #device_debug(__FILE__,__LINE__,"End parse");
#    return 1;
#    };

#########################################################################
#	Return true if a constraint matches.				#
#########################################################################
$cpi_drivers::this->{matches} = sub
    {
    my( $test, $constraint ) = @_;
    #device_debug(__FILE__,__LINE__,"Start matches");
    my $hostp = $test->{whats_open}{$constraint};

    return undef if( ! $hostp );
    my @hosts = map { $_->{name}||$_->{ip} } @{ $hostp };
    my $ret = join(",",@hosts)
	. " violate"
	. ( scalar(@hosts)==1 ? "s" : "" )
	. " " . $constraint;
    #device_debug(__FILE__,__LINE__,"End matches");
    return $ret;
    };

#########################################################################
#	Parse to setup for finding matching.				#
#########################################################################
$cpi_drivers::this->{parse} = sub
    {
    my( $test, $result ) = @_;
    my %hostinfo;
    my $host_ptr;
    my %whats_open;

    #device_debug(__FILE__,__LINE__,"Start parse");
    #return "white/red timeout" if(/scan report/ms);

    foreach my $ln ( split(/\n/ms, &read_file("ip neigh|") ) )
	{
	#10.1.0.111 dev enp6s0 lladdr b8:16:5f:cf:9f:c2 STALE
	if( $ln =~ /^\s*([\d\.]+)\s+dev\s+(\w+)\s+lladdr\s+([0-9a-f:]+)\s+(.*?)\s*$/ )
	    {
	    $host_ptr = ( $hostinfo{$1} ||= {} );
	    $host_ptr->{ip} = $1;
	    $host_ptr->{device} = $2;
	    $host_ptr->{mac} = $3;
	    $host_ptr->{state} = $4;
	    }
	}

    foreach my $ln ( split(/\n/ms,$result) )
	{
	#Nmap scan report for printer0 (10.1.0.10)
	if( $ln =~ /scan report for\s+([^\s]+)\s+\(([\d\.]+)\)$/ )
	    {
	    $host_ptr = ( $hostinfo{$2} ||= {} );
	    $host_ptr->{name} = $1;
	    $host_ptr->{ip} = $2;
	    }
	elsif( $ln =~ /scan report for\s+([\d\.]+)$/ )
	    {
	    $host_ptr = ( $hostinfo{$1} ||= {} );
	    $host_ptr->{ip} = $1;
	    $host_ptr->{name} = $1;
	    $host_ptr->{ip} = $1;
	    }
	elsif( $ln =~ /Host is up \((.*)\s+latency\)/ )
	    { $host_ptr->{ latency } = $1; }
	elsif( $ln =~ /MAC Address:\s+(.*?)\s+/ )
	    { $host_ptr->{ mac } = $1; }
	elsif( $ln =~ /^(\d+)\/(\w+)\s+(\w+)\s+([^\s]+)$/ )
	    {
	    my( $portnum, $portprot, $state, $porttext ) = ($1,$2,$3,$4);
	    next if( $state ne "open" );
	    push( @{$whats_open{$portnum}},				$host_ptr );
	    push( @{$whats_open{"$portnum/$portprot"}},			$host_ptr );
	    push( @{$whats_open{"$portnum/$portprot/$porttext"}},	$host_ptr );
	    push( @{$whats_open{$porttext}},				$host_ptr );
	    }
	}
    $test->{whats_open} = \%whats_open;
    $test->{summary} = "Portscan complete";
    #device_debug(__FILE__,__LINE__,"End parse");
    return 1;
    };

#########################################################################
#	Print table.							#
#########################################################################
$cpi_drivers::this->{show_data} = sub
    {
    my ( $test ) = @_;
    my %hosts_in_use;
    my %ports_in_use;
    my %in_use;
    #device_debug(__FILE__,__LINE__,"Start show_data");
    foreach my $k ( keys %{$test->{whats_open}} )
	{
	next if( $k !~ /^(.*)\/(.*)\/(.*)$/ );
	$ports_in_use{"$1/$2"} = $3;
	foreach my $hp ( @{$test->{whats_open}{$k}} )
	    {
	    my $host_id = $hp->{ip};
	    $hosts_in_use{$host_id}= $hp;
	    $in_use{"$host_id/$1/$2"} = 1;
	    }
	}
    my @ports = &numeric_sort( keys %ports_in_use );
    my @hosts = &numeric_sort( keys %hosts_in_use );
    my( @s ) = ( "<html><head></head><body><center><table border=1 style='border-collapse:collapse'>\n<tr><td></td>" );
    push( @s, map {"<th>$_<br>$ports_in_use{$_}</th>"} @ports );
    foreach my $h ( @hosts )
	{
	push( @s, "</tr>\n<tr><th align=left>$h" );
	push( @s, "<br>$hosts_in_use{$h}{name}" )
	    if( $hosts_in_use{$h}{name} && $hosts_in_use{$h}{name} ne $h );
	push( @s, "<br>$hosts_in_use{$h}{mac}" ) if( $hosts_in_use{$h}{mac} );
	push( @s, "</th>" );
        foreach my $p ( @ports )
	    { 
	    if( $in_use{"$h/$p"} )
		{
		push(@s,"<td bgcolor=red>",$hosts_in_use{$h}{name},
		    "<br>",$ports_in_use{$p},"</td>");
		}
	    else
		{ push(@s,"<td>&nbsp;</td>"); }
	    }
	}
    push( @s, "</tr>\n</table></center><body></html>\n" );
    print join("",@s);
    #device_debug(__FILE__,__LINE__,"End show_data");
    };

#########################################################################
#	Returns true if data is readable by this parser.		#
#########################################################################
$cpi_drivers::this->{could_be} = sub
    {
    my( $txt ) = @_;
    #device_debug(__FILE__,__LINE__,"Start could_be");
    #device_debug(__FILE__,__LINE__,"End could_be");
    return ( $txt =~ /scan report for/ );
    };

#########################################################################
#	Parse to setup for finding matching.				#
#########################################################################
$cpi_drivers::this->{read} = sub
    {
    my( $result ) = @_;
    my %hostinfo;
    my $host_ptr;
    my %whats_open;

    #device_debug(__FILE__,__LINE__,"Start read");
    #return "white/red timeout" if(/scan report/ms);

    foreach my $ln ( split(/\n/ms, &read_file("ip neigh|") ) )
	{
	#10.1.0.111 dev enp6s0 lladdr b8:16:5f:cf:9f:c2 STALE
	if( $ln =~ /^\s*([\d\.]+)\s+dev\s+(\w+)\s+lladdr\s+([0-9a-f:]+)\s+(.*?)\s*$/ )
	    {
	    $host_ptr = ( $hostinfo{$1} ||= {} );
	    $host_ptr->{ip} = $1;
	    $host_ptr->{device} = $2;
	    $host_ptr->{mac} = $3;
	    $host_ptr->{state} = $4;
	    }
	}

    foreach my $ln ( split(/\n/ms,$result) )
	{
	#Nmap scan report for printer0 (10.1.0.10)
	if( $ln =~ /scan report for\s+([^\s]+)\s+\(([\d\.]+)\)$/ )
	    {
	    $host_ptr = ( $hostinfo{$2} ||= {} );
	    $host_ptr->{name} = $1;
	    $host_ptr->{ip} = $2;
	    }
	elsif( $ln =~ /scan report for\s+([\d\.]+)$/ )
	    {
	    $host_ptr = ( $hostinfo{$1} ||= {} );
	    $host_ptr->{ip} = $1;
	    $host_ptr->{name} = $1;
	    $host_ptr->{ip} = $1;
	    }
	elsif( $ln =~ /Host is up \((.*)\s+latency\)/ )
	    { $host_ptr->{ latency } = $1; }
	elsif( $ln =~ /MAC Address:\s+(.*?)\s+/ )
	    { $host_ptr->{ mac } = $1; }
	elsif( $ln =~ /^(\d+)\/(\w+)\s+(\w+)\s+([^\s]+)$/ )
	    {
	    my( $portnum, $portprot, $state, $porttext ) = ($1,$2,$3,$4);
	    next if( $state ne "open" );
	    push( @{$whats_open{$portnum}},				$host_ptr );
	    push( @{$whats_open{"$portnum/$portprot"}},			$host_ptr );
	    push( @{$whats_open{"$portnum/$portprot/$porttext"}},	$host_ptr );
	    push( @{$whats_open{$porttext}},				$host_ptr );
	    }
	}
    #device_debug(__FILE__,__LINE__,"End read");
    return \%whats_open;
    };

#########################################################################
#	Print table.							#
#########################################################################
$cpi_drivers::this->{html} = sub
    {
    my ( $whats_open_p ) = @_;
    my %hosts_in_use;
    my %ports_in_use;
    my %in_use;
    #device_debug(__FILE__,__LINE__,"Start html");
    foreach my $k ( keys %{$whats_open_p} )
	{
	next if( $k !~ /^(.*)\/(.*)\/(.*)$/ );
	$ports_in_use{"$1/$2"} = $3;
	foreach my $hp ( @{$whats_open_p->{$k}} )
	    {
	    my $host_id = $hp->{ip};
	    $hosts_in_use{$host_id}= $hp;
	    $in_use{"$host_id/$1/$2"} = 1;
	    }
	}
    my @ports = &numeric_sort( keys %ports_in_use );
    my @hosts = &numeric_sort( keys %hosts_in_use );
    my( @s ) = ( "<html><head></head><body><center><table border=1 style='border-collapse:collapse'>\n<tr><td></td>" );
    push( @s, map {"<th>$_<br>$ports_in_use{$_}</th>"} @ports );
    foreach my $h ( @hosts )
	{
	push( @s, "</tr>\n<tr><th align=left>$h" );
	push( @s, "<br>$hosts_in_use{$h}{name}" )
	    if( $hosts_in_use{$h}{name} && $hosts_in_use{$h}{name} ne $h );
	push( @s, "<br>$hosts_in_use{$h}{mac}" ) if( $hosts_in_use{$h}{mac} );
	push( @s, "</th>" );
        foreach my $p ( @ports )
	    { 
	    if( $in_use{"$h/$p"} )
		{
		push(@s,"<td bgcolor=red>",$hosts_in_use{$h}{name},
		    "<br>",$ports_in_use{$p},"</td>");
		}
	    else
		{ push(@s,"<td>&nbsp;</td>"); }
	    }
	}
    push( @s, "</tr>\n</table></center><body></html>\n" );
    #device_debug(__FILE__,__LINE__,"End html");
    return join("",@s);
    };

#########################################################################
#	Print table.							#
#########################################################################
$cpi_drivers::this->{text} = sub
    {
    my ( $whats_open_p ) = @_;
    my %hosts_in_use;
    my %ports_in_use;
    my %in_use;
    my %width = ( "host_id" => 0 );
    #device_debug(__FILE__,__LINE__,"Start text");
    foreach my $k ( keys %{$whats_open_p} )
	{
	next if( $k !~ /^(.*)\/(.*)\/(.*)$/ );
	my $portprot = "$1/$2";
	$ports_in_use{$portprot} = $3;
	$width{$portprot} = length($portprot);
	$width{$portprot} = $_ if( ($_=length($3)) > $width{$portprot} );
	foreach my $hp ( @{$whats_open_p->{$k}} )
	    {
	    my $host_id = $hp->{ip};
	    $hosts_in_use{$host_id}= $hp;
	    $in_use{"$host_id/$1/$2"} = 1;
	    $width{host_id} = $_ if( ($_=length($host_id)) > $width{host_id} )
	    }
	}
    my @ports = &numeric_sort( keys %ports_in_use );
    my @hosts = &numeric_sort( keys %hosts_in_use );
    grep( $width{$_}=-1-$width{$_}, keys %width );
    my( @s ) = sprintf("%*s",$width{host_id},"");
    push( @s, (map {sprintf("%*s",$width{$_},$ports_in_use{$_})} @ports) );
    foreach my $h ( @hosts )
	{
	push( @s, "\n", sprintf( "%*s", $width{host_id}, $h ) );
        foreach my $p ( @ports )
	    { 
	    push( @s, sprintf("%*s",$width{$p},($in_use{"$h/$p"}?"*":" ") ) );
	    }
	}
    push( @s, "\n" );
    #device_debug(__FILE__,__LINE__,"End text");
    return join("",@s);
    };

#########################################################################
#	Create a test from the tests in the log.			#
#########################################################################
$cpi_drivers::this->{make_test} = sub
    {
    my ( $whats_open_p ) = @_;
    my %res;
    #device_debug(__FILE__,__LINE__,"Start make_test");
    foreach my $k ( keys %{$whats_open_p} )
	{
	next if( $k !~ /^(.*)\/(.*)\/(.*)$/ );
	my( $port, $prot, $name ) = ( $1, $2, $3 );
	foreach my $hp ( @{$whats_open_p->{$k}} )
	    {
	    my $host_id = $hp->{ip};
	    my $name = "nmap $host_id";
	    #my $name = "${current_driver} $host_id";
	    my $id = &cpi_filename::text_to_filename( $name );
	    $res{$id} =
		{
		name	=>	$name,
		address	=>	$host_id,
		id	=>	$id,
		driver	=>	"nmap",
		every	=>	600,
		timeout	=>	60,
		matches	=>	100,
	        media	=>	"testd/$id.txt",
		simple	=>	[ "25/tcp", "red with %r", "22/tcp", "yellow with %r", "green" ],
		set_screen =>	[
				"25/tcp,53/tcp,80/tcp,1900/tcp"
					,&set_screen_std(4)
				,"22/tcp"
					,&set_screen_std(3)
					#,"set_screen -s$screen -i%i -p1 -c'white/green' -t'%n<br>%t:; ALL GOOD'"
				]
		};
	    }
	}
    #device_debug(__FILE__,__LINE__,"End make_test");
    return \%res;
    };

#device_debug(__FILE__,__LINE__,"End eval");
1;
