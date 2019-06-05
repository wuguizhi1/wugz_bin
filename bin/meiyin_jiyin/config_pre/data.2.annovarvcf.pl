
use Data::Dumper;

my %ignore_rs;
open(RS,"/data/bioit/biodata/chenx/gits/susceptibility/susceptibility-dev/pre/item2snpids/result/MeiYin/CN/MeiYin_xiaotaoxi/daquantao/daquantao.disease.snp.relation.all.snp.xls");
while(<RS>){
	chomp; my$Rs=$_;
	$ignore_rs{lc($Rs)} = 1;
}
close RS;

my %annovar_vcf;
open(IN,"/data/bioit/biodata/wugz/meiyin/bin_finial/config_20190522/annovar.20190524.hg19_multianno.txt");
while(<IN>){
	chomp; my$lines=$_;
	my@line = split/\t/,$lines;
	my($chr,$s,$e,$ref,$alt,$exon,$gene,$cdotall,$sys,$pdotall,$all,$es,$rs,$vcfref,$vcfalt) = @line[0,1,2,3,4,5,6,7,8,9,11,12,22,23,24];
	my($SMPD1,$NM,$exonN,$cdot,$pdot) = (".", ".", ".", ".", ".");
	if( $line[5] eq "splicing" or $line[5] eq "UTR3" or $line[5] eq "UTR5"){
		$SMPD1=$gene;		($NM,$exonN,$cdot,$pdot) = split/:/,$cdotall;
	}else{
		($SMPD1,$NM,$exonN,$cdot,$pdot) = split/:/,$pdotall;
	}

	if( length($ref) > length($alt) ){
		my@alts = split/,/,$vcfalt;
		foreach my$i(0..$#alts){
			if( "$alts[$i]$ref" eq $vcfref and $vcfref =~ /$alts[$i]$/ ){
				#my$each = reverse $vcfref;
				#$each =~ s/$alts[$i]//;
				#$ref = reverse $each;
			}
		}
	}
	if( $alt eq "-" or $ref eq "-" ){
		my@alts = split/,/,$vcfalt;
		foreach my$i(0..$#alts){
			if( "$alts[$i]$ref" eq $vcfref ){
				$ref = $vcfref; $alt = $alts[$i];
				$s = $s - length($alts[$i]);
			}elsif( "$vcfref$alt" eq $alts[$i] ){
				$ref = $vcfref; $alt = $alts[$i];
				$s = $s - length($vcfref) + 1;
			}
		}
	}
	#print "#annovar#$rs\t$s\t$ref:$alt\t$exon,$sys,$SMPD1,$NM,$exonN,$cdot,$pdot,$all,$es\t$vcfref,$vcfalt\n";
	@{$annovar_vcf{$rs}{$s}{"$ref:$alt"}}=($exon,$sys,$SMPD1,$NM,$exonN,$cdot,$pdot,$all,$es);
}
close IN;

my%disease;
load_en_order();
open(IN,"$ARGV[1]");
open(OUT,">$ARGV[2]");
while(<IN>){
	chomp;my$lines=$_;
	my@line = split/\t/,$lines;
	my($chr,$pos,$id,$ref,$alt,$chN,$enN,$omimid,$rs,$gene,$acmg)=@line[0..10];
	my($exon,$sys,$SMPD1,$NM,$exonN,$cdot,$pdot,$all,$es) = (".",".",".",".",".",".",".",".",".");
=pob
	my($point, $ref_, $alt_, $type) = check_ref_alt($chr,$pos,$ref,$alt,$rs);
	if( $point ne "" ){
		($exon,$sys,$SMPD1,$NM,$exonN,$cdot,$pdot,$all,$es) = @{$annovar_vcf{$rs}{$point}{"$ref_:$alt_"}};
	}
=cut
	if( exists $annovar_vcf{$rs}{$pos}{"$ref:$alt"} ){
		($exon,$sys,$SMPD1,$NM,$exonN,$cdot,$pdot,$all,$es) = @{$annovar_vcf{$rs}{$pos}{"$ref:$alt"}};
	}else{
		
	}

	if( exists $change_to_conflict{"$rs:$ref:$alt"} ){
		$acmg = "Conflicting_interpretations_of_pathogenicity";
	}
	if( exists $delete_ch{$chN} ){ 
		print OUT "#";  
	}
	if( exists $delete_ch_gene{"$ARGV[0]:$chN:$gene"} ){
		print OUT "#";
	}
	if( exists $ignore_rs{$rs} ){
		print OUT "#";
	}


	if( exists $delete_pos{"$rs:$ref:$alt"} ){
		if( $delete_pos{"$rs:$ref:$alt"} ne "1" ){
			my($ref_, $alt_) = split/:/,$delete_pos{"$rs:$ref:$alt"};
			print OUT "$chr\t$pos\t$id\t$ref_\t$alt_\t$chN\t$enN\t$omimid\t$rs\t$gene\t$acmg\t\t\t";
			print OUT "$exon\t$sys\t$SMPD1\t$NM\t$exonN\t$cdot\t$pdot\t$all\t$es\n";
		}
		print OUT "#";
	}

	if( $rs eq "rs121908799" ){
		#print Dumper $rs, $annovar_vcf{$rs};
	}
	if( $exon eq "."  ){
		if( exists $delete_pos{"$rs:$ref:$alt"} or exists $change_to_conflict{"$rs:$ref:$alt"} ){
		}elsif( exists $annovar_vcf{$rs} ){
		}else{
			print "##$chr,$pos,$ref,$alt,$rs\n";	next;
		}
	}

	print OUT "$chr\t$pos\t$id\t$ref\t$alt\t$chN\t$enN\t$omimid\t$rs\t$gene\t$acmg\t\t\t";
	print OUT "$exon\t$sys\t$SMPD1\t$NM\t$exonN\t$cdot\t$pdot\t$all\t$es\n";
}
close IN;
close OUT;

