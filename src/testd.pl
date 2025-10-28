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

$| = 1;

use POSIX;
use Data::Dumper;

use lib "/usr/local/lib/perl";
use cpi_file qw( read_file write_file append_file fatal echodo );
use cpi_arguments qw( parse_arguments );
use cpi_filename qw( text_to_filename );
use cpi_english qw( nword );
use cpi_sortable qw( numeric_sort );
use cpi_drivers qw( get_drivers );
use cpi_template qw( subst_list );
use cpi_vars;

# Put constants here

my $PROJECT = "testd";
#my $cpi_vars::PROG = ( $_ = $0, s+.*/++, s/\.[^\.]*$//, $_ );
#my $TMP = "/tmp/$cpi_vars::PROG.$$";
#my $TMP = "/tmp/$cpi_vars::PROG";

#my $cpi_vars::BASEDIR = "%%PROJECTDIR%%";
$cpi_vars::BASEDIR = "/usr/local/projects/$cpi_vars::PROG" if( ! -d $cpi_vars::BASEDIR );
my $TESTDIR = "$cpi_vars::BASEDIR/src/tests";
my $RESULTSDIR = "$cpi_vars::BASEDIR/results";
my $LOGSDIR = "$cpi_vars::BASEDIR/logs";
our %TESTS;

our %ONLY_ONE_DEFAULTS =
    (
    "input"	=>	"/dev/stdin",
    "output"	=>	"/dev/stdout",
    "configuration"	=>	"$cpi_vars::BASEDIR/cfg",
    "function"	=>	"set_screen",
    "test"	=>	"",
    "dumpfile"	=>	"",
    "repeat"	=>	1,
    "verbosity"	=>	"0"
    );

my %VERBOSE = ( progress=>1, debug=>2 );
my @all_useful_tests;

our $CFG;

# Put variables here.

our @problems;
our %ARGS;
our @files;
my $exit_stat = 0;

#########################################################################
#	Print message if verbose set correctly.				#
#########################################################################
sub status
    {
    my( $level, @contents ) = @_;
    print &time_stamp(), ": ", @contents, "\n"
	if( $ARGS{verbosity} >= $VERBOSE{$level} );
    }

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
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> is:",
	"    -c <cfg>	Specify config directory ($cpi_vars::BASEDIR/cfg)",
	"    -x 0	Repeat tests (default)",
	"    -x 1	Execute tests only once",
	"    -t <test>	Execute only specified (default all tests)",
	"    -v 0	Verbosity off (default)",
	"    -v 1	Verbosity on"
	);
    }

#########################################################################
#	Read the configuration.						#
#########################################################################
sub read_configuration
    {
    if( -f $ARGS{configuration} )
        {
	&status("debug","[Reading configuration $ARGS{configuration}]");
	eval( &read_file( $ARGS{configuration} ) );
	}
     elsif( -d $ARGS{configuration} )
	{
	my %merged_cfg;
	opendir( D, $ARGS{configuration} ) || &fatal("Cannot opendir($ARGS{configuration}):  $!");
	my @files =
	    grep(-f $_, map {"$ARGS{configuration}/$_"} grep(/^\w.*\.cfg$/, readdir(D)));
	closedir( D );
	foreach my $file ( @files )
	    {
	    &status("debug","[Reading configuration $file]");
	    eval( &read_file($file) );
	    grep( $merged_cfg{$_}=$CFG->{$_}, keys %{$CFG} );
	    }
	$CFG = \%merged_cfg;
	}
    &fatal("CFG did not get defined.") if( ! $CFG );

#    &fatal("Cannot opendir($TESTDIR):  $!")
#	if(!opendir(D,$TESTDIR));
#    my @test_files = map {"$TESTDIR/$_"} grep(/^\w.*\.pl$/,readdir(D));
#    closedir( D );
#
#    foreach my $test_file ( @test_files )
#	{
#	if( $test_file =~ m:.*/(.*?)\.pl$: )
#	    {
#	    our $current_driver = $1;
#	    #my( $test_name ) = $current_driver;
#	    #$test_name = 's/_/ /g';
#	    eval( &read_file($test_file) );
#	    }
#	}
    #%TESTS = &get_drivers( $TESTDIR );
    }

