
my%hash;
open(IN,"xinzeng.txt");
while(<IN>){
	chomp;
	my ($name, $rs) = split/\t/,$_;
	#if( exists $hash{lc($rs)} ){	print "#$rs\n";	}
	push@{$hash{lc($rs)}{'title'}},$name;
}
close IN;

open(IN,"/data/bioit/biodata/chenx/biodata/chip_pipeline/v2/Data/00.chipDir/ASA-24v1-0_A1.csv.GRCh37/info.txt.add.rs.update");
while(<IN>){
	chomp;
	my @line = split/\t/,$_;
	if( exists $hash{lc($line[4])} or exists $hash{lc($line[6])} ){
		#if( $line[4] ne $line[6] ){	print "#$line[4] ne $line[6]\n";	}
		$hash{lc($line[6])}{'ASA'} = 1;
	}
}
close IN;

open(IN,"/data/bioit/biodata/chuanj/work/susceptibility/genetic-disease/chipArray/50Kchip_list_20190129.txt");
while(<IN>){
	chomp;
	if( exists $hash{lc($_)} ){
		$hash{lc($_)}{'50K'} = 1;
		#print "#$_\n";
	}
}
close IN;

foreach my$rs( sort keys %hash){
	if( not exists $hash{$rs}{'50K'} ){
		$hash{$rs}{'50K'} = 0;
	}
	if( not exists $hash{$rs}{'ASA'} ){
		$hash{$rs}{'ASA'} = 0;
	}
	
	my @titles = @{$hash{$rs}{'title'}};
	foreach (@titles){
		print "$_\t$rs\t$hash{$rs}{'ASA'}\t$hash{$rs}{'50K'}\n";
	}
}