sub check_ref_alt{
	my($chr,$pos,$ref,$alt,$rs)=@_;
	my($point, $ref_, $alt_);
	if( not exists $annovar_vcf{$rs}{$pos}{"$ref:$alt"} ){
		my$annovar_rs = $annovar_vcf{$rs};
		foreach my$p(keys %$annovar_rs){
			my$annovar_p = $annovar_rs->{$p};
			foreach my$each( keys %$annovar_p ){
				($ref_, $alt_) = split/:/,$each;
				my$l=length($ref_);
				if( $ref_ eq "-" and "$ref$alt_" eq $alt ){	
					return($p, $ref_, $alt_,"insert");
#				}elsif( $alt_ eq "-" and "$alt$ref_" eq $ref ){
#					return($p, $ref_, $alt_);
				}elsif( $alt_ eq "-" and $l+1==length($ref) ){
					my$seqall = get_samtools_faidx("chr$chr",$pos,$p+$l-1);
					if( substr($seqall,1,($p-$pos-1)) eq substr($seqall,-($p-$pos-1)) ){
						return($p, $ref_, $alt_,"delete2");
					}elsif( substr($seqall,1,$l) eq substr($seqall,-$l)  ){
						return($p, $ref_, $alt_,"delete1");
					}
				}
			}
		}
	}else{
		return($pos,$ref,$alt,"snp");
	}
}
sub get_samtools_faidx{
	my($chr,$sta,$end)=@_;
	my$RefGenome="/data/bioit/biodata/zenghp/hg19/hg19.fasta";
	my $genome_ref = `samtools faidx $RefGenome $chr:$sta-$end`;
	$genome_ref =~ tr/ATGCatgc/ATGCATGC/;
	my( $ref_id, @seq_ref_1 ) = split( /\n/,$genome_ref );
	my $ref_seq12 = join "",@seq_ref_1;
	return($ref_seq12);
}
sub load_en_order{
	%insert_iscan_error = (
		'rs387906244:T:TA' =>'TA:T',
		'rs121908799:AA:G' =>1,
		'rs397508669:G:GT' =>1,
		'rs398124245:C:CG' =>1,
		'rs397515732:T:TA' =>1,
		'rs118203563:AG:A' =>1,
		'rs397507654:C:CA' =>1,
		'rs397507781:C:CT' =>1,
		'rs397507814:G:GA' =>1,
		'rs397507744:T:TG' =>1,
	);
	%delete_ch = (
		'非霍奇金氏淋巴瘤'	=>1,
		'膀胱癌'			=>1,
		'脑胶质瘤'			=>1,
		'宫颈癌'			=>1,
	);
	%delete_ch_gene = (
		'cancers:乳腺癌:BRCA1'	=>1,
		'cancers:乳腺癌:BRCA2'  =>1,
		'cancers:卵巢癌:BRCA1'  =>1,
		'cancers:卵巢癌:BRCA2'  =>1,
		'mono:家族性腺瘤性息肉病2型:MUTYH'	=>1,
		'mono:皮肤弹性过度综合征6型:PLOD1'	=>1,
		'mono:皮肤弹性过度综合征6型:MFN2'	=>1,
		'mono:皮肤弹性过度综合征7型:ADAMTS2'	=>1,
	);
	%delete_pos = (
		'rs121908746:C:CA'	=>1,
		'rs121908746:CAA:C'	=>1,
		'rs180177102:CAA:C' =>1,
		'rs397507272:T:TA' =>1,
		'rs397507583:C:CAG' =>1,
		'rs397507623:AAGAG:A' =>1,
		'rs397508637:G:GA' =>1,
		'rs397508842:G:GA' =>1,
		'rs397509158:TC:T' =>1,
		'rs397509162:A:AT' =>1,
		'rs558037268:C:CT' =>1,
		'rs80359301:G:GA' =>1,
		'rs80359388:AT:A' =>1,
		'rs111033640:C:CCAGT'	=>1,

		'rs397507781:C:CT' =>'CT:C',
		'rs397507814:G:GA' =>'GA:G',
		'rs397508669:G:GT' =>'GT:G',
		'rs397515732:T:TA' =>'TA:T',
		'rs398124245:C:CG' =>'CG:C',
		'rs397507654:C:CA' =>'CA:C',
		'rs397507744:T:TG' =>'TG:T',
		'rs121908799:AA:G' =>'A:G',
		'rs118203563:AG:A' =>'AG:AGGA',
		'rs387906244:T:TA' =>'TA:T',
	);

	%change_to_conflict = (
		'rs750664148:A:C' =>1,
		'rs28929474:C:T' =>1,
		'rs3755319:A:.' =>1,
		'rs3755319:A:C' =>1,
		'rs2046210:G:A' =>1,
		'rs56378716:A:G' =>1,
		'rs1799945:C:G' =>1,
	);
}

