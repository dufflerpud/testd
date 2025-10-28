#!/usr/bin/perl -w
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );
use cpi_filename qw( text_to_filename );

#device_debug(__FILE__,__LINE__,"Start eval");
#########################################################################
#	Return command to generate data to standard output.		#
#########################################################################
$cpi_drivers::this->{test} = sub
    {
    my( $test ) = @_;
    return "traceroute $test->{address}";
    };

#########################################################################
#	Do setup work for matching.					#
#########################################################################
$cpi_drivers::this->{parse} = sub
    {
    my( $test, $result ) = @_;
    #device_debug(__FILE__,__LINE__,"Start parse");
    $test->{result} = $result;
    foreach my $ln ( split(/\n/,$result) )
	{
	$ln =~ s/\s+/ /g;
	#traceroute to www.google.com (172.217.13.196), 30 hops max, 60 byte packets
	if( $ln =~ /traceroute to ([^ ]+) \(([^ ]+)\), (\d+) hops max, (\d+) byte packets/ )
	    {
	    $test->{parsed} =
	        {
		dest	=>	$1,
		destip	=>	$2,
		hopmax	=>	$3,
		bytes	=>	$4,
		hops	=>	0
		};
	    }
	# 1  router (10.1.0.1)  0.719 ms  1.021 ms  1.228 ms
	elsif( $ln =~ / *(\d+) ([^ ]+) \((.+)\) ([\d\.]+) ms ([\d\.]+) ms ([\d\.]+) ms/ )
	    {
	    $test->{parsed}{hops}++;
	    push( @{ $test->{parsed}{steps} },
	        {
		ind	=>	$1,
		name	=>	$2,
		ip	=>	$3,
		time0	=>	$4,
		time1	=>	$5,
		time2	=>	$6
		} );
	    }
	elsif( $ln =~ /\*\s+\*\s+\*/ )
	    {
	    $test->{parsed}{timeouts}++;
	    }
	else
	    {
	    print "CMC unknown line [$ln]\n";
	    }
	}
    $test->{summary} = ( $test->{parsed}{hops} ? $test->{parsed}{hops}." hops" : "failure" );
    #device_debug(__FILE__,__LINE__,"End parse");
    return 1;
    };

#########################################################################
#	Return true if packet would take less than equal to the		#
#	number of hops specified.					#
#########################################################################
$cpi_drivers::this->{matches} = sub
    {
    my( $test, $constraint ) = @_;
    #device_debug(__FILE__,__LINE__,"Start matches");
    #device_debug(__FILE__,__LINE__,"End matches");
    return 0 if( ! defined( $test->{parsed}{hops} ) );
    return ( $test->{parsed}{hops} < $constraint ? "$test->{parsed}{hops} hops" : undef );
    };

#########################################################################
#	Return a table based on the parsed data.			#
#########################################################################
$cpi_drivers::this->{show_data} = sub
    {
    my( $test ) = @_;
    #device_debug(__FILE__,__LINE__,"Start show_data");
    my( @s ) = ("<center><table border=1 style='border-collapse:collapse'>");
    push( @s
	,"<tr><th align=left>", $test->{dest}, ":</th>"
	,"<td>", $test->{destip}, "</td>"
	,"<td>", $test->{hopmax}, "</td>"
	,"<td>", $test->{bytes}, "</td>" );
    foreach my $hopp ( @{ $test->{parsed}{steps} } )
	{
	push( @s
	    ,"</tr>\n<tr><th align=right>", $test->{ind},   "</th>"
	    ,"</tr>\n<tr><th align=left>",  $test->{name},  "</th>"
	    ,"</tr>\n<tr><th align=left>",  $test->{ip},    "</th>"
	    ,"</tr>\n<tr><th align=right>", $test->{time0}, "</th>"
	    ,"</tr>\n<tr><th align=right>", $test->{time1}, "</th>"
	    ,"</tr>\n<tr><th align=right>", $test->{time2}, "</th>" );
	}
    push( @s, "</tr>\n</table></center>\n" );
    #device_debug(__FILE__,__LINE__,"End show_data");
    return join("",@s);
    };

