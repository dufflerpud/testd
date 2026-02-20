#!/usr/bin/perl -w
#
#indx#	command.pl - Source for command test
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-19 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Source for command test
########################################################################
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
