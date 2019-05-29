#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Data::Dumper;
my $BEGIN_TIME=time();
my $version="1.0.0";
####################################################################
# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my($bamfile,$outdir,$outfile);
my($illumina_len,$min_count,$RefGenome,$print_type,$print_N);
GetOptions(
		"help|?"	=>\&USAGE,
		"i:s"		=>\$bamfile,
		"o:s"   	=>\$outfile,
		"d:s"   	=>\$outdir,
		"len:s"		=>\$illumina_len,
		"minc:s"	=>\$min_count,
		"ref:s"		=>\$RefGenome,
		"p:s"		=>\$print_type,
		"pN:s"		=>\$print_N,
) or &USAGE;
&USAGE unless defined($bamfile and $outfile);
if( not defined $illumina_len ){	$illumina_len = 600; }
if( not defined $min_count ){		$min_count = 10;	}
if( not defined $print_type ){  	$print_type = 0; }
if( not defined $print_N ){			$print_N = 0; }
if( not defined $RefGenome ){   	$RefGenome = "/data/bioit/biodata/duyp/bin/hg19/hg19.fasta"; }
if( not defined $outdir ){			$outdir = "./"; }
`mkdir $outdir` unless (-d $outdir);
$outdir=&AbsolutePath("dir",$outdir);

my ( %alt_all, %each_pos_ids, %each_pos_IDM, %count_company );
open( OUT,">$outfile");
&SHOW_TIME("$bamfile\nstart"); ##
&read_bam_window($bamfile);
&SHOW_TIME("read"); ##
&check_and_print($bamfile);
&SHOW_TIME("end"); ##
close OUT;

print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";

