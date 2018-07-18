outdir=/data/bioit/biodata/wugz/wugz_testout
time=20180707
sampleId=L80705-22-44
time=$1
sampleId=$2
bamfile=/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_$time/05.variant_detect/$sampleId.GATK_realign_new.bam
vcffile=/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_$time/05.variant_detect/variants/$sampleId.vcf
sortbam=$outdir/ttttt.one.bam
indexbam=$outdir/ttttt.one.bam.bam

samtools sort $bamfile $sortbam
samtools index $indexbam
total=`samtools view $indexbam chr11:5247995-5247996 |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|cut -f 1|sort -u|wc -l`
CD41=`samtools view $indexbam chr11:5247995-5247996 |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|awk '$6~/4D/'|cut -f 1|sort -u|wc -l`
ref=`samtools view $indexbam chr11:5247994-5247996 |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|awk '$6!~/4D/'|cut -f 1|sort -u|wc -l`

#eachSold=`samtools view /data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_$time/05.variant_detect/$sampleId.GATK_realign.bam |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2" |sort |awk '$6~/S/ && $10~/N/' |less -S |awk '$0~/MC:Z:.+M4D/' |wc -l`
#eachSoldid=`samtools view /data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_$time/05.variant_detect/$sampleId.GATK_realign.bam |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2" |sort |awk '$6~/S/ && $10~/N/' |less -S |awk '$0~/MC:Z:.+M4D/' |cut -f 1|xargs |perl -ne '{chomp;my@a=split;my$grepid=join"\\|",@a;print $grepid}'`
eachN=`samtools view $indexbam |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|awk '$10~/N.*N.*N/'|awk '$0~/M4D/'|cut -f 1`
eachS=`samtools view $indexbam |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|awk '$10~/N.*N/'|awk '$0~/M4D/'|cut -f 1|sort -u|wc -l`
eachall=`samtools view $indexbam |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|awk '$10~/N.*N/'|cut -f 1|sort -u|wc -l`


if [ $total > 0 ];then
	ratio=`echo "scale=5; $CD41/$total" |bc`
	rationew=`echo "scale=5; ($CD41-$eachS)/($total-$eachall)" |bc`

	echo $bamfile
	echo $indexbam
	echo "$time $sampleId CD41 $CD41 $total $ratio (ref)$ref $eachS $eachall $rationew"
	#awk 'BEGIN{printf "%.5f\n",'$CD41'/'$total'}'
fi

#echo $vcffile
#less $vcffile|grep 5247992


# samtools tview $outdir/ttttt.bam.bam /data/bioit/biodata/duyp/bin/hg19/hg19.fasta
# chr11:5248173

