#!/usr/bin/perl -w
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
