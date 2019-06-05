#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use MongoDB;
use JSON;
use Template;
use FindBin qw($Bin);
use File::Basename qw(basename dirname);
use XML::Simple qw(XMLin XMLout);
use utf8;
use Encode;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $BEGIN_TIME=time();
my $version = "1.0.0";
my $auther = "wu guizhi";
my $autheremail = "guizhi.wu\@genetalks.com";
my($filein, $fileout, $dirout, $dirin);
GetOptions (
"help|?"	=> \&USAGE,
"od|out=s"     => \$dirout,
"id|in=s"      => \$dirin,
"i|infile=s"	=> \$filein,
"o|outfile=s"	=> \$fileout,
)or &USAGE;
&USAGE unless ($filein and $fileout);

sub USAGE {
	my $usage=<<"USAGE";
Program: $0
Version: $version
Contact: $auther<$autheremail>
Usage:
	-i	<filein>		Input file
	-o	<fileout>		Output file
	-id	<dirin>			Input dir
	-od	<dirout>		Output dir
	-h	<help>			Help	
USAGE
	print $usage;
	exit;
}

$dirout||="./";
mkdir $dirout if (! -d $dirout);
$dirout=&AbsolutePath("dir",$dirout);
$dirin=&AbsolutePath("dir",$dirin);