#########################################################################
#	Setup instances							#
#########################################################################
sub setup_instances
    {
    &status("debug","[Setup instances]");
    my $starting_time = time();
    my $instances = 0;
    $ARGS{test} = &text_to_filename($ARGS{test});
    #foreach my $test ( @{$CFG->{tests}} )
    @all_useful_tests = grep( &use_test($_), values %{$CFG} );
    foreach my $test ( @all_useful_tests )
	{
	my $driver		= $test->{driver};
	my $sane_name		= &text_to_filename( $test->{name} );
	$test->{id}		= $sane_name;
	$test->{results}	= "$RESULTSDIR/$sane_name.txt";
	$test->{log}		= "$LOGSDIR/$sane_name.log";
	$test->{next_try}	= ++$starting_time;
	$instances++;
	}
    &status("debug","[",&nword($instances,"instance")," setup]");
    }

#########################################################################
#	Return true if no test specified or test matches specified.	#
#########################################################################
sub use_test
    {
    my( $test ) = @_;
    #print "Reviewing ARGS{test}=$ARGS{test} vs id=$test->{id}.\n";
    my $ret = ( ! $ARGS{test} || ( $ARGS{test} eq &text_to_filename($test->{id}) ) );
#    print "Reviewing ARGS{test}=$ARGS{test} vs id=$test->{id} = ",
#        ( $ret || "UNDEF" ), ".\n";
    return $ret;
    }

#########################################################################
#	Return a time in the format we like.				#
#########################################################################
sub time_stamp
    {
    return strftime("%Y-%m-%d %H:%M:%S", localtime($_[0]||time()));
    }

#########################################################################
#	Initialize each instance, and then loop till there is no more	#
#	work to do.							#
#########################################################################
sub the_loop
    {
    &status("debug","[Starting the loop]");
    my $bot = time();
    #$SIG{CHLD} = "IGNORE";
    my $running = 1;
    my %test_counts = ( started=>0, completed=>0 );
    while( $running )
        {
	my $now = time();
	my $next_check;
	my $last_check;
	#foreach my $test ( @{$CFG->{tests}} )
	foreach my $test ( @all_useful_tests )
	    {
	    if( ! $running )
	        { last; }
	    else
		{
#	    print "i=$test->{id} d=$test->{driver}.\n";
		my $driver = $TESTS{$test->{driver}};
#	    print STDOUT ($test->{results}||"UNDEF"), ": ",
#		    " now=", ($now-$bot),
#		    " pid=", ($test->{pid}||"UNDEF"),
#		    " timeout_at=", ($test->{timeout_at}||0)-$bot,
#		    " next_try=", ($test->{next_try}||0)-$bot,
#		    "\n";
		if( my $pid = $test->{pid} )
		    {
		    my $waiting_flag = 0;
		    if( $pid > 0 )
			{
			my $sig = "TERM";
			my $waiting_flag = 0;
			#while( waitpid($pid,WNOHANG) < 0 )
			while( kill($pid,0) > 0 )
			    {
			    if( $now < $test->{timeout_at} )
				{
				$waiting_flag = 1;
				last;
				}
			    else
				{
				kill($sig,$pid);
				$sig = "KILL";
				sleep(1);
				}
			    }
			}
		    # If we're here and waiting_flag is not set, we have
		    # results, though we may have had to kill the process
		    # to get them.
		    # print "pid=$pid waiting_flag=$waiting_flag.\n";
		    if( $waiting_flag )
			{
			print "Nothing to cleanup (yet).\n";
			}
		    elsif(  $driver->{code}
			 || &{$driver->{parse}}
				( $test, &read_file( $test->{results} ) ) )
			{
			if( $driver->{ $ARGS{function} } )
			    { &{$driver->{ $ARGS{function} } }( $test ); }
			else
			    {
			    my @args = @{$test->{$ARGS{function}}};
			    my @matches;
			    my $possible_template;
			    my $action;

			    while( scalar(@args) >= 2 )
				{
				my $value = &{$driver->{matches}}($test,shift(@args));
				my $template = shift(@args);
				if( defined($value) )
				    {
				    push( @matches, $value );
				    $action = $template if( ! defined( $action ) );
				    last if( $test->{matches} && scalar(@matches) >= $test->{matches} );
				    }
				}
			    my $results = $test->{summary};
			    if( defined($action) )
				{
				my $sep = "; ";
				$results = ( $sep ? join($sep,@matches) : $matches[0] );
				$action =~ s/%r/$results/gms;
				}
			    elsif( @args )
				{
				$action = pop(@args);
				}
			    else
				{ $action = "set_screen -r %i"; }
			    my $when = &time_stamp( $test->{started} );
			    $action = &subst_list( $action,
				"%t",	$when,
				"%i",	$test->{id},
				"%n",	$test->{name},
				"%r",	$results );
			    $action =~ s/; /<br>- /gms;
			    &status("progress",
				"\"$test->{cmd}\" returns \"$results\".");
			    &append_file( $test->{log},
				&time_stamp($now), ": $results\n" );
			    if( $ARGS{function} eq "simple" )
				{ print "[ $action ]\n"; }
			    else
				{ &echodo( $action ); }
			    }

			$test_counts{completed}++;
			if( ! $ARGS{repeat} )
			    { $running=0; last; }
			else
			    {
			    $test->{timeout_at} = 0;
			    $test->{next_try} = $now + $test->{every};
			    $test->{pid} = 0;
			    }
			}
		    }

		my $next_try;
		if( ($next_try = $test->{next_try}) && ! $test->{pid} )
		    {
		    if( $next_try <= $now )
			{
			# Time to start the next test
			my $cmd = &{$driver->{test}}( $test );
			#print __LINE__, " driver test [ $driver->{test} ] returns [$cmd]\n";
			$test->{cmd} = $cmd;
			&status("progress", "\"$cmd\" started.");
			$test->{started} = $now;
			if( $driver->{code} )
			    {
			    &{$driver->{code}}($test);
			    $test->{pid} = -1;
			    }
			else
			    {
			    unlink( "$test->{results}" );
			    if( my $pid = fork() )
				{ $test->{pid} = $pid; }
			    else
				{ exec("$cmd > $test->{results} 2>&1"); }
			    $test->{timeout_at} = $now + $test->{timeout};
			    $test_counts{started}++;
			    }
			$next_try = $now + $test->{every};
			$test->{next_try} = $next_try;
    #		    print STDOUT $test->{pid},
    #			" fn=", $test->{results},
    #			" next_try=", $test->{next_try}-$bot,
    #			" timeout_at=", $test->{timeout_at}-$bot,
    #			" cmd=[$cmd]\n",
    #			"\n";
			}
		    #print "CMC set next_check to $next_try.\n";
		    $next_check = $next_try
			if( $next_try > $now
			 && ( !defined($next_check) || ($next_try<$next_check) ) );
		    $next_check = $test->{timeout_at}
			if( $test->{timeout_at}
			 && $next_check > $test->{timeout_at} );
		    }
		}
	    }
	last if( ! $running || ! $next_check );
	my $time_diff = $next_check - $now;
	$time_diff = 5 if( $time_diff > 30 );
	if( $time_diff > 0 )
	    {
	    &status("debug",
	        sprintf("Sleeping until %s (%d seconds).\n",
		    strftime("%Y-%m-%d %H:%M:%S", localtime($now+$time_diff)),
		    $time_diff ) );
	    sleep( $time_diff );
	    }
	}
    print &nword( $test_counts{started}, "test" ), " started.\n";
    print &nword( $test_counts{completed}, "test" ), " completed.\n";
    &cleanup( 0 );
    &status("debug","[End loop]");
    }

