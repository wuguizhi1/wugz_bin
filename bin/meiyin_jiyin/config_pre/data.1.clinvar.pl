
my%result;
open(IN,"/data/bioit/biodata/chuanj/data/clinvar/clinvar_20190114.vcf");
while(<IN>){
	chomp;
	my($pos,$id,$ref,$alt,$info)=(split/\t/,$_)[1,2,3,4,7];
	#my@l=(split/;|=/,$info)[0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32];
	#print "@l\n";
	my($rs,$acmg,$name,$omim);
	if( $info =~ /CLNDN(.+)/){		
		my $n = $1; $name = (split/;|=/,$n)[1];
	}
	if( $info =~ /CLNSIG(.+)/ ){		
		my $n = $1;
		$acmg = (split/;|=/,$n)[1];
#		my $m = (split/;|=/,$n)[1];
#		if( $m =~ /([a-zA-Z0-9:_]+)/ ){
#			$acmg = $1; }
	}
	if( $info =~ /CLNDISDB(.+)/ ){	
		my $n = $1;	$omim = (split/;|=/,$n)[1]; 
	}
	if( $info =~ /RS=([0-9]+)/ ){
		$rs = $1;
		$result{$rs}{"N"}++;
		@{$result{$rs}{$result{$rs}{"N"}}} = ($id,$pos,$ref,$alt,$acmg,$name,$omim);
#		print "$rs\t$info\n";
	}
}
close IN;
my%disease;
open(IN,"$ARGV[0]");
while(<IN>){
	chomp;
	my($chr,$pos,$id,$ref,$alt,$chN,$enN,$omimid,$rs,$gene,$acmg)=(split/\t/,$_);
	my$rsN=substr($rs,2);
	@{$disease{$rsN}{"$chN:$acmg"}} = ($chr,$pos,$id,$ref,$alt,$chN,$enN,$omimid,$rs,$gene,$acmg);
}
close IN;
foreach my$rsN(keys %disease){
	my$disease_ = $disease{$rsN};
	foreach my$each(keys %$disease_){
		my($chr,$pos,$id,$ref,$alt,$chN,$enN,$omimid,$rs,$gene,$acmg)=@{$disease{$rsN}{$each}};
		if( exists $result{$rsN} ){	
			foreach my$index(1..$result{$rsN}{"N"}){
				my($id1,$pos1,$ref1,$alt1,$acmg1,$name1,$omim1) = @{$result{$rsN}{$index}};
				my $p=0;
				if( $acmg1 eq $acmg ){
					$p=1;
				}else{ 
					my@ac=split(/:/,$acmg1); 
					if( $ac[1] eq $acmg ) {
						$p=1;
					}
				}
				
				if( $p==1 ){
					my$print_ = "$chr\t$pos1\t$id1\t$ref1\t$alt1\t$chN\t$enN\t$omimid\t$rs\t$gene\t$acmg\t$exon\t$sys";
					if( $enN ne "" and $omimid ne "" ){
						if( $name1 =~ /$enN/ and $omim1 =~ /OMIM:$omimid/ ){
							print "$print_\n";
						}else{ 
			#				print "#$rs\t$omimid\t$enN\t$omim1\t$name1\n"; 
						}
					}elsif( $enN ne "" ){
						if( $name1 =~ /$enN/ ){
							print "$print_\n";
						}else{
			#				print "#$rs\t\t$enN\t\t$name1\n";
						}
					}elsif( $omimid ne "" ){
						if( $omim1 =~ /OMIM:$omimid/ ){
							print "$print_\n";
						}else{
			#				print "#$rs\t$omimid\t\t$omim1\t\n";
						}
					}else{
						print "$print_\n"; 
					}
			#	}else{	print "#$rs\t$result{$rsN}{'N'}\t#$acmg\t#$acmg1\n";	
				}
			}
		}
	}
}


