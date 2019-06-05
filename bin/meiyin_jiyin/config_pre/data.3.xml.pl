#!/usr/bin/perl
# perl data.3.xml.pl -sex F -file /data/bioit/biodata/chenx/biodata/chip_pipeline/v2/Data/04.genotypesDir/202466020115_R05C02_MM0500183.txt  -conf config_20190522/config.cancers -xlsx /data/bioit/biodata/wugz/meiyin/dataIn1/final.cancers.xlsx -label cancers  -out config_20190522/test.cancers.out
# perl data.3.xml.pl -sex F -file /data/bioit/biodata/chenx/biodata/chip_pipeline/v2/Data/04.genotypesDir/202466020115_R05C02_MM0500183.txt  -conf config_20190522/config.acmg -xlsx /data/bioit/biodata/wugz/meiyin/dataIn1/final.acmg.xlsx -label acmg  -out config_20190522/test.acmg.out

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(cwd);
use FindBin qw($Bin);
use File::Basename qw(basename dirname);
use POSIX;
use Math::Round;
use Template;
use Data::Dumper;
use File::Slurp;
use Scalar::Util 'refaddr';
use XML::Simple qw(XMLin XMLout);
use Data::Printer colored => 1;
use Storable qw(dclone);
use Spreadsheet::XLSX;
use utf8;
use Encode;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my ($out, $sex, $label, $xlsx, $file, $config, $printType);
GetOptions (
	"sex=s"		=> \$sex,
	"label=s"	=> \$label,
	"out=s"		=> \$out,
	"xlsx=s"	=> \$xlsx,
	"file=s"	=> \$file,
	"print=s"	=> \$printType,
	"conf=s"	=> \$config,
)or &USAGE;
&USAGE unless ($out and $xlsx and $file and $config and $sex);

$printType ||= 0;

########## AbsolutePath and default ##############
##################################################
my(%diseaseGene, %geneFunc, %diseaseDes);
my $excel = Spreadsheet::XLSX -> new ("$xlsx") or die "Can't read $xlsx: $!\n";
for my $sheet (@{$excel->{Worksheet}}){ 
#	$sheet->{MaxRow} ||= $sheet->{MinRow};
	foreach my $row (1 .. $sheet->{MaxRow}) {
		if( $sheet->{Name} eq "Sheet1" ){
			my $cell_disease = $sheet->{Cells}[$row][0]->{Val};
			my $cell_sex = $sheet->{Cells}[$row][1]->{Val};
			my $cell_gene = $sheet->{Cells}[$row][2]->{Val};
			my $cell_genefunc = decode('UTF-8',$sheet->{Cells}[$row][3]->{Val});
			if( not defined $cell_genefunc ){	$cell_genefunc="";	}
			$geneFunc{$cell_gene}{$cell_sex} = $cell_genefunc;#################基因功能
#			$diseaseGene{$cell_disease}{$cell_gene} = $cell_sex;
		}elsif( $sheet->{Name} eq "Sheet2" ){
			my $cell_dis = decode('UTF-8',$sheet->{Cells}[$row][0]->{Val});
			my $cell_disdes = decode('UTF-8',$sheet->{Cells}[$row][1]->{Val});
			my $cell_disref = decode('UTF-8',$sheet->{Cells}[$row][2]->{Val});
		#	my $cell_disref = $sheet->{Cells}[$row][2]->{Val};
			if( not defined $cell_disdes ){   $cell_disdes="";  }
			if( not defined $cell_disref ){   $cell_disref="";  }
			$diseaseDes{$cell_dis}{'des'} = $cell_disdes;#################描述
			$diseaseDes{$cell_dis}{'ref'} = $cell_disref;#################参考文献
			#if( $cell_disref =~ /9004/ ){print Dumper $cell_disref; }
		}
	}	
}