#########################################################################
#	Start the testing.						#
#########################################################################
sub dump_configuration_text
    {
    #foreach my $testp ( @{ $CFG->{tests} } )
    foreach my $testp ( values %{$CFG} )
	{
	printf("%-15s %-10s %-14s %6d %3d %s\n",
	    $testp->{name},
	    $testp->{driver},
	    $testp->{address},
	    $testp->{every},
	    $testp->{timeout},
	    join(" ",@{$testp->{args}}) );
	if( ! $TESTS{$testp->{driver}} )
	    { &fatal("No driver for ".$testp->{driver}."."); }
	else
	    { &{ $TESTS{ $testp->{driver} }{test} }; }
	}
    }

#########################################################################
#	Dump configuration after we've read everything in.		#
#########################################################################
sub dump_configuration
    {
    my( $outfile ) = @_;
    $Data::Dumper::Indent = 1;
    &write_file( $outfile, Data::Dumper->Dump( [ $CFG ], [ qw(CFG) ] ) );
    exit(0);
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

$cpi_vars::VERBOSITY = $ARGS{verbosity};

#print join("\n\t","$cpi_vars::PROG args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

&read_configuration();
%TESTS = &get_drivers( $TESTDIR );
&setup_instances();
&dump_configuration( $ARGS{dumpfile} )		if( $ARGS{dumpfile} );
&the_loop();

#exec("rm -rf $TMP");
