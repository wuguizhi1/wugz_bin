
outbam=/data/bioit/biodata/wugz/wugz_testout/HBBsnp/test.bam
bamfile=/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_20180713/05.variant_detect/L80711-22-44.GATK_realign.bam

`samtools view -h $bamfile chr11:5248200-5248200|grep "^\@\|A-HBB-8200-U-TN\|A1-HBB-8200-D-TN" >$outbam`
alt=`/home/zenghp/bin/sam2tsv -r /data/bioit/biodata/duyp/bin/hg19/hg19.fasta $outbam |awk '$7==5248200'|awk '$5=="A" '|cut -f 1 |sort -u |wc -l`
ref=`/home/zenghp/bin/sam2tsv -r /data/bioit/biodata/duyp/bin/hg19/hg19.fasta $outbam |awk '$7==5248200'|awk '$5=="T" '|cut -f 1 |sort -u |wc -l `
totalN=`samtools view $outbam |awk '$10~/N.*N/' |cut -f 1 |sort -u |wc -l`
altNid=`/home/zenghp/bin/sam2tsv -r /data/bioit/biodata/duyp/bin/hg19/hg19.fasta $outbam |awk '$7==5248200'|awk '$5=="A" ' |cut -f 1 |sort -u |xargs |perl -ne '{chomp;my@a=split;my$l=join"\\\|",@a;print "$l";}' `
altN=`samtools view $outbam |grep $altNid |awk '$10~/N.*N/' |cut -f 1 |sort -u |wc -l`

total=$(( $alt + $ref ))
echo $total 

if [ $total > 0 ];then
	ratio=`echo "scale=5; $alt/($ref+$alt)" |bc`
	ratioN=`echo "scale=5; ($alt-$altN)/($ref+$alt-$totalN)" |bc`

	echo $outbam
	echo $bamfile
	echo "$ref $alt $ratio $totalN $altN $ratioN"
fi

