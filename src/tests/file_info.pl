#!/usr/bin/perl -w
use strict;

use lib "/usr/local/lib/perl";
use cpi_drivers qw( device_debug );

#device_debug(__FILE__,__LINE__,"Start eval");
#########################################################################
#	Return command to generate data to standard output.		#
#########################################################################
$cpi_drivers::this->{test} = sub
    {
    my( $test ) = @_;
    return "file_info -i $test->{file} $test->{to_check}";
    };

#########################################################################
#	    qw(	dev ino mode nlink uid gid rdev size
#		atime mtime ctime blksize blocks	);
#########################################################################
sub printable
    {
    my ( $str ) = @_;
    my( @parts ) = split(/\//,$str);
    my $base64 = pop( @parts );
    my @pieces = map { &compress_decode($_) } @parts;
    $pieces[8] = &timestr( $pieces[8] );
    $pieces[9] = &timestr( $pieces[9] );
    $pieces[10] = &timestr( $pieces[10] );
    return sprintf("%d %d %07o %d %d %d %d %d %s %s %s %d %d %s",@pieces,$base64);
    }

#########################################################################
#	Parse to setup for finding matching.				#
#########################################################################
$cpi_drivers::this->{parse} = sub
    {
    my( $test, $result ) = @_;

    my %file_info;
    foreach my $ln ( split(/\n/ms,$result) )
	{
	if( /^([!+\-\s])\s+([^\s]+)\s+(.*)$/ )
	    {
	    my( $op, $info, $filename ) = @_;
	    my @pieces = split(/\//,$info);
	    grep( $file_info{$filename}{$_}=shift(@pieces),
		qw(	dev ino mode nlink uid gid rdev size
			atime mtime ctime blksize blocks	) );
	    }
	}
    $test->{summary} = "File stat complete";
    return 1;
    };

#########################################################################
#	Return true if a constraint matches.				#
#########################################################################
$cpi_drivers::this->{matches} = sub
    {
    my( $test, $constraint ) = @_;
    my $hostp = $test->{whats_open}{$constraint};

    return undef if( ! $hostp );
    my @hosts = map { $_->{name}||$_->{ip} } @{ $hostp };
    my $ret = join(",",@hosts)
	. " violate"
	. ( scalar(@hosts)==1 ? "s" : "" )
	. " " . $constraint;
    return $ret;
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
    #device_debug(__FILE__,__LINE__,"End show_data")
    };
#device_debug(__FILE__,__LINE__,"End eval");
1;
