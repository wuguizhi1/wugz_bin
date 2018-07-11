
bamlist=`less InsertSize.txt |awk '{print $1"."$2":/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_"$1"/05.variant_detect/"$2".GATK_realign.bam "}' |xargs `
cmd="perl InsertSize.pl -i $bamlist -od ../../test_out -m 800 -k result"
$cmd
echo $cmd

