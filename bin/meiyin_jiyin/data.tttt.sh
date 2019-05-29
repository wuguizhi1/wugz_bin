
cd /data/bioit/biodata/wugz/meiyin/bin_finial
in=config_20190522/final.$1.gene-rs-level.all.txt.addRefAlt
in1=config_20190522/final.$1.gene-rs-level.all.txt.addRefAlt.1
in2=config_20190522/final.$1.gene-rs-level.all.txt.addRefAlt.2

new=config_20190522/config.$1
old=/data/bioit/biodata/wugz/meiyin/dataIn1/final.$1.gene-rs-level.all.txt.addRefAlt.2

#cat /data/bioit/biodata/wugz/meiyin/bin_test/test_in/final.$1.gene-rs-level.all.txt.addRefAlt config_20190522/addon.$1.gene-rs-level.txt.addRefAlt  >$in
# perl data.1.clinvar.pl $in >$in1

# perl data.11.clinvar.after.annovar.prepare.pl
# scp 10.0.0.204:/data/bioit/biodata/wugz/meiyin/bin_finial/config_20190522/rs.vcf.txt ./
# perl /data/bioit/biodata/database/humandb/table_annovar.pl rs.vcf.txt /data/bioit/biodata/database/humandb/  -buildver hg19 -out annovar.20190524 -remove -protocol refGene,esp6500siv2_all,1000g2014oct_all,1000g2014oct_eas,nci60,avsnp144,clinvar_20150330,v180403-TMA-AB-10S-noSNP -operation g,f,f,f,f,f,f,f -nastring . -vcfinput --otherinfo >annovar.20190524.log
###############    exac only once   ##########################################################
# scp 10.0.0.9:/data/bioit/biodata/wugz/wugz_bin/bin/meiyin/dataIn20190524/annovar.20190524.hg19_multianno.txt

perl data.2.annovarvcf.pl $1 $in1 $in2
perl data.31.1.clinvar.pl $in2 $new

less $new |sed 's/\t\t\t/\t/g'|sort -n >$new.sort 
less $old |sed 's/\t\t\t/\t/g'|sort -n >$new.sortold 

echo $in 
echo $new