####################################################################
# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
sub USAGE{
	my $usage=<<"USAGE";
	Program: $0
	Version: $version
	Contact:Wu guizhi<guizhi.wu\@genetalks.com> 

	Usage:
	  Options:
	  	-i	<file>	Input bam file, forced
	  	-o	<file>	Output file, forced
	  	-d	<str>	Outdir, [./]
		-len	<int>	illumina_len, default 80
		-minc	<int>	min_count, default 10
		-window	<str>	window ,default 1 [0:no] [1:yes]
		-chr	<str>	Chr, default chr17
		-s	<int>	Start, default 1000
		-e	<int>	End, default 50000000
		-ref	<str>	RefGenome, default /data/bioit/biodata/duyp/bin/hg19/hg19.fasta
	  	-p	<int>   Print info in detail, default 0 [0:no] [1:yes]
		-pN	<int>	print_N, default 0 [0:no] [1:yes]
	  	-h		 		Help

USAGE
	print $usage;
	exit;
}
sub AbsolutePath{		
	#获取指定目录或文件的决定路径
	my ($type,$input) = @_;
	my $return;
	if ($type eq 'dir'){
		my $pwd = `pwd`;
		chomp $pwd;
		chdir($input);
		$return = `pwd`;
		chomp $return;
		chdir($pwd);
	}elsif($type eq 'file'){
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
sub SHOW_TIME {
	#显示当时时间函数，参数内容是时间前得提示信息，为字符串
	my ($str)=@_;
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	my $temp=sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
	print "$str:\t[".$temp."]\n";
}

sub read_bam_window{
	my($infile)=@_;
	open(I,"samtools view $infile|") or die $!;
	while(<I>){
		chomp; my$lines = $_;
		my ($id,$flag,$chr,$pos,$mapQ,$matchInfo,$li7,$li8,$li9,$seq,@line) = split(/\t/,$lines);
		my ($rnum, $is_reverse ,$is_unmap)=&explain_bam_flag($flag);

		if ($is_unmap == 1 and $print_type == 2 ){
			print "$id,$flag,$chr,$pos\t This id is_unmap!\n";
		}elsif($matchInfo eq "*"){
		}else{
			my ($DS,$I) = (0,0);
			if( $matchInfo =~ /I/ ){ $I = 1; }
			my($leftM,$rightM) = &bianli_match_n($matchInfo,$chr,$pos,$seq,"border"); # 得到左右M位点
			#my $cexusequence = &bianli_match_n($matchInfo,$chr,$pos,$seq,"seq",$leftM,$rightM); # 得到左右M位点对应序列
			my $cexusequence = $seq;
			my($bef,$MD,$aft,$refsequence);
			if ( $lines =~ m/^(?<bef>.+MD:Z:)(?<MD>.+?)\t(?<aft>.+?)$/){
				($bef,$MD,$aft) = ($+{bef},$+{MD},$+{aft});
				$MD = &changed_to_MD($chr,$pos,$leftM,$rightM,$matchInfo,"exist",$MD,$cexusequence,$id);
			}else{
				my $refsequence = &get_samtools_faidx($chr,$leftM,$rightM); #print"$lines\n";
				$MD = &changed_to_MD($chr,$pos,$leftM,$rightM,$matchInfo,"notex",$refsequence,$cexusequence,$id);
			}
			my $cigar = &bianli_match_n($matchInfo,$chr,$pos,$seq,"cigar",$leftM,$rightM);
			if( $MD =~ /[ATGC]/ ){	$DS = 1; }
			#if( defined $refsequence and $DS+$I > 0 ){	print "$refsequence\trefgeted!\n";		}
			my $pos_end = $pos + &len_leave($cigar,"MD") - 1 ;
			#if( $DS+$I > 0 ){	print "$cexusequence\t$MD\t$cigar\t$pos\t$pos_end\t$matchInfo\n\n";			}
		}

	}
	close I;
}
### 计数各个类型的长度
sub len_leave{
	my($cigar,$typ)=@_;
	my ($match_n_,$match_str_) = &sep_match_info($cigar);
	my @match_n = @$match_n_;
	my @match_str = @$match_str_;
	my ($re,$re1) = (0,0);
	foreach my$index(0..$#match_n){
		if( $match_str[$index] =~ /[MSI]/ ){
			$re += $match_n[$index];
		}
		if( $match_str[$index] =~ /[MD]/ ){
			$re1 += $match_n[$index];
		}
	}
	if( $typ eq "MSI" ){
		return($re);
	}elsif( $typ eq "MD" ){
		return($re1);
	}
}
### 指定位置，截取基因组序列
sub get_samtools_faidx{
	my($chr,$sta,$end)=@_;
	my $genome_ref = `samtools faidx $RefGenome $chr:$sta-$end`;
	$genome_ref =~ tr/ATGCatgc/ATGCATGC/;
	my ($id,@seq_ref) = split( /\n/,$genome_ref );
	if( scalar(@seq_ref) == 0 ){ print "what:$genome_ref"; }
	my $ref_seq12 = join "",@seq_ref;
	return($ref_seq12);
}
sub sep_match_info{		#分割cigar
	my($match_info)=@_;
	my @ucigar = split //, $match_info;
	my (@match_n,@match_str);
	my $I_before = 0;
	my $cigar="";
	foreach my $i(0..$#ucigar){
		if($ucigar[$i] eq "M" || $ucigar[$i] eq "I"|| $ucigar[$i] eq "D" || $ucigar[$i] eq "S"){
			push @match_str, $ucigar[$i];
			push @match_n, $cigar+$I_before;
			$cigar = "";
		}else{
			$cigar .= $ucigar[$i];
		}
	}
	return(\@match_n,\@match_str)
}
sub explain_bam_flag{	#分割flag
	my ($flag)=@_;
	my $flag_bin=sprintf("%b", $flag);
	my @flag_bin = split //, $flag_bin;
	my $is_read1 = $flag_bin[-7];
	#my $is_read2 = @flag_bin>=8? $flag_bin[-8]: 0;
	#my $is_supplementary = @flag_bin>=12? $flag_bin[-12]: 0;
	#my $is_proper_pair = $flag_bin[-2];
	my $is_reverse = $flag_bin[-5];
	my $is_unmap = $flag_bin[-3];
	my $is_munmap = $flag_bin[-4];
	#my $dup = @flag_bin>=11? $flag_bin[-11]: 0;
	my $rnum = $is_read1==1? 1: 2;
	#return($rnum, $is_proper_pair, $is_reverse, $is_unmap, $is_munmap, $is_supplementary);
	return($rnum,$is_reverse,$is_unmap);
}

sub bianli_match_n{		#遍历cigar
	my($matchInfo,$chr,$pos,$seq,$typ,$start,$end)=@_;
	my($match_n_,$match_str_) = &sep_match_info($matchInfo);
	my @match_n = @$match_n_;
	my @match_str = @$match_str_;
	my ($seq_l,$seq_r,$seq_D,$seq_I,$seq_S)=(0,$pos,0,0,0);
	my ($start_l,$end_l)=(0,0);
	my ($cigar_re)=("");

	foreach my $index(0..$#match_n){
		if( $match_str[$index] eq "D" ){
			if( defined $typ and $typ eq "cigar" and $start <= $seq_r and $end >= $seq_r + $match_n[$index] ){
				$cigar_re .= $match_n[$index].$match_str[$index];
			}elsif( defined $typ and $typ eq "cigar" and $start <= $seq_r and $end < $seq_r + $match_n[$index] ){
				$cigar_re .= "0".$match_str[$index];		last;
			}elsif( defined $typ and $typ eq "cigar" and $start > $seq_r and $end >= $seq_r + $match_n[$index]
					and $start < $seq_r + $match_n[$index] ){
				$cigar_re .= "0".$match_str[$index];
			}
			if( defined $typ and $typ eq "seq" ){
				if( $start >= $seq_r and $start < $seq_r+$match_n[$index] ){
					$start_l = $seq_l ;
				}
				if( $end >= $seq_r and $end < $seq_r+$match_n[$index] ){
					$end_l = $seq_l -1;
				}
			}
			$seq_r += $match_n[$index];
			$seq_D += $match_n[$index];
			next;
		}
		if( $match_str[$index] eq "M" ){
			if( defined $typ and $typ eq "seq" ){
				if( $start >= $seq_r and $start < $seq_r+$match_n[$index] ){
					$start_l = $seq_l + ($start-$seq_r);
				}
				if( $end >= $seq_r and $end < $seq_r+$match_n[$index] ){
					$end_l = $seq_l + ($end-$seq_r);
				}
			}elsif( defined $typ and $typ eq "cigar" ){
				if( $start <= $seq_r and $end >= $seq_r + $match_n[$index] ){
					$cigar_re .= $match_n[$index].$match_str[$index];
				}elsif( $start <= $seq_r and $end >= $seq_r and $end < $seq_r + $match_n[$index] ){
					$cigar_re .= ($end-$seq_r+1).$match_str[$index];						last;
				}elsif( $start >= $seq_r and $start < $seq_r + $match_n[$index] and $end >= $seq_r + $match_n[$index] ){
					$cigar_re .= ($match_n[$index]-($start-$seq_r)).$match_str[$index];	
				}elsif( $start >= $seq_r and $end < $seq_r + $match_n[$index] ){
					$cigar_re .= ($end-$start+1).$match_str[$index];					last;
				}
			}
			$seq_r += $match_n[$index]; 
			$seq_l += $match_n[$index];
		}elsif( $match_str[$index] eq "I" ){
			if( defined $typ and $typ eq "cigar"	and $start <= $seq_r-1 and $end >= $seq_r ){
				$cigar_re .= $match_n[$index].$match_str[$index];
			}
			$seq_l += $match_n[$index];
			$seq_I += $match_n[$index];
		}elsif( $match_str[$index] eq "S" ){
			$seq_l += $match_n[$index];
			$seq_S += $match_n[$index];
		}
	}
	if( defined $typ and $typ eq "seq" ){
		my $seq_re = substr($seq, $start_l, $end_l-$start_l+1);
#		print "seq:\t###$seq_re\t$start,$end\t$seq, $start_l, $end_l-$start_l+1\n";
		return($seq_re);
	}elsif( defined $typ and $typ eq "cigar" ){
#		print "cigar:\t###$cigar_re\t$start,$end\t$matchInfo\n";
		return($cigar_re);
	}elsif( defined $typ and $typ eq "border" ){
#		print "pos:\t###$pos\n";
		return($pos,$seq_r-1);
	}
}


sub changed_to_MD{
	my($chr,$pos,$leftM,$rightM,$matchInfo,$tpy,$refsequence,$cexusequence,$id) = @_;
	my($match_n_,$match_str_) = &sep_match_info($matchInfo);
	my @match_n = @$match_n_;
	my @match_str = @$match_str_;
	my ($seq_l,$seq_r,$seq_D,$seq_I,$seq_S)=(0,0,0,0,0);
	my ($MD,$MD_exists) = ("","");
	if( $tpy eq "exist" ){	$MD_exists = $refsequence;	}

	foreach my $index(0..$#match_n){
		my ($MD_each,$del) = ("","");
		if( $match_str[$index] eq "D" ){
			if( $tpy eq "notex" ){	
				$del = substr($refsequence,$seq_r,$match_n[$index]);	
				$MD_each = "^".$del;
			}else{	
				$del = &cut_MD($id,$MD_exists,$chr,$pos,$seq_r,$match_n[$index]);	
			}
			$seq_r += $match_n[$index];
			$seq_D += $match_n[$index];
		}elsif( $match_str[$index] eq "M" ){
			if( $tpy eq "notex" ){
				my $refseq = substr($refsequence,$seq_r,$match_n[$index]);
				my $altseq = substr($cexusequence,$seq_l,$match_n[$index]);
				$MD_each = &changed_onlyM_to_MD($refseq,$altseq);
			}else{
				my $altseq = substr($cexusequence,$seq_l,$match_n[$index]);
				$del = &cut_MD($id,$MD_exists,$chr,$pos,$seq_r,$match_n[$index],$altseq);
			}
			$seq_r += $match_n[$index];
			$seq_l += $match_n[$index];
		}elsif( $match_str[$index] eq "I" and $index ne 0 and $index ne $#match_n ){  # 边界的 I ！
			my $altseq = substr($cexusequence,$seq_l,$match_n[$index]);
			$alt_all{$chr}{$pos+$seq_r-1}{"ins"}{$altseq}++;  # 记前1位置
			push@{$each_pos_ids{$chr}{$pos+$seq_r-1}{"I"}},$id;
			@{$each_pos_IDM{$chr}{$pos+$seq_r-1}{"I"}{$id}} = ("I",$altseq,"");
			#print "\t$chr\t$pos+$seq_r-1\tins\t$altseq\n";
			$seq_l += $match_n[$index];
			$seq_I += $match_n[$index];
		}elsif( $match_str[$index] eq "S" ){
			$seq_l += $match_n[$index];
		}
		$MD .= $MD_each;
	}

	if( $tpy eq "exist" ){  $MD = $refsequence;  }
	return($MD);
}
sub changed_onlyM_to_MD{
	my ($refsequence,$cexusequence) = @_;
	my $re="";
	if( $refsequence eq $cexusequence ){
		return(length($refsequence));
	}else{
		my@refseq = split//,$refsequence;
		my@altseq = split//,$cexusequence;
		my($match)=(0);
		foreach my$i(0..$#refseq){
			if( not defined $refseq[$i] or not defined $altseq[$i]){ print "what:$refsequence,$cexusequence\n";}
			if( $refseq[$i] eq $altseq[$i] ){
				$match++;
			}elsif( $refseq[$i] ne $altseq[$i] ){
				if( $i == 0 ){	$re = "0".$refseq[$i]; 
				}else{	$re = $re.$match.$refseq[$i];	$match=0;}
			}
		}
		$re = $re.$match;
	}
	return($re);
}

sub cut_MD{
	my($id,$MD_exists,$chr,$pos,$seq_r,$match_n,$cexusequence)=@_;
	my @MD_array = split//,$MD_exists;
	my ($count,$match,$D_in,$D_seq)=(0,0,0,"");
	foreach my$i(0..$#MD_array){
		if( $count >= $seq_r+$match_n ){last;}
		if( $MD_array[$i] =~ /\d/){
			if( $D_in ){	
				if( $count >= $seq_r and $count < $seq_r+$match_n ){
					$alt_all{$chr}{$pos+$seq_r}{"del"}{$D_seq}++;	# 记 D 的第一碱基位置
					push@{$each_pos_ids{$chr}{$pos+$seq_r}{"D"}},$id;
					@{$each_pos_IDM{$chr}{$pos+$seq_r}{"D"}{$id}} = ("D",$D_seq,"");
					#print "\t$chr\t$pos+$seq_r\tdel\t$D_seq\n";
				}
				$count += length($D_seq); $D_in=0;
			}
			$match .= $MD_array[$i]; $D_in=0;
		}elsif( $MD_array[$i] =~ /([ATGCN])/){
			if( not $D_in ){	
				$count += $match;	
				$match=0;
				if( $count >= $seq_r and $count < $seq_r+$match_n ){
					if( defined $cexusequence ){
						my$alt_snp = substr($cexusequence,$count-$seq_r,1);
						#if( $alt_snp ne "N" ){	
							$alt_all{$chr}{$pos+$count}{"snp"}{$alt_snp} = $MD_array[$i];
							push@{$each_pos_ids{$chr}{$pos+$count}{"M"}},$id;
							@{$each_pos_IDM{$chr}{$pos+$count}{"M"}{$id}} = ("M",$MD_array[$i],$alt_snp);
							#print "snp:$id\t$chr\t",$pos+$count,"\tsnp\t$alt_snp\t$MD_array[$i]\t$MD_exists\n";
						#}
					}
				}
				$count += 1; $D_in=0;
			}else{	$D_seq .= $MD_array[$i];	}
		}elsif( $i  =~ /\^/){
			$D_in = 1;
		}
	}
	return($D_seq);
}
sub check_and_print{
	foreach my$chr(sort keys %each_pos_ids){
		my$each_chr = $each_pos_ids{$chr};
		my @pos = sort{$a<=>$b} keys %$each_chr;
		foreach my$p1( 0..$#pos ){
			my $each_pos1 = $each_pos_ids{$chr}{$pos[$p1]};
			my @IDM1 = sort keys %$each_pos1;
			foreach my$idm1(@IDM1){
				my @each_chr_pos1 = @{$each_pos_ids{$chr}{$pos[$p1]}{$idm1}};
				foreach my$p2( $p1..$#pos ){
					if( $pos[$p2] - $pos[$p1] > $illumina_len ){        last;   }
					my $each_pos2 = $each_pos_ids{$chr}{$pos[$p2]};
					my @IDM2 = sort keys %$each_pos2;
					foreach my$idm2(@IDM2){
						if( $pos[$p2] == $pos[$p1] and $idm2 eq $idm1 ){	next;	}
						my @each_chr_pos2 = @{$each_pos_ids{$chr}{$pos[$p2]}{$idm2}};
						&check_ids(\@each_chr_pos1,\@each_chr_pos2,$chr,$pos[$p1],$idm1,$pos[$p2],$idm2);
						#print "$chr\t$pos[$p1]\t$pos[$p2]\t$idm1\t$idm2##################\n";
					}
				}
			}
		}
	}
	&check_and_print_count();
}
sub check_ids{
	my($id1,$id2,$chr,$pos1,$idm1,$pos2,$idm2)=@_;
	my%id_hash;
	foreach my$id(@$id1){
		$id_hash{$id} = 1;
	}
	foreach my$id(@$id2){
		if(exists $id_hash{$id}){	$id_hash{$id} = 2;	}
	}

	foreach my$id(sort{$id_hash{$b}<=>$id_hash{$a}} keys %id_hash){
		if( $id_hash{$id} == 2 ){
			my ($IDM1, $ref1, $alt1, $IDM2, $ref2, $alt2) = ("","","no","","","no");
			($IDM1, $ref1, $alt1) = @{$each_pos_IDM{$chr}{$pos1}{$idm1}{$id}};
			($IDM2, $ref2, $alt2) = @{$each_pos_IDM{$chr}{$pos2}{$idm2}{$id}};
			$count_company{$chr}{$pos1}{"$IDM1\_$ref1\_$alt1:$pos2:$IDM2\_$ref2\_$alt2"} ++;
		}
	}
}
sub check_and_print_count{
	foreach my$chr(sort keys %count_company){
		my $count_chr = $count_company{$chr};
		my @pos = sort{$a<=>$b} keys %$count_chr;
		foreach my$p( @pos ){
			my $count_pos = $count_company{$chr}{$p};
			foreach my$company(sort keys %$count_pos){
				my $count_c = $count_company{$chr}{$p}{$company};			
				if( $count_c > $min_count ){
					if( $print_N == 0 ){ 
						if( $company =~ /N/ ){ next; } 
					}
					my ($IDM1, $P, $IDM2) = split/:/,$company;
					print OUT "$chr\t$p\t$company\t$count_c\n";
				}
			}
		}
	}
}

