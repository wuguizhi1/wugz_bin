#perl data.31.1.clinvar.pl /data/bioit/biodata/wugz/meiyin/dataIn1/fileNoFreqExon/final.acmg.gene-rs-level.all.txt.addRefAlt.2
#perl data.31.1.clinvar.pl /data/bioit/biodata/wugz/meiyin/dataIn1/fileNoFreqExon/final.mono.gene-rs-level.all.txt.addRefAlt.2
#perl data.31.1.clinvar.pl /data/bioit/biodata/wugz/meiyin/dataIn1/fileNoFreqExon/final.cancers.gene-rs-level.all.txt.addRefAlt.2

my(%store, %stArray);
open(IN,"/data/bioit/biodata/chuanj/work/susceptibility/genetic-disease/formatClinvar/clinvar.format.txt") or die;
# /data/bioit/biodata/wugz/meiyin/dataIn1/clinvar.format.txt
while(<IN>){
	chomp;
	my($ref, $alt, $rs, $AFexac, $AFtgp, $disE, $OMIM ) = (split/\t/,$_)[3,4,5,11,12,13,14];
	if( $rs eq "." ){ next; }
	push @{$stArray{$ref}{$alt}{$rs}}, "$disE:$OMIM:$AFexac:$AFtgp"; 

	if($disE ne "." ){	$store{$ref}{$alt}{$rs}{$disE}{'exac'}{$AFexac}++;	}
	if($OMIM ne "." ){	$store{$ref}{$alt}{$rs}{$OMIM}{'exac'}{$AFexac}++;	}
	if($disE ne "." ){	$store{$ref}{$alt}{$rs}{$disE}{'tgp'}{$AFtgp}++;	}
	if($OMIM ne "." ){	$store{$ref}{$alt}{$rs}{$OMIM}{'tgp'}{$AFtgp}++;	}
	if( ($store{$ref}{$alt}{$rs}{$disE}{'exac'}{$AFexac} > 1 and $store{$ref}{$alt}{$rs}{$OMIM}{'exac'}{$AFexac} > 1) or
		($store{$ref}{$alt}{$rs}{$disE}{'tgp'}{$AFtgp} > 1   and $store{$ref}{$alt}{$rs}{$OMIM}{'tgp'}{$AFtgp} > 1 ) ){
			print "$ref, $alt, $rs, $AFexac, $AFtgp, $disE, $OMIM\t2,repete!\n";
	}
}
close IN;

my %dis_gene, $dis_gene_N=0;;
open(IN,"/data/bioit/biodata/wugz/meiyin/dataIn1/fileNoFreqExon/AD.txt");
while(<IN>){
	chomp;
	if( /^#/ ){	next;	}
	my($dis, $gene, $AD) = split/\t/,$_;
	$dis_gene{$dis}{$gene} = $AD;
	$dis_gene_N++;
}
print "mono(380:439)+acmg(58:67)+cancers(17:107) =  $dis_gene_N (==613?)\n";
close IN;

my%print;
open(I,"$ARGV[0]") or die;
open(O,">$ARGV[1]");
while(<I>){
	chomp;
	my $lines = $_;
	my @line = split/\t/,$lines;
	my ($chr, $ref, $alt, $disC, $disE, $OMIM, $rs, $gene ) = @line[0,3,4,5,6,7,8,9];
	if( not exists $print{$rs} ){ $print{$rs} = 0;  }

	my($disE_,$OMIM_,$AFexac,$AFtgp);
	if( exists $stArray{$ref}{$alt}{$rs} ){
		my@result = @{$stArray{$ref}{$alt}{$rs}};
		my$no_n=0; 
		foreach my$re(@result){
			($disE_,$OMIM_,$AFexac,$AFtgp) = split/:/,$re;
			if( $disE eq $disE_ and $OMIM eq $OMIM_ ){
				$print{$rs}++;
			}elsif( $disE eq $disE_ and $disE ne "" ){
				$print{$rs}++;
			}elsif( $OMIM eq $OMIM_ and $OMIM ne "" ){
				$print{$rs}++; 
			}elsif( $disE eq "" and $OMIM eq "" ){
#				print "$chr, $ref, $alt, $rs\t($disE, $OMIM)\t(how to match?)@result!\n";
				$print{$rs}++;
			}else{
				$no_n++;
			}
		}
		if( $no_n == scalar(@result) ){
			print "$chr, $ref, $alt, $rs\t($disE, $OMIM)\t@result!\n";
		}
	}else{
		($AFexac,$AFtgp) = (".",".");
		print "$chr, $ref, $alt, $rs\t($disE, $OMIM)\tno!!!!!\n";
	}

	print O "$lines\t";
	my $mis_n = 20 - scalar(@line);
	foreach my$mis(1..$mis_n){
		print O ".\t";
	}
	if( not exists $dis_gene{$disC}{$gene} ){
		$dis_gene{$disC}{$gene} = "-"; print "$disC\t$gene\t no!\n";
		$dis_gene_N++;
	}
	print O "$dis_gene{$disC}{$gene}\t$AFexac\t$AFtgp\n";
	next;


	if( $disE eq "" ){	$disE=$OMIM;	}
	if( $disE eq "" ){	print "$chr, $ref, $alt, $rs, ($disE, $OMIM)\t#########\n";}

	my($AFexac_line, $AFtgp_line);
	if( exists $store{$ref}{$alt}{$rs}{$disE} ){
		my $exac = $store{$ref}{$alt}{$rs}{$disE}{'exac'};
		my $tgp = $store{$ref}{$alt}{$rs}{$disE}{'tgp'};
		my @AFexac = keys %$exac;
		my @AFtgp = keys %$tgp;
		if( scalar(@AFexac) == 1 and $store{$ref}{$alt}{$rs}{$disE}{'exac'}{$AFexac[0]} == 1 ){
			$AFexac_line = $AFexac[0];
		}else{
			print "$chr, $ref, $alt, $rs, ($disE, $OMIM)\texac\n";
		}

		if( scalar(@AFtgp) == 1 and $store{$ref}{$alt}{$rs}{$disE}{'tgp'}{$AFtgp[0]} == 1 ){
			$AFtgp_line = $AFtgp[0];
		}else{
			print "$chr, $ref, $alt, $rs, ($disE, $OMIM)\ttgp\n";
		}
	}else{
		print "$chr, $ref, $alt, $rs, ($disE, $OMIM)\tno!\n";
	}

	if( defined $AFexac_line and defined $AFtgp_line ){
		if( $print{$rs}==0 ){ $print{$rs} = 1;	}
#		print O "$lines\t$AFexac_line\t$AFtgp_line\n";
	}
}
close I;
close O;

foreach my$rs(keys %print){
	if( $print{$rs} != 1 ){ 
#		print "######$rs\t$print{$rs}\n";
	}
}
print "mono(380:439)+acmg(58:67)+cancers(17:107) = $dis_gene_N (==613?)\n";
