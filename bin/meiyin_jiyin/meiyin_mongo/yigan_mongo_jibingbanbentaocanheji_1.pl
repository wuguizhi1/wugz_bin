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
$prodatacol="prodata";

$dirin||="./";
$dirout||="./";
mkdir $dirout if (! -d $dirout);
$dirout=&AbsolutePath("dir",$dirout);
$dirin=&AbsolutePath("dir",$dirin);

my @update_list;
&load_1();
print "$dirout/$fileout\n";
open(OUT,">$dirout/$fileout");
my $mongo = MongoDB::MongoClient->new('host' => '10.0.0.204:'.$port);
my $db = $mongo->get_database($susceptibilitydb);
my $cl = $db->get_collection($prodatacol);

my $key = join("_",$taoxi,$taocan);
my $data = $cl->query({_id => qr/$key/});
my $record;
while ($record=$data->next) {
	my $id=$record->{'_id'};
	next if ($id !~ /\_/);
	my @unit=split /\_/,$id;
	my $id_ =join("_",$unit[0],$unit[1]);
	next if ( scalar(@unit)!=4 );
	next if ($id_ ne $taoxi || $unit[2] ne $taocan);
	my $dataMJH = $cl->query({_id => $taoxi_taocan."_".$unit[3]});
	my $dataMJHcount = 0;	
	while (my $recordMJH=$dataMJH->next) {
		my $idMJH = $recordMJH->{'_id'};
		foreach my$CN_each(@update_list){
			my $category = $recordMJH->{'CN'}->{$CN_each};	
			print Dumper $CN_each,$category;
			#$cl->update({'_id' => $id},{'$set' => {'CN.'.$CN_each => $category} },{'upsert' => 1});
		}
		$dataMJHcount ++;
	}
	($dataMJHcount==1) or die "find more than one id?\t$id from $taoxi_taocan \n";
	print OUT "$dataMJHcount\t$unit[3]\n";
}
close OUT;

sub load_1{
	$taoxi="RTX_preciManagment";	# to
	$taocan="jibingheji";	
	$taoxi_taocan="Xclient_jiyinshuoxilie_jibingbanbentaocanheji";	# from
	# 转移关键字：归类信息，单项健康建议，图片，简介，体检规则，饮食规则
	@update_list=("category", "suggestion", "pic", "summary", "healthyrule", "nutritionrule");
}
sub load_2{
	$taoxi="RTX_preciPopulation";
	$taocan="ertongxiangmuheji";	
	$taoxi_taocan="GJH_xiaotaoxi_kuaileertongtaocan";
	# 转移关键字：归类信息，单项健康建议，图片，简介，特性，影响因素，干预方案，参考文献
	@update_list=("category", "suggestion", "pic", "summary", "character", "influfac", "intervene", "references");
}


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