#########################################################################
#	Returns true if data is readable by this parser.		#
#########################################################################
$cpi_drivers::this->{could_be} = sub
    {
    my( $txt ) = @_;
    #device_debug(__FILE__,__LINE__,"Start could_be");
    #device_debug(__FILE__,__LINE__,"End could_be");
    return ( $txt =~ /traceroute to / );
    };

#########################################################################
#	Read traceroute logs, possible from script (with \rs in it)	#
#########################################################################
$cpi_drivers::this->{read} = sub
    {
    my ( $current_data ) = @_;
    my $current_route;
    my @res;
    #device_debug(__FILE__,__LINE__,"Start read");
    foreach my $ln ( split(/\n/,$current_data) )
	{
	chomp( $ln );
	if( $ln =~ /^.*traceroute to ([^\s]+)\s+\(([^\s]+?)\)/ )
	    {
	    my %route_dest = ( name=>$1, ip=>$2 );
	    print "name=$1 ip=$2.\n";
	    $current_route = \%route_dest;
	    push( @res, $current_route );
	    }
#                   1        router     (10.1.0.1)  0.690        ms   0.880      ms    0.739     ms
	elsif( $ln =~ /^\s*(\d+)\s+([^\s]+)\s+\(([^\s]+)\)\s+([^\s]+)\s+ms\s+([^\s]+)\s+ms\s+([^\s]+)\s*ms\s*$/ )
	    {
	    my %piece =
		(
		ind	=>	$1,
		name	=>	$2,
		ip	=>	$3,
		time0	=>	$4,
		time1	=>	$5,
		time2	=>	$6
		);
	    push( @{$current_route->{steps}}, \%piece );
	    $current_route->{hops}++;
	    print "hop ind=[$1] name=[$2] ip=[$3] time0=[$4] time1=[$5] time2=[$6] hc=$current_route->{hops}.\n";
	    }
	}
    #device_debug(__FILE__,__LINE__,"End read");
    return \@res;
    };

#########################################################################
#	Print simple output.						#
#########################################################################
$cpi_drivers::this->{text} = sub
    {
    my( $routes_p ) = @_;
    #device_debug(__FILE__,__LINE__,"Start text");
    foreach my $routep ( @{$routes_p} )
    	{
	printf("%s (%s):\n",$routep->{name},$routep->{ip});
	foreach my $stepp ( @{$routep->{steps}} )
	    {
	    printf("%3d %s (%s) %s ms %s ms %s ms\n",
	        $stepp->{ind},
		$stepp->{name},
		$stepp->{ip},
		$stepp->{time0},
		$stepp->{time1},
		$stepp->{time2} );
	    }
	}
    #device_debug(__FILE__,__LINE__,"End text");
    };

#########################################################################
#	Create a simple test array of hashes.				#
#########################################################################
$cpi_drivers::this->{make_test} = sub
    {
    my ( $routes_p ) = @_;
    my %res;
    #device_debug(__FILE__,__LINE__,"Start make_test");
    foreach my $route_p ( @{$routes_p} )
	{
	my $name = "traceroute $route_p->{ip}";
	my $id = &cpi_filename::text_to_filename( $name );
	my %threshholds =
	    (	green	=>	$route_p->{hops}+1,
		yellow	=>	$route_p->{hops}+4	);
	$res{$id} =
	    {
	    name	=>	$name,
	    address	=>	$route_p->{ip},
	    id		=>	$id,
	    driver	=>	"traceroute",
	    every	=>	600,
	    timeout	=>	60,
	    matches	=>	1,
	    media	=>	"testd/$id.txt",
	    simple	=>	[ "Traceroute returned %r" ],
	    set_screen	=>
		[
		$route_p->{hops}+1,	&set_screen_std(2),
		$route_p->{hops}+4,	&set_screen_std(3),
					&set_screen_std(4)
		]
	    };
	}
    #device_debug(__FILE__,__LINE__,"End make_test");
    return \%res;
    };

#device_debug(__FILE__,__LINE__,"End eval");
1;
