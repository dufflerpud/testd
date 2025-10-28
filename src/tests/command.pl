#!/usr/bin/perl -w
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);

#device_debug(__FILE__,__LINE__,"Start eval");

#########################################################################
#	Return command necessary to get data on standard stdout.	#
#########################################################################
$driverp->{test} = sub
    {
    my( $test ) = @_;
    #device_debug(__FILE__,__LINE__,"Start test");
    #device_debug(__FILE__,__LINE__,"End test");
    return $test->{command};
    };

#########################################################################
#	Do setup for matching.						#
#########################################################################
$driverp->{parse} = sub
    {
    my( $test, $result ) = @_;
    #device_debug(__FILE__,__LINE__,"Start parse");
    $test->{summary} = $test->{result} = $result;
    #device_debug(__FILE__,__LINE__,"End parse");
    return 1;
    };

#########################################################################
#	Return true if data matches constraint.				#
#########################################################################
$driverp->{matches} = sub
    {
    my( $test, $constraint ) = @_;
    #device_debug(__FILE__,__LINE__,"Start matches");
    #device_debug(__FILE__,__LINE__,"End matches");
    return ( $test->{result} =~ /$constraint/ms ? $constraint : undef );
    };
#device_debug(__FILE__,__LINE__,"End eval");
1;
