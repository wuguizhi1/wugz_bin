outdir=/data/bioit/biodata/wugz/wugz_testout
bamlist=`less InsertSize.txt |awk '{print $1"."$2":/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_"$1"/05.variant_detect/"$2".GATK_realign.bam "}' |xargs `
cmd="perl InsertSize.pl -i $bamlist -od $outdir -m 800 -k InsertSize.SEAadjust"
#$cmd
echo ""
echo $cmd
echo ""
ls $outdir/InsertSize.SEAadjust* |xargs -n1


echo "perl /data/bioit/biodata/wugz/wugz_bin/bin/SEAsdjust/InsertSize.pl -i /data/bioit/biodata/wugz/wugz_bin/bin/SEAsdjust/InsertSize.txt -id /data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_20180707 -c /home/macx/workdir/ctDNA/cnv/180707_FC/gt/snp_indel/cffdna_EM.txt -od $outdir -m 800 -k InsertSize.SEAadjust"

 
