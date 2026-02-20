#!/usr/bin/perl -w
#
#indx#	watch_file.pl - Source for watch_file test
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
#doc#	Source for watch_file test
########################################################################
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug get_driver );

my $driverp = &get_driver(__FILE__);

#device_debug(__FILE__,__LINE__,"Start eval");

#########################################################################
#	Return command to generate data to standard output.		#
#########################################################################
$driverp->{test} = sub
    {
    my( $test ) = @_;
    #device_debug(__FILE__,__LINE__,"Start test");
    #device_debug(__FILE__,__LINE__,"End test");
    return "stat $test->{file}";
    };

#########################################################################
#	Replaces fork/exec if it exists.				#
#########################################################################
$driverp->{code} = sub
    {
    my( $test ) = @_;
    #device_debug(__FILE__,__LINE__,"Start code");
    if( my @stat_info = stat( $test->{file} ) )
	{
	my %filedata = map { $_, shift(@stat_info) }
	    qw(	dev ino mode nlink uid gid rdev size
		atime mtime ctime blksize blocks	);
	$filedata{mode} &= 07777;
	$test->{filedata} = \%filedata;
	$test->{summary} = "File stat complete";
	}
    else
	{
	$test->{summary} = "File stat failed";
	}
    #device_debug(__FILE__,__LINE__,"End code");
    };

#########################################################################
#	Return true if a constraint matches.				#
#########################################################################
$driverp->{matches} = sub
    {
    my( $test, $constraint ) = @_;
    my @s;

    #device_debug(__FILE__,__LINE__,"Start matches");
    foreach my $varname ( keys %{$test->{filedata}} )
	{
	next if( $constraint !~ /\b$varname\b/ );
	my $value = $test->{filedata}{$varname};
	$constraint =~ s/\b$varname\b/$value/g;
	$value=sprintf("%04o",$value) if( $varname eq "mode" );
	
	push( @s, "$varname=$value" );
	}

    #device_debug(__FILE__,__LINE__,"End matches");
    return ( eval( $constraint ) ? join(" ",@s) : undef );
    };
#device_debug(__FILE__,__LINE__,"End eval");
1;
