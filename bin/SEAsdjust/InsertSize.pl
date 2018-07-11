#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $BEGIN_TIME=time();
my $version="1.0.0";
#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my (@bam_info, $fkey, $outdir);
my $max_x = 400;
GetOptions(
				"help|?" =>\&USAGE,
				"i:s{,}"=>\@bam_info,
				"m:s"=>\$max_x,
				"k:s"=>\$fkey,
				"od:s"=>\$outdir,
				) or &USAGE;
&USAGE unless (@bam_info and $fkey);
$outdir||="./";
mkdir $outdir if (! -d $outdir);
$outdir=AbsolutePath("dir",$outdir);

my $fsize="$outdir/$fkey.size.txt";
`rm $fsize` if(-f $fsize);
foreach my $bam_info(@bam_info){
	my ($s, $bam)=split /:/, $bam_info;
	
	my $cmd ="samtools view -f 0x40 -F 0x800 $bam | perl -ane '{if(\$F[8]!=0 && abs(\$F[8])<$max_x){print \"$s\",\"\\t\",abs(\$F[8]),\"\\n\"}}' >>$fsize";
	print "$cmd\n";
	`$cmd`;
}
my $cmdR = `Rscript $Bin/InsertSize.r 200 1000 $fsize $fsize.adjust.txt`;
print $cmdR,"\n";

#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
sub AbsolutePath
{		#获取指定目录或文件的决定路径
        my ($type,$input) = @_;

        my $return;
	$/="\n";

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

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}


sub USAGE {#
	my $usage=<<"USAGE";
Program:
Version: $version
Contact: zeng huaping<huaping.zeng\@genetalks.com> 

Usage:
  Options:
  -i     <str,>   bam infos, "sampleName:bamFile", forced
  -m     <int>    max x, [400]
  -k     <str>    key of output file, forced
  -od    <dir>    output dir, optional

  -h                     Help

USAGE
	print $usage;
	exit;
}

