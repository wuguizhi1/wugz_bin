
my $time = $ARGV[0];
my $sample = $ARGV[1];
my $newbam = "/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_$time/05.variant_detect/$sample.GATK_realign.bam";
my $max_x = 1000;
my $outdir = "/data/bioit/biodata/wugz/wugz_testout/CD41_png";
if( ! -d $outdir ){
	`mkdir $outdir`;
}
my $fsize = "$outdir/$time.$sample.txt";
`rm $fsize`;
`samtools sort $newbam $outdir/test`;
`samtools index $outdir/test.bam`;
my $cmd = "samtools view -f 0x40 -F 0x800 $outdir/test.bam chr11:5247993-5247996 |perl -ane '{
	if( \$_ =~ /XF:i:(\\d+)/ ){
		my \$XP = \$1;
		if( \$XP <= $max_x ){
			print \"$sample\\t\$XP\\n\";
		}
	}
}' >>$fsize ";
`$cmd`;
`Rscript /data/bioit/biodata/zenghp/bin/tools/drawing/density/multiDensity.r --infile $fsize --outfile $fsize.png  --value.col 2 --group.col 1 --group.lab "group lab" --x.lab "x lab" --y.lab "y lab" --x.lim $max_x  --title.lab "title lab" --skip 1`;
`Rscript /data/bioit/biodata/wugz/small_work/zenghuapingWork/depthCorrect/intersizedir/SEAintersize/hist.r --infile $fsize --outfile $fsize.hist.png  --value.col 2 --group.col 1 --group.lab "group lab" --x.lab "x lab" --y.lab "y lab" --title.lab "title lab" --skip 1`;

