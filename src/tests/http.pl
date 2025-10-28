#!/usr/bin/perl -w
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );

#device_debug(__FILE__,__LINE__,"Start eval");
#########################################################################
#	Return command necessary to get data on standard stdout.	#
#########################################################################
$cpi_drivers::this->{test} = sub
    {
    my( $test ) = @_;
    #device_debug(__FILE__,__LINE__,"Start test");
    #device_debug(__FILE__,__LINE__,"End test");
    return "wget -q -O - '$test->{address}'";
    };

#########################################################################
#	Do setup for matching.						#
#########################################################################
$cpi_drivers::this->{parse} = sub
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
$cpi_drivers::this->{matches} = sub
    {
    my( $test, $constraint ) = @_;
    #device_debug(__FILE__,__LINE__,"Start matches");
    #device_debug(__FILE__,__LINE__,"End matches");
    return ( $test->{result} =~ /$constraint/ms ? $constraint : undef );
    };
#device_debug(__FILE__,__LINE__,"End eval");
1;
