
my%hash_rs;
get_rs_hash("/data/bioit/biodata/wugz/meiyin/bin_finial/config_20190522/final.acmg.gene-rs-level.all.txt.addRefAlt");
get_rs_hash("/data/bioit/biodata/wugz/meiyin/bin_finial/config_20190522/final.mono.gene-rs-level.all.txt.addRefAlt");
get_rs_hash("/data/bioit/biodata/wugz/meiyin/bin_finial/config_20190522/final.cancers.gene-rs-level.all.txt.addRefAlt");

my$re=`ls /data/bioit/biodata/chuanj/data/dbsnp/human906/ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/chr*.txt`;
my@vcf=split/\n/,$re;
open(OUT,">/data/bioit/biodata/wugz/meiyin/bin_finial/config_20190522/rs.vcf.txt");
foreach (@vcf){
	get_vcf_rs($_);
}
close OUT;

sub get_rs_hash{
	my($in)=@_;
	open(IN,$in)or die "$in !\n";
	while(<IN>){
		chomp;
		my@line = split/\t/,$_;
		my$rs = $line[8];
		$hash_rs{$rs}=$chr;
	}
	close IN;
}
sub get_vcf_rs{
	my($in)=@_;
	open(IN,$in)or die "$in !\n";
	while(<IN>){
		chomp;
		my$lines = $_;
		my@line = split/\t/,$_;
		if( exists $hash_rs{$line[2]} ){
			print OUT $lines."\n";
		}
	}
	close IN;
}