my(%mutation_info, %mutation_print, %en_ch_mutationNature, %en_ch_mutationType, %en_order, %yichuanfangshi);
my(%mutation_info_Di, %mutation_info_Ge, %mutation_info_Rs);
load_en_order();
load_en_ch();
load_yichuanfangshi();
open(CIN,"$config") or die "no file $config!\n";
while(<CIN>){
	chomp; my$line=$_;
	if( $line =~ /^#/ ) {	next;	}
	my($ref,$alt,$disCh,$rsid,$gene,$mutationNature,$splicing,$mutationType,$trans,$exonN,$cPos,$pPos,$all_1000g2014oct,$eas_1000g2014oct,$AD,$exac,$tgp) = (split/\t/,$line)[3,4,5,8,9,10,13,14,16,17,18,19,20,21,22,23,24];
#		(split/\t/,$line)[3,4,5,8,9,10,12,14,16,17,18,20,21,22];
	my $insN = length($alt) - length($ref);
	if( $insN <= 0 ){
		$insN = "-";
	}

	if( $exonN =~ /^c\./ ){
		$cPos = $exonN;
	}	
	my@cPos_up=split/,/,$cPos;
	if( scalar(@cPos_up) > 1 ){
		$cPos = $cPos_up[0];
		$pPos = ".";
	}

	my ($stopgain_01, $num, $stopg, $exon_pos, $add_plus, $intron_pos) = ("-", "-", "-", "-", "-", "-");
	if( $cPos =~ /([0-9_*+-]+)(.+)$/ ){
		$num = $1;
		$num =~ tr/_/~/;
		$stopg = $2;
		if( $stopg =~ /del/ ){
			$stopgain_01 = 'del';
		}elsif($stopg =~ /ins/ or $stopg =~ /dup/ ){
			$stopgain_01 = 'ins';
		}elsif($splicing eq "splicing"){
			$stopgain_01 = 'splicing';
		}else{
			$stopgain_01 = 'snp';
		}
		if( $num =~ /([0-9]*)([+-])([0-9]*)/ ){
			$exon_pos = $exonN;
			$add_plus = $2;
			$intron_pos = $3;
		}
		if( $printType == 1 ){
			print "$cPos\t$num\t$rsid\t$exon_pos,$add_plus,$intron_pos\t$mutationNature\t\t$mutationType\n";
		}
	}else{
		$stopgain_01 = '-';
		if( $printType == 1 ){	print "###$cPos\n";	}
	}
	if( $mutationType eq 'stopgain' ){
		$stopgain_01 = 'stopgain';
	}

	$mutation_info_Di{$disCh} = 1;
	$mutation_info_Ge{$gene} = 1;
	$mutation_info_Rs{$rsid} = 1;
	$AD = decode('utf8', $AD);
	$AD = $yichuanfangshi{$AD};
	$disCh = decode('utf8', $disCh);
#	if( $disCh eq "非霍奇金氏淋巴瘤" or $disCh eq "膀胱癌"  or $disCh eq "脑胶质瘤" or $disCh eq "宫颈癌" ){	next; 	}

	$rsid = ucfirst($rsid);
	$mutationNature = delete_and_uniq($mutationNature);

	$mutationType = guiyi_not_defined($mutationType);
	$trans = guiyi_not_defined($trans);
	$cPos = guiyi_not_defined($cPos);
	$pPos = guiyi_not_defined($pPos);
	$exac = guiyi_not_defined($exac);
	$tgp = guiyi_not_defined($tgp);
	$num = guiyi_not_defined($num);
	$AD = guiyi_not_defined($AD);
	$all_1000g2014oct = guiyi_not_defined($all_1000g2014oct);
	$eas_1000g2014oct = guiyi_not_defined($eas_1000g2014oct);

	$mutation_info{$rsid}{$en_order{$mutationNature}}{"$ref:$alt:$disCh"} = {
		'rsid' => $rsid,
		'gene' => $gene,
		'trans' => $trans,
		'cPos' => $cPos,
		'cpos' => $num,
		'exonN'=> $exon_pos, 
		'updown' =>$add_plus, 
		'intron_pos' =>$intron_pos,
		'pPos' => $pPos,
		'exac' => $exac,
		'all_1000g2014oct' => $all_1000g2014oct,
		'eas_1000g2014oct' => $eas_1000g2014oct,
		'type' => "-",
		'insN' => $insN,
		'mutationNature' => $mutationNature,
		'mutationNatureCh' => $en_ch_mutationNature{$mutationNature},
		'mutationType' => $mutationType,
		'stopgainornot' => $stopgain_01,
		'mutationTypeCh' => $en_ch_mutationType{$mutationType},
		'mode' => $AD,
	};
	$mutation_info{$rsid}{$en_order{$mutationNature}}{"$ref:$alt"}{'assodis'}{$disCh}=1;
	$mutation_print{'store'}{$disCh}{'totalNrs'}{$rsid} = 1;
	$mutation_print{'store'}{$disCh}{'totalNgene'}{$gene}{$rsid} = 1;
}
close CIN;

$mutation_print{'label'} = $label;
$mutation_print{'sex'} = $sex;
$mutation_print{'totalDisN'} = scalar(keys %mutation_info_Di);
$mutation_print{'totalGeneNum'} = scalar(keys %mutation_info_Ge);
$mutation_print{'totalSNPNum'} = scalar(keys %mutation_info_Rs);
$mutation_print{'summary'}{'MutationN'} = 0;
$mutation_print{'summary'}{"positiveMutN"} = 0;
$mutation_print{'summary'}{'positiveGeneN'} = 0;
my (%hash_uniq, %dis_gene);
open(IN,"$file") or die "no file $file!\n";
while(<IN>){
	chomp;
	my($rsid,$genotype) = split/\t/,$_;
	if( exists $hash_uniq{$rsid} ){	
#		print $rsid,"\trsid exists!\n";
		next;	
#	}else{		print $rsid,"\trsid not exists!\n";	
	}
	$hash_uniq{$rsid} = 1;
	if( exists $mutation_info{$rsid} ){
		my$mutation_info_ = $mutation_info{$rsid};
		foreach my$order(sort {$a<=>$b} keys %$mutation_info_){
			my$mutation_info_rs = $mutation_info{$rsid}{$order};
			foreach my$each(keys %$mutation_info_rs){
				my($ref,$alt,$disCh) = split/:/,$each;
				if( not defined $disCh ){	next;	}
				my($type, $type_) = check_type($genotype,$ref,$alt);
				if( $type eq "-" ){
#					print "##$rsid\t$genotype,$ref,$alt\ttype==0, no mutation!\n";	
				}else{	
#					print "$rsid\t$genotype,$ref,$alt\t$mutationNature\tcounting!\n";
					my$gene = $mutation_info{$rsid}{$order}{$each}{'gene'};
					my$mutationNature = $mutation_info{$rsid}{$order}{$each}{'mutationNature'};
					$mutation_info{$rsid}{$order}{$each}{'type'} = $type;
					$mutation_info{$rsid}{$order}{$each}{'typekey'} = $type_;

					my %hash_eachrs = %{$mutation_info{$rsid}{$order}{$each}};
					my $eachalt_assodis = $mutation_info{$rsid}{$order}{"$ref:$alt"}{'assodis'};
					my @mut_assodis = sort keys %$eachalt_assodis;
					@{$hash_eachrs{'assodis'}} = @mut_assodis;  #####
					$hash_eachrs{'geneassodis'} = combine_with(\@mut_assodis);

					if( $mutationNature eq "Pathogenic" or $mutationNature eq "Pathogenic/Likely_pathogenic" or $mutationNature eq "Likely_pathogenic"){
						$hash_eachrs{'display'} = "Y"; #####
						$mutation_print{'store'}{$disCh}{'positiveMutN'}{$rsid} = 1;
						$mutation_print{'store'}{$disCh}{'positiveGeneN'}{$gene}{$rsid} = 1;
						$mutation_print{'store_sum_gene'}{$hash_eachrs{'gene'}}{$disCh} = 1;
						$mutation_print{'store_sum_rs'}{$rsid} = 1;
						print "$disCh\t$rsid\t$gene\t$mutationNature\n";
					}else{
						$hash_eachrs{'display'} = "N";
					}
					$dis_gene{$gene}{$hash_eachrs{'mode'}} = 1;
					$mutation_print{'store_uniqrs'}{$rsid}{'geneName'} = $hash_eachrs{'gene'};
					$mutation_print{'store_uniqrs'}{$rsid}{'value'} = \%hash_eachrs;
					$mutation_print{'summary'}{'MutationN'}++;
					$mutation_print{'store'}{$disCh}{'MutationNgene'}{$gene}{$rsid} = 1;
					my %hash_eachrs_new = %hash_eachrs;
					$mutation_print{'store'}{$disCh}{'MutationN'}{$rsid} = \%hash_eachrs_new;
				 }
			}
		}
	}
}
close IN;
my$mutation_print_sum_rs = $mutation_print{'store_sum_rs'};
$mutation_print{'summary'}{"positiveMutN"} =scalar(keys %$mutation_print_sum_rs);
delete $mutation_print{'store_sum_rs'};

my$mutation_print_sum_gene = $mutation_print{'store_sum_gene'};
foreach my$gene(sort{$a cmp $b}keys %$mutation_print_sum_gene){
	my $mutation_positive_gene = $mutation_print{'store_sum_gene'}{$gene};
	my %hash_eachgene;	#print Dumper $gene, $mutation_positive_gene;
	$hash_eachgene{'gene'} = $gene;
	if( not exists $geneFunc{$gene}{$sex} ){
		if( exists $geneFunc{$gene}{"A"}){	
			$geneFunc{$gene}{$sex} = $geneFunc{$gene}{"A"};
		}else{
			print "Error:($gene $sex) has no geneFunction!\n";	
			#die;
		}
	}
	$hash_eachgene{'geneFunction'} = (exists $geneFunc{$gene}{$sex})?($geneFunc{$gene}{$sex}):("");

	my @dis_all	= sort keys %$mutation_positive_gene;
	my $dis_n = scalar(@dis_all);
	my $dis_count=0;
	my %hash_ref;
	my $geneassodis	= combine_with(\@dis_all);
	foreach my$dis(@dis_all){
		$dis_count++;
		my%hash_eachdis=(
			'distitle' => $dis,
			'summary' => $diseaseDes{$dis}{'des'},
			'refs' => $diseaseDes{$dis}{'ref'},
		);
		push @{$hash_eachgene{"assodis"}}, \%hash_eachdis;
		my $hash_ref_ = uniq_refall(\%hash_ref, $diseaseDes{$dis}{'ref'});
		%hash_ref = %$hash_ref_;
	}
	$hash_eachgene{'geneassodis'} = $geneassodis;
	push @{$mutation_print{'summary'}{'disinfo'}},\%hash_eachgene;
	$mutation_print{'summary'}{'allref'} = join "\n", (sort keys%hash_ref);
	$mutation_print{'summary'}{'positiveGeneN'}++;
}
delete $mutation_print{'store_sum_gene'};

my$mutation_print_uniqrs = $mutation_print{'store_uniqrs'};
my@sortRs=sort{$mutation_print{'store_uniqrs'}{$a}{'geneName'} cmp $mutation_print{'store_uniqrs'}{$b}{'geneName'}} keys %$mutation_print_uniqrs;
foreach my$rsid(@sortRs){
	my $gene = $mutation_print{'store_uniqrs'}{$rsid}{'value'}->{'gene'};
	my $AD_keys = $dis_gene{$gene};
	my @AD_keys_all = sort keys %$AD_keys;
	my $mode_new = combine_with(\@AD_keys_all);
	$mutation_print{'store_uniqrs'}{$rsid}{'value'}->{'mode'} = $mode_new;
	push @{$mutation_print{'summary'}{'mutation'}}, $mutation_print{'store_uniqrs'}{$rsid}{'value'};
}
delete $mutation_print{'store_uniqrs'};

my$mutation_print_store = $mutation_print{'store'};
foreach my$disCh(sort keys %$mutation_print_store){
#	if( not exists $mutation_print{'store'}{$disCh}{'MutationN'} ){	 next;	}
	my$total_rs = $mutation_print{'store'}{$disCh}{'totalNrs'};
	my$mutation_disCh = $mutation_print{'store'}{$disCh}{'MutationN'};
	my$mutationP_disCh = $mutation_print{'store'}{$disCh}{'positiveMutN'};
	my$geneP_disCh = $mutation_print{'store'}{$disCh}{'positiveGeneN'};
	my$gene_disCh = $mutation_print{'store'}{$disCh}{'MutationNgene'};
#	print Dumper $mutation_print{'store'}{$disCh}{'totalNrs'};
	my%hash_disCh = (
		'title'		=> $disCh,
		'totalN'	=> scalar( keys %$total_rs ),
		'mutaionN'	=>	scalar(keys %$mutation_disCh),
		'positiveMutN'	=> scalar(keys %$mutationP_disCh),
		'positiveGeneN'	=> scalar(keys %$geneP_disCh),
	);
#	print Dumper $mutation_print{'store'}{$disCh}{'MutationN'};
	foreach my$rsid(sort keys %$mutation_disCh){
		$mutation_print{'store'}{$disCh}{'MutationN'}{$rsid}{'geneassodis'} = $disCh;
		push @{$hash_disCh{'mutation'}}, $mutation_print{'store'}{$disCh}{'MutationN'}{$rsid};
	}

	my %hash_ref;
	foreach my$gene(sort keys %$geneP_disCh){
		my%disinfo;
		$disinfo{'gene'} = $gene;
		$disinfo{'geneFunction'} = (exists $geneFunc{$gene}{$sex})?($geneFunc{$gene}{$sex}):("");
		$disinfo{'geneassodis'} = $disCh;
		
		my%assodis = (
			'distitle' => $disCh,
			'summary' => $diseaseDes{$disCh}{'des'},
			'refs' => $diseaseDes{$disCh}{'ref'},
		);
		push @{$disinfo{'assodis'}}, \%assodis;
		push @{$hash_disCh{'disinfo'}}, \%disinfo;	
		my $hash_ref_ = uniq_refall(\%hash_ref, $diseaseDes{$disCh}{'ref'});
		%hash_ref = %$hash_ref_;
	}
	$hash_disCh{'allref'} = join "\n", (sort keys%hash_ref);

	my$gene_disCh_all = $mutation_print{'store'}{$disCh}{'totalNgene'};
	foreach my$gene(sort keys %$gene_disCh_all){
		my$total_gene = $mutation_print{'store'}{$disCh}{'totalNgene'}{$gene};
		my$mutrs_gene = $mutation_print{'store'}{$disCh}{'MutationNgene'}{$gene};
		my$mutPrs_gene = $mutation_print{'store'}{$disCh}{'positiveGeneN'}{$gene};
		my%gene = (
			'geneName'  =>	$gene,
			'totalN'	=>	scalar( keys %$total_gene),
			'mutaionN'  =>	scalar( keys %$mutrs_gene),
			'positiveMutN'  =>	scalar( keys %$mutPrs_gene),
		);
		push @{$hash_disCh{'geneA'}}, \%gene;
	}
#	print Dumper %hash_disCh;
	push@{$mutation_print{'information'}{'disease'}}, \%hash_disCh;
}
delete $mutation_print{'store'};

print "$mutation_print{'summary'}{'MutationN'}\t$mutation_print{'summary'}{'positiveMutN'}\t$mutation_print{'summary'}{'positiveGeneN'}\t$out\n";

output_xml(\%mutation_print,"$out.original");
replace_array_all();
output_xml(\%mutation_print,$out);
##################################################################################################################
##################################################################################################################
##################################################################################################################
sub combine_with{
	my ($arr)=@_;
	my @array = @$arr;
	my $re;
	my $scalar = scalar(@array);
	if( $scalar == 1 ){
		$re = $array[0]; #####
	}else{
		$re = join"、",@array[0..($scalar-2)];
		$re .= "和".$array[$#array];
	}
	return($re);
}

sub replace_array_all{
#=pob	
	foreach my $eachM( @{$mutation_print{'summary'}{'mutation'}} ){
		$eachM = foreach_replace($eachM);
	}
#=cut
	$mutation_print{'summary'}{'allref'} = replace($mutation_print{'summary'}{'allref'});
	foreach my $eachI( @{$mutation_print{'summary'}{'disinfo'}} ){
		$eachI->{'gene'} = replace($eachI->{'gene'});
		$eachI->{'geneassodis'} = replace($eachI->{'geneassodis'});
		$eachI->{'geneFunction'} = replace($eachI->{'geneFunction'});
		foreach my $eachA( @{$eachI->{'assodis'}} ){
			$eachA = foreach_replace($eachA);
		}
	}

	foreach my $eachD( @{$mutation_print{'information'}{'disease'}} ){
		$eachD->{'allref'} = replace($eachD->{'allref'});
		$eachD->{'title'} = replace($eachD->{'title'});
		foreach my $eachM( @{$eachD->{'mutation'}} ){
			$eachM = foreach_replace($eachM);
		}
		foreach my $eachM( @{$eachD->{'geneA'}} ){
			$eachM = foreach_replace($eachM);
		}
		foreach my $eachI( @{$eachD->{'disinfo'}} ){
			$eachI->{'gene'} = replace($eachI->{'gene'});
			$eachI->{'geneassodis'} = replace($eachI->{'geneassodis'});
			$eachI->{'geneFunction'} = replace($eachI->{'geneFunction'});
			foreach my $eachA( @{$eachI->{'assodis'}} ){
				$eachA = foreach_replace($eachA);
			}
		}
	}

}
sub uniq_refall{
	my($hashRef, $string)=@_;
	$string = $string;
	if( not defined  $string ){	
		return $hashRef;
	}
	my@refs=split("\n", $string);
	foreach my$each(@refs){
		(exists $hashRef->{$each})?($hashRef->{$each}++):($hashRef->{$each}=1);
	}
	return $hashRef;
}

sub load_en_order{
	%en_order = (
		'Pathogenic'									=>1,
		'Pathogenic/Likely_pathogenic'					=>2,
		'Likely_pathogenic'								=>3,
		'Benign'										=>4,
		'Benign/Likely_benign'							=>5,
		'Likely_benign'									=>6,
		'Conflicting_interpretations_of_pathogenicity'	=>7,
		'Uncertain_significance'						=>8,
		'not_provided'									=>10,
		'-'												=>11,
	);
}
sub load_en_ch{
	%en_ch_mutationNature = (
		'Pathogenic'									=> '致病突变',
		'Likely_pathogenic'								=> '可能致病突变',
		'Pathogenic/Likely_pathogenic'					=> '可能致病突变',
		'Benign'										=> '良性突变',
		'Likely_benign'									=> '可能良性突变',
		'Benign/Likely_benign'							=> '良性突变/可能良性突变',
		'Conflicting_interpretations_of_pathogenicity'	=> '致病性的矛盾解释',
		'Uncertain_significance'						=> '不确定性突变',
		'not_provided'									=> '未提供',
		'-'												=> '未提供',
	);
	%en_ch_mutationType = (
		'frameshift deletion'			=> '缺失突变',#'移码缺失',
		'frameshift insertion'			=> '插入突变',#'移码插入',
		'frameshift substitution'		=> '错义突变',#'移码替换',
		'nonframeshift deletion'		=> '缺失突变',#'非移码缺失',
		'nonframeshift insertion'		=> '插入突变',#'非移码插入',
		'nonsynonymous SNV'				=> '错义突变',#'非同义突变',
		'stopgain'						=> '无义突变',#'终止突变',
		'synonymous SNV'				=> '同义突变',
		'unknown'						=> '未知',
		'-'								=> '未知',
	);
}
sub load_yichuanfangshi{
	%yichuanfangshi = (
		'常隐' => 'AR',
		'常显' => 'AD',
		'X隐性' => 'XLR',
		'X显性' => 'XLD',
		'Y连锁' => 'YL',
		'线粒体' => 'MD',
		'-' => '-',
	);
}

sub delete_and_uniq{
	my( $acmg ) = @_;
	$acmg =~ s/,_drug_response//;
	$acmg =~ s/,_risk_factor//;
	$acmg =~ s/,_other//;
	$acmg =~ s/,_Affects//;
	$acmg =~ s/,_association//;
	if( $acmg eq "drug_response" or $acmg eq "risk_factor" ){
		#$acmg = "not_provided";
		$acmg = ".";
	}
	if( $acmg eq "." ){
		$acmg = "-";
	}
	return($acmg);
}
sub check_type{
	my($genotype,$ref,$alt) = @_;
	my ($type, $type_) = ("-", "-");
	if( length($ref) > length($alt) ){
		if( $genotype eq "DD" ){	
			$type = "纯合突变";
		}elsif( $genotype eq "DI" or $genotype eq "ID" ){ 
			$type = "杂合突变"; }
	}elsif( length($ref) < length($alt) ){
		if( $genotype eq "II" ){  
			$type = "纯合突变";
		}elsif( $genotype eq "DI" or $genotype eq "ID" ){ 
			$type = "杂合突变"; }
	}elsif( $alt eq "." and $genotype ne "$ref$ref" ){
		if( $genotype =~ /$ref/ ){
			$type = "杂合突变";
		}else{
			$type = "纯合突变";
		}
	}else{
		if( $genotype eq "$alt$alt" ){
			$type = "纯合突变";
		}elsif( $genotype eq "$ref$alt" or $genotype eq "$alt$ref" ){
			$type = "杂合突变"; }
	}
	if( $type eq "杂合突变" ){
		$type_ = "杂合";
	}elsif( $type eq "纯合突变" ){
		$type_ = "纯合";
	}else{
		$type_ = $type;
	}
	return($type, $type_);
}
#&output_xml(\%vars,$dirout,$section,$type);
sub output_xml {
	my ($vars,$outfile)=@_;
	
	##
	open my $out, '>:encoding(utf-8)', $outfile || die $!;
	XMLout($vars,  OutputFile => $out, NoAttr => 1,SuppressEmpty => "");

	return;
}

sub foreach_replace{
	my($hash) = @_;
	foreach my$k(keys %$hash){
		$hash->{$k} = replace($hash->{$k});
	}
	return $hash;
}

#
sub replace {
    my ($js)=@_;
	if( not defined $js ){
		return "";
	}

	my $utfcode = '';
        ##
	$js=~s/&lt;/</g;
	$js=~s/&gt;/>/g;
	$js=~s/&amp;/&/g;

	$js=~s/&/\\&/g;
    $js=~s/{/\\{/g;
    $js=~s/}/\\}/g;
    $js=~s/%/{\\%}/g;
    $js=~s/\n/\n\n/g;
	$js=~s/Ⅰ/\\RNum{1}/g;
	$js=~s/Ⅱ/\\RNum{2}/g;
	$js=~s/Ⅲ/\\RNum{3}/g;
	$js=~s/Ⅳ/\\RNum{4}/g;
	$js=~s/Ⅴ/\\RNum{5}/g;
	$js=~s/Ⅵ/\\RNum{6}/g;
	$js=~s/Ⅶ/\\RNum{7}/g;
	$js=~s/Ⅷ/\\RNum{8}/g;
	$js=~s/Ⅸ/\\RNum{9}/g;
	$js=~s/Ⅹ/\\RNum{10}/g;
	$js=~s/Ⅺ/\\RNum{11}/g;
	$js=~s/Ⅻ/\\RNum{12}/g;
	$js=~s/ⅩⅢ/\\RNum{13}/g;
	$js=~s/α/\\textalpha /g;
	$js=~s/β/\\textbeta /g;
	$js=~s/γ/\\textgamma /g;
	$js=~s/μ/\\textmu /g;
	$js=~s/δ/\\textdelta /g;
	$js=~s/κ/\\textkappa /g;
	$js=~s/ε/\\textepsilon /g;
	$js=~s/ƹ/\\textepsilon /g;
	$js=~s/\$/\\\$/g;
	$js=~s/≥/\$\\geq\$/g;
	$js=~s/≤/\$\\leq\$/g;

	$js=~s/~/\\textasciitilde /g;
	$js=~s/_/\\_/g;
	$js=~s/#/\\#/g;
	$js=~s/\//\{\/\}/g;
	while ($js=~/\^(\D+)/) {
		$js=~s/\^/\\\^{}/g;
	}
	while ($js=~/\^(\d+)/) {
		my $ori=$1;
		$js=~s/\^$ori/\$\^\{$ori\}\$/g;
	}

	while ($js=~/∮(\d+)/) {
		my $ori=$1;
		$js=~s/∮$ori/\$\_\{$ori\}\$/g;
	}
	$js=~s/【/\\vskip.6\\baselineskip\\noindent {\\bfseries\\wuhao 【/g;
	$js=~s/】/】}\\smallskip/g;
	$js=~s/腘/\\mbox{\\scalebox{0.5}[1]{月 }\\kern-.15em\\scalebox{0.75}[1]{国}}/g;
        
	return ($js);
}




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

sub guiyi_not_defined{
	my($arg) = @_;
	if(not defined $arg or $arg eq "" or $arg eq "." ){  
		$arg="-";  
	}
	return($arg);
}
