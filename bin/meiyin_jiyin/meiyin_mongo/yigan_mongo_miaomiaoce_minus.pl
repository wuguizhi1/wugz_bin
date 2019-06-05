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
my($filein, $fileout, $dirout, $dirin, $port, $susceptibilitydb, $prodatacol, $taoxi, $taocan, $taoxi_taocan);
GetOptions (
"help|h|?"		=> \&USAGE,
"p|port=s"		=> \$port,
"db|database=s"	=> \$susceptibilitydb,
"pd|prodata=s"	=> \$prodatacol,
"x|taoxi=s"		=> \$taoxi,
"c|taocan=s"	=> \$taocan,
"do|dirout=s"	=> \$dirout,
"di|dirin=s"	=> \$dirin,
"fi|filein=s"	=> \$filein,
"fo|fileout=s"	=> \$fileout,
)or &USAGE;
&USAGE unless ($fileout);

sub USAGE {
	my $usage=<<"USAGE";
Program: $0
Version: $version
Contact: $auther<$autheremail>
Usage:
	-p	<port>			port [27021]
	-db	<database>		database [susceptibility]
	-pd	<prodata>		prodatacol [prodata]
	-x	<taoxi>			taoxi [Xclient_jiyinshuoxilie]
	-c	<taocan>		taocan [jibingbanbentaocanheji]
	-fi	<filein>		Input file []
	-fo	<fileout>		Output file
	-di	<dirin>			Input dir [./]
	-do	<dirout>		Output dir [./]
	-h	<help>			Help	
USAGE
	print $usage;
	exit;
}

$port=27021;
$susceptibilitydb="susceptibility";
$prodatacol="relations";

$dirin||="./";
$dirout||="./";
mkdir $dirout if (! -d $dirout);
$dirout=&AbsolutePath("dir",$dirout);
$dirin=&AbsolutePath("dir",$dirin);

$taoxi="MeiYin_xiaotaoxi"; 
$taocan="daquantao";

print "$dirout/$fileout\n";
open(OUT,">$dirout/$fileout");
my $mongo = MongoDB::MongoClient->new('host' => '10.0.0.204:'.$port);
my $db = $mongo->get_database($susceptibilitydb);
my $cl = $db->get_collection($prodatacol);

my $key = join("_",$taoxi,$taocan);
my@disease=("weiai","feiai","ganai","jiazhuangxianai");
my@dis_rs=("Rs1042522","Rs1042522","Rs1042522","Rs1042522");
foreach my$i(0..$#disease){
	my $data = $cl->query({itm => $key."_".$disease[$i], rsid => $dis_rs[$i]}); 
	my $ori; my$count=0;
	while (my $record=$data->next) {	$count++;
		my $id=$record->{'itm'};
		next if ($id !~ /\_/);
		my @unit=split /\_/,$id;
		my $id_ =join("_",$unit[0],$unit[1]);
		next if ( scalar(@unit)!=4 );
		next if ($id_ ne $taoxi || $unit[2] ne $taocan);
		$ori = $record->{'orientation'}; 
	}
	if( $count==1 ){
		$cl->update({itm => $key."_".$disease[$i], rsid => $dis_rs[$i]},{'$set' => {'orientation' => "plus"} },{'upsert' => 1});
		print "$disease[$i]\t$dis_rs[$i]\t$ori => plus\n";
	}
}
close OUT;


sub AbsolutePath
{		#获取指定目录或文件的决定路径
		my ($type,$input) = @_;

		my $return;

		if ($type eq 'dir')
		{
				my $pwd = `pwd`;
				chomp $pwd;
				chdir($input);
				$return = `pwd`;
				chomp $return;
				chdir($pwd);
		}
		elsif($type eq 'file')
		{
				my $pwd = `pwd`;
				chomp $pwd;

				my $dir=dirname($input);
				my $file=basename($input);
				chdir($dir);
				$return = `pwd`;
				chomp $return;
				$return .="\/".$file;
				chdir($pwd);
		}
		return $return;
}
