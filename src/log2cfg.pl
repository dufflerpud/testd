#!/usr/local/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
########################################################################
#	(Replace with brief explanation of what this file is or does)
#
#	2024-04-20 - c.m.caldwell@alumni.unh.edu - Created
########################################################################

use strict;
use Data::Dumper;

use lib "/usr/local/lib/perl";
use cpi_file qw( read_file write_file fatal );
use cpi_arguments qw( parse_arguments );
use cpi_drivers qw( get_drivers );

# Put constants here

my $PROJECT = "replace_with_real_name";
my $PROG = ( $_ = $0, s+.*/++, s/\.[^\.]*$//, $_ );
my $TMP = "/tmp/$PROG.$$";
#my $TMP = "/tmp/$PROG";

my $BASEDIR = "%%PROJECTDIR%%";
$BASEDIR = "/usr/local/projects/testd" if( ! -d $BASEDIR );
my $TESTDIR = "$BASEDIR/src/tests";

our %TESTS;
our $current_driver;
our $screen;

our %ONLY_ONE_DEFAULTS =
    (
    "i"	=>	"/dev/stdin",	# Source of log file
    "o"	=>	"/dev/stdout",	# Output or progress if -u
    "t"	=>	"",		# Type of output
    "s"	=>	"",		# Screen to send data to
    "m"	=>	"gen",		# Map log to data for testing
    "v"	=>	""
    );

my %COLORS = (
	1=>"cyan/blue",
	2=>"white/green",
	3=>"black/yellow",
	"*"=>"white/red" );

# Put variables here.

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

#=======================================================================#
#	New code not from prototype.pl					#
#		Should at least include:				#
#			parse_arguments()				#
#			CGI_arguments()					#
#			usage()						#
#=======================================================================#

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $PROG <possible arguments>","",
	"where <possible arguments> is:",
	"    -i <input file>",
	"    -o <output file>",
	"    -t	Type of output",
	"    -s	<screen>",
	"    -m <mode> (gen or list)",
	"    -v (0|1) Verbosity"
	);
    }

#########################################################################
#	Find driver that matches argument.				#
#########################################################################
sub find_driver
    {
    my( $driver_name ) = @_;
    if( my @drivers = grep( $TESTS{$_}{$driver_name}, keys %TESTS ) )
	{
	@drivers = map { $TESTS{$_} } @drivers;
	return ( wantarray() ? @drivers : $drivers[0] );
	}
    &fatal("Unable to find a driver for '$driver_name'");
    }

#########################################################################
#	Print the drivers we know about:				#
#########################################################################
sub list_drivers
    {
    foreach my $driver ( sort keys %TESTS )
        {
	printf("%-20s %s\n",
	    $driver.":", join(" ",sort keys %{$TESTS{$driver}}) );
	}
    }

#########################################################################
#	Figure out which driver supports the input we have and call it.	#
#########################################################################
sub read_data
    {
    my $log_data = &read_file( $ARGS{i} );
    foreach my $driver_p ( &find_driver("could_be") )
	{
	return( &{$driver_p->{read}}($log_data) )
	    if( &{$driver_p->{could_be}}($log_data) );
	}
    &fatal("Unable to identify type of data $ARGS{i} contains.");
    }

#########################################################################
#	We do so often, let's just return a standardized string		#
#	instead of having it in every log2cfg writer.			#
#########################################################################
sub set_screen_std
    {
    my( $argp ) = @_;
    $argp = { priority=>$argp } if( !ref($argp) || ref($argp) ne "HASH" );
    return join(" ","set_screen",
	"-s",	$screen,
	"-i",	"%i",
	"-p",	$argp->{priority},
	"-c",	$argp->{colors}||$COLORS{$argp->{priority}}||$COLORS{"*"},
	"-t",	"'".($argp->{text}||"%n<br>%t:; %r")."'" );
    }

#########################################################################
#	Find the driver for specified type and output in that format.	#
#########################################################################
sub generate_output
    {
    my( $type, $data_p ) = @_;
    $screen = $ARGS{s};
    return &{ (&find_driver($type))->{$type} }( $data_p );
    }

#########################################################################
#	
#########################################################################
sub hash_file
    {
    my( $filename, $data_p ) = @_;
    my $CFG;
    if( ! -f $filename )
	{ $CFG = $data_p; }
    else
	{
	eval( &read_file( $filename ) );
	grep( $CFG->{$_}=$data_p->{$_}, keys %{$data_p} );
	}
    #$Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    my $contents = Data::Dumper->Dump( [ $CFG ], [ qw(CFG) ] );
    $contents =~ s/'([A-Za-z][\w_]*)'(\s*=>)/$1$2/gms;
    &write_file( $filename, $contents );
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

%TESTS = &get_drivers( $TESTDIR );
if( $ARGS{m} eq "list" )
    { &list_drivers(); }
elsif( $ARGS{s} eq "" )
    { &fatal("Screen not defined with -s."); }
else
    {
    $screen = $ARGS{s};
    my $ret = &generate_output( $ARGS{t}, &read_data() );
    if( !ref($ret) || ref($ret) ne "HASH" )
	{ &write_file( $ARGS{o}, $ret ); }
    else
	{ hash_file( $ARGS{o}, $ret ); }
    }

exec("rm -rf $TMP");
