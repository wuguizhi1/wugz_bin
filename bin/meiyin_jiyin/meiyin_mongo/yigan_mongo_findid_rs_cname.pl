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
	-o	<fileout>		Output file, forced
	-id	<dirin>			Input dir [./]
	-od	<dirout>		Output dir [./]
	-h	<help>			Help	
USAGE
	print $usage;
	exit;
}

$port=27021;
$susceptibilitydb="susceptibility";
$prodatacol="relations";
$taoxi="RTX_preciManagment";	#$taoxi="RTX_preciManagment";	#$taoxi="RTX_preciPopulation";
$taocan="jibingheji";			#$taocan="nengliheji";			#$taocan="chengrenxiangmuheji";
$dirin||="./";
$dirout||="./";
mkdir $dirout if (! -d $dirout);
$dirout=&AbsolutePath("dir",$dirout);
$dirin=&AbsolutePath("dir",$dirin);

my%rshash;
open(IN,"rs.txt");
while(<IN>){
	chomp;
	next if( $_ eq '' );
	my ($rs) = (split/\t/,$_)[0];
	$rshash{ucfirst(lc($rs))}++;
}
close IN;

open(IN,"rs1.txt");
while(<IN>){
	chomp;
	next if( $_ eq '' );
	my ($rs) = (split/\t/,$_)[0];
	if( not exists $rshash{ucfirst(lc($rs))} ){
		print $rs, "\n";
	}
}
close IN;

exit;


open(OUT,">$dirout/$fileout");
my $mongo = MongoDB::MongoClient->new('host' => '10.0.0.204:'.$port);
my $db = $mongo->get_database($susceptibilitydb);
my $cl = $db->get_collection($prodatacol);

my $key = join("_",$taoxi,$taocan);
my $data = $cl->query({itm => qr/$key/});
my $record; 
my $count=0;
while ($record=$data->next) {$count++;
	my $id=$record->{'itm'};	
	next if ($id !~ /\_/);
	my @unit=split /\_/,$id;
	my $id_ =join("_",$unit[0],$unit[1]);
	next if ( scalar(@unit)!=4 );
	next if ($id_ ne $taoxi || $unit[2] ne $taocan);

	my $rsid = $record->{'rsid'};
	my $cname = $record->{'cname'};
	if( not exists $rshash{$rsid} ){
		print  "$count\t$unit[3]\t$rsid\t$cname\n";
	}else{
		print OUT "$count\t$unit[3]\t$rsid\t$cname\t$rshash{$rsid}\n";
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
