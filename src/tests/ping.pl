#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use lib "/usr/local/lib/perl";
use cpi_filename qw( text_to_filename );
use cpi_drivers qw( device_debug );

#device_debug(__FILE__,__LINE__,"Start eval");
#########################################################################
#	Return command to generate data to standard output.		#
#########################################################################
$cpi_drivers::this->{test} = sub
    {
    my( $test ) = @_;
    #device_debug(__FILE__,__LINE__,"Start test");
    #device_debug(__FILE__,__LINE__,"End test");
    return "ping -c 1 $test->{address}";
    };

#########################################################################
#	Do setup work for matching.					#
#########################################################################
$cpi_drivers::this->{parse} = sub
    {
    my( $test, $result ) = @_;
    #device_debug(__FILE__,__LINE__,"Start parse");
    $test->{result} = $result;
    if( $result =~ /time=([0-9\.]+) ms/ms )
	{ $test->{pingtime} = $1; }
    else
        { undef $test->{pingtime}; }
    $test->{summary} =
	( $test->{pingtime}
	? "$test->{pingtime} ms"
	: "ping failed." );
    #device_debug(__FILE__,__LINE__,"End parse");
    return 1;
    };

#########################################################################
#	Return true if ping time was less than constraint.		#
#########################################################################
$cpi_drivers::this->{matches} = sub
    {
    my( $test, $constraint ) = @_;
    #device_debug(__FILE__,__LINE__,"Start matches");
    #device_debug(__FILE__,__LINE__,"Start end");
    return 0 if( ! defined( $test->{pingtime} ) );
    return ( $test->{pingtime} < $constraint ? $test->{summary} : undef );
    };
#########################################################################
#	Returns true if data is readable by this parser.		#
#########################################################################
$cpi_drivers::this->{could_be} = sub
    {
    #device_debug(__FILE__,__LINE__,"Start could_be");
    my( $txt ) = @_;
    #device_debug(__FILE__,__LINE__,"End could_be");
    return
     (	$txt =~ /^([^\s]+) \(([^\s]+)\) at (..:..:..:..:..:..) \[(.*?)\] on (.*)$/ms
     ||	$txt =~ /^([\d\.]+) dev ([^\s]+) lladdr (..:..:..:..:..:..) (.*?)\s*$/ms
     ||	$txt =~ /\w\w-\w\w-\w\w-\w\w-\w\w-\w\w/ )
    };

#########################################################################
#	Read the table from a cut-and-paste HTML table.			#
#	Create an array hashes with info.				#
#########################################################################
$cpi_drivers::this->{read} = sub
    {
    #device_debug(__FILE__,__LINE__,"Start read");
    my( $source_data ) = @_;
    my $last_line;
    my $host_info_p;
    my @host_infos;

    foreach my $ln ( split(/\n/ms,$source_data) )
	{
	#macbook (10.1.0.125) at 98:fe:94:47:c0:14 [ether] on enp6s0
	if( $ln =~ /^([^\s]+) \(([^\s]+)\) at (..:..:..:..:..:..) \[(.*?)\] on (.*)$/ )
	    {
	    $host_info_p =
		{	name	=>	$1,
			ip	=>	$2,
			mac	=>	$3,
			dev	=>	"?",
			state	=>	"?",
			up	=>	"?",
			down	=>	"?",
			media	=>	"?"	};
	    push( @host_infos, $host_info_p );
	    #print "read an arp entry.\n";
	    }
	#10.1.0.134 dev enp6s0 lladdr 70:de:e2:eb:81:0f STALE
	elsif( $ln =~ /^([\d\.]+) dev ([^\s]+) lladdr (..:..:..:..:..:..) (.*?)\s*$/ )
	    {
	    $host_info_p =
		{	name	=>	$1,
			ip	=>	$1,
			dev	=>	$2,
			mac	=>	$3,
			state	=>	$4,
			up	=>	"?",
			down	=>	"?",
			media	=>	"?"	};
	    push( @host_infos, $host_info_p );
	    #print "read an ip neighbors entry.\n";
	    }
	elsif( scalar( split(/-/,$ln) ) == 6 )
	    {
	    $ln =~ s/-/:/g;
	    $ln =~ tr/A-F/a-f/;
	    $host_info_p = { name=>$last_line, mac=>$ln, dev=>"?", state=>"?" };
	    }
	elsif( $ln =~ /^[^\d]*(\d+\.\d+\.\d+\.\d+).*$/ )
	    { $host_info_p->{ip} = $1; }
	elsif( $ln =~ /KB\/s/ && ! $host_info_p->{up} )
	    { $host_info_p->{up} = $ln; }
	elsif( $ln =~ /KB\/s/ && ! $host_info_p->{down} )
	    { $host_info_p->{down} = $ln; }
	elsif( $ln =~ /Wire.*/ )
	    {
	    $ln =~ s/Wireless\(2.4G\)/2.4G/;
	    $ln =~ s/Wireless\(5G\)/2.4G/;
	    $host_info_p->{media} = $ln;
	    push( @host_infos, $host_info_p );
	    #print "read a deco entry.\n";
	    }
	$last_line = $ln;
	}
    #device_debug(__FILE__,__LINE__,"End read");
    return \@host_infos;
    };

#########################################################################
#	Read the table taken from cut-and-pasting the TP-Link DECO	#
#	w6000's	MAC->IP address list.  It would be awesome if you	#
#	read the data more directly.  Dump in a more convenient format.	#
#########################################################################

#########################################################################
#	Create a simple text table from the array of hashes.		#
#########################################################################
$cpi_drivers::this->{text} = sub
    {
    #device_debug(__FILE__,__LINE__,"Start text");
    my ( $host_infos_p ) = @_;
    my @res;
    foreach my $host_info_p ( @{$host_infos_p} )
	{
	push( @res, sprintf("%-15s %017s %-30s %-8s %-8s %s\n",
	    $host_info_p->{ip},
	    $host_info_p->{mac},
	    $host_info_p->{name},
	    $host_info_p->{up},
	    $host_info_p->{down},
	    $host_info_p->{media} ) );
	}
    #device_debug(__FILE__,__LINE__,"End text");
    return &numeric_sort( @res );
    };

#########################################################################
#	Create a simple test array of hashes.				#
#########################################################################
$cpi_drivers::this->{make_test} = sub
    {
    #device_debug(__FILE__,__LINE__,"Start make_test");
    my ( $host_infos_p ) = @_;
    print "host_infos_p=$host_infos_p.\n";
    print Dumper( $host_infos_p );
    my %res;
    foreach my $host_info_p ( @{$host_infos_p} )
	{
	my $name = "ip $host_info_p->{ip}";
	my $id = &cpi_filename::text_to_filename( $name );
	$res{$id} =
	    {
	    name	=>	$name,
	    id		=>	$id,
	    address	=>	$host_info_p->{ip},
	    driver	=>	"ping",
	    every	=>	600,
	    timeout	=>	60,
	    matches	=>	1,
	    media	=>	"testd/$id.txt",
	    simple	=>	[ 100, "green with %r", 1000, "yellow with %r", "red with %r" ],
	    set_screen	=>	[
				100,	&set_screen_std(2),
		    		,1000,	&set_screen_std(3),
		    			,&set_screen_std(4)
				]
	    };
	}
    #device_debug(__FILE__,__LINE__,"End make_test");
    return \%res;
    };

#device_debug(__FILE__,__LINE__,"End eval");
1;
