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
my($filein, $fileout, $dirout, $dirin, $port, $susceptibilitydb, $prodatacol, $taoxi, $taocan);
GetOptions (
"help|?"		=> \&USAGE,
"p|port=s"		=> \$port,
"db|database=s"	=> \$susceptibilitydb,
"db1|prodata=s"	=> \$prodatacol,
"x|taoxi=s"		=> \$taoxi,
"c|taocan=s"	=> \$taocan,
"od|dirout=s"    => \$dirout,
"id|dirin=s"     => \$dirin,
"i|filein=s"	=> \$filein,
"o|fileout=s"	=> \$fileout,
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
	-db1	<prodata>		prodatacol [prodata]
	-x	<taoxi>			taoxi [Xclient_jiyinshuoxilie]
	-c	<taocan>		taocan [jibingbanbentaocanheji]
	-i	<filein>		Input file []
	-o	<fileout>		Output file
	-id	<dirin>			Input dir [./]
	-od	<dirout>		Output dir [./]
	-h	<help>			Help	
USAGE
	print $usage;
	exit;
}

$port=27021;
$susceptibilitydb="susceptibility";
$prodatacol="prodata";
$taoxi="RTX_preciManagment";	$taoxi="RTX_preciPopulation";	$taoxi="RTX_preciPopulation";
$taocan="nengliheji";			$taocan="ertongxiangmuheji";	$taocan="chengrenxiangmuheji";
$dirin||="./";
$dirout||="./";
mkdir $dirout if (! -d $dirout);
$dirout=&AbsolutePath("dir",$dirout);
$dirin=&AbsolutePath("dir",$dirin);

open(OUT,">$dirout/$fileout");
my $mongo = MongoDB::MongoClient->new('host' => '10.0.0.204:'.$port);
my $db = $mongo->get_database($susceptibilitydb);
my $cl = $db->get_collection($prodatacol);

my $key = join("_",$taoxi,$taocan);
my $data = $cl->query({_id => qr/$key/});
my $record; my $count=0;
while ($record=$data->next) {$count++;
	my $id=$record->{'_id'};
	next if ($id !~ /\_/);
	my @unit=split /\_/,$id;
	my $id_ =join("_",$unit[0],$unit[1]);
	next if ( scalar(@unit)!=4 );
	next if ($id_ ne $taoxi || $unit[2] ne $taocan);
	my $title = $record->{'CN'}->{'title'};
	if( $id =~ /xishounengli/ or $id =~ /liyongnengli/ ){
		my ($idNew, $titleNew) = ($id, $title);	
		$idNew =~ s/xishounengli/daixienengli/;
		$idNew =~ s/liyongnengli/daixienengli/; 
		$titleNew =~ s/吸收能力/代谢能力/;
		$titleNew =~ s/利用能力/代谢能力/;
		$cl->update({'_id' => $id},{'$set' => {'CN.title'=>$titleNew} },{'upsert' => 1});
		my $TF;
		if( $titleNew eq $title ){			$TF =  "TTTTTT";
		}else{			$TF =  "FFFFFF";		}
		print "$count\t$unit[3]\t$title\t$titleNew\t$TF\n";
	}else{
		print  "###$count\t$unit[3]\t$title\n";
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
