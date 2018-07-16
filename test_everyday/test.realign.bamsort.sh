outdir=/data/bioit/biodata/wugz/wugz_testout
time=20180713
sampleId=L80711-22-44
time=$1
sampleId=$2
bamfile=/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_$time/05.variant_detect/$sampleId.GATK_realign_new.bam
vcffile=/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_$time/05.variant_detect/variants/$sampleId.vcf

samtools sort $bamfile $outdir/ttttt.bam
samtools index $outdir/ttttt.bam.bam
total=`samtools view $outdir/ttttt.bam.bam chr11:5247993-5247996 |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|cut -f 1|sort -u|wc -l`
CD41=`samtools view $outdir/ttttt.bam.bam chr11:5247993-5247996 |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|awk '$6~/4D/'|cut -f 1|sort -u|wc -l`
ref=`samtools view $outdir/ttttt.bam.bam chr11:5247993-5247996 |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|awk '$6!~/4D/'|cut -f 1|sort -u|wc -l`
ratio=`echo "scale=5; $CD41/$total" |bc`

#echo $bamfile
#echo $outdir/ttttt.bam.bam
echo "$time $sampleId CD41 $CD41 $total $ratio (ref)$ref"
#awk 'BEGIN{printf "%.5f\n",'$CD41'/'$total'}'

#echo $vcffile
#less $vcffile|grep 5247992


# samtools tview $outdir/ttttt.bam.bam /data/bioit/biodata/duyp/bin/hg19/hg19.fasta
# chr11:5248173

