outdir=/data/bioit/biodata/wugz/wugz_testout
time=180707
sampleId=L80705-22-18
bamfile=/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_20$time/05.variant_detect/$sampleId.GATK_realign_new.bam

samtools sort $bamfile $outdir/ttttt.bam
samtools index $outdir/ttttt.bam.bam
total=`samtools view $outdir/ttttt.bam.bam chr11:5247993-5247996 |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|cut -f 1|sort -u|wc -l`
CD41=`samtools view $outdir/ttttt.bam.bam chr11:5247993-5247996 |grep "B-HBB-7992-D-TN\|HBB-8028-U-TN2-2"|awk '$6~/4D/'|cut -f 1|sort -u|wc -l`
ratio=`echo "scale=5; $CD41/$total" |bc`

echo $bamfile
echo $outdir/ttttt.bam.bam
echo "$sampleId CD41 $CD41 $total $ratio"
awk 'BEGIN{printf "%.5f\n",'$CD41'/'$total'}'


# samtools tview $outdir/ttttt.bam.bam /data/bioit/biodata/duyp/bin/hg19/hg19.fasta
# chr11:5248173

