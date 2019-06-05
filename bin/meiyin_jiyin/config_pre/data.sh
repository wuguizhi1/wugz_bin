
perl data.1.clinvar.pl $1 >$1.1
perl data.2.annovarvcf.pl $1.1 >$1.4

# perl data.3.xml.pl -file /data/bioit/biodata/chenx/gits/susceptibility/susceptibility-dev-test/MeiYin/CN/MeiYin_xiaotaoxi/daquantao/test.dat -conf /data/bioit/biodata/wugz/meiyin/dataIn1/final.cancers.gene-rs-level.all.txt.addRefAlt.2 -out /data/bioit/biodata/wugz/meiyin/dataout/




# 查找有矛盾位点，参照芯片设计情况，注释掉错误突变信息
less -S $1.4 |cut -f 6,9 |less -S |sort |uniq -c |awk '{if($1>=2){ print $1"\t"$2"\t"$3 }}' >ttt.twice
awk -F '\t' 'NR==FNR{ a[$2][$3]=1 } NR>FNR{  if(a[$6][$9]){print $0} }' ttt.twice $1.4  >ttt.twice.each

rm $1.1  ttt.twice

# 检查有矛盾位点在各个文件是否有错误的单行，需注释
awk -F '\t' 'NR==FNR{a[$1]=1}; NR>FNR{ if(a[$9]==1){ print  }  }' exists_conflict_rs.txt final.acmg.gene-rs-level.all.txt.addRefAlt.2 |cut -f 1-6,9|less -S

# 与探针信息及实际样本结果存在矛盾的点查找
less -S /data/bioit/biodata/chenx/gits/susceptibility/susceptibility-dev/templates/MeiYin/CN/MeiYin_xiaotaoxi/daquantao/_template90.db2xml/config_cancer/chip.data.stat | awk '{print $(NF - 1)"\t"$1 }' |awk -F '' '{print $1"\t"$3$4$5$6$7$8$9$10$11$12$13$14$15$16}' |tr R r >sample_genotype.txt

awk -F '\t' 'NR==FNR{a[$3]=$1;b[$3]=1} NR>FNR{ if( b[$9]==1 ){ if( a[$9]==$4 ){ print "#"a[$9]"\t"$0  }else if(a[$9]=="I" && length($4)>length($5) ){ print "##"a[$9]"\t"$0 }else if(a[$9]=="D" && length($4)<length($5) ){ print "###"a[$9]"\t"$0 }else{ print a[$9]"\t"$0 } } }' sample_genotype.txt final.acmg.gene-rs-level.all.txt.addRefAlt.2 |grep -v "#" |less -S



