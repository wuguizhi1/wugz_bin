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
$prodatacol="geneFunctionBySet";
$taoxi="RTX";	#$taoxi="RTX_preciManagment";	#$taoxi="RTX_preciPopulation";
$taocan="";			#$taocan="nengliheji";			#$taocan="chengrenxiangmuheji";
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

my (%rs_genefunc, %rs_id);
my $record; 
while ($record=$data->next) {
	my $id=$record->{'_id'};	
	next if ($id !~ /\_/);
	my ($RTX, $preciMP, $jihe, $jibing) = split /\_/,$id;
	next if ( $RTX ne $taoxi );

	my $oriid = $record->{'oriid'};
	next if ( $oriid ne $jibing );

	my ($count_old, $count_new) = (0, 0);
	if( exists $rs_genefunc{$oriid} ){
		my $rs_list = $rs_id{$oriid};
		$count_old = scalar(keys %$rs_list);
#		print "$count_old\told $oriid rsN!\n";
	}
	my $snps = $record->{'CN'}->{'snps'};
	my $title = $record->{'CN'}->{'title'};
	foreach my$rs(keys %$snps){
		$count_new++;
		my $geneName = $snps->{$rs}->{'geneName'};
		my $geneID = $snps->{$rs}->{'geneID'};
		my $geneFunction = $snps->{$rs}->{'geneFunction'};
		push @{$rs_genefunc{$title}{$rs}{"$geneName:$geneID:$geneFunction"}}, $id;
		push @{$rs_id{$title}{$rs}}, $id;
	}
#	print "$count_new\tnew $oriid rsN!\t$id\n";
	if( $count_new != $count_old and $count_old != 0 ){
#		print Dumper $rs_id{$oriid};
	}
}

foreach my$oriid(keys %rs_id){
	my $rs_id_oriid = $rs_id{$oriid};
	foreach my$rs(keys %$rs_id_oriid){
		my$rs_genefunc_id = $rs_genefunc{$oriid}{$rs};
		if( scalar(keys %$rs_genefunc_id) != 1 ){
			foreach my$func(keys %$rs_genefunc_id){
				my @ids = @{$rs_genefunc_id->{$func}};
				my $id = join",", @ids;
				print "$oriid\t$rs\t$id\t$func\n";
			}
		}
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
