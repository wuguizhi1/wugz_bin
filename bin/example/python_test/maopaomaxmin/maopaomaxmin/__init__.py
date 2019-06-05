
def max(lis):
	maxi = 0;
	maxnum = lis[0];
	for i in range(len(lis)-1):
		if(lis[i+1] > maxnum):
			maxi = i+1;
			maxnum = lis[i+1];
		
	return(maxnum, maxi);

def min(lis):
	mini = 0;
	minnum = lis[0];
	for i in range(len(lis)-1):
		if(lis[i+1] < minnum):
			mini = i+1;
			minnum = lis[i+1];
		
	return(minnum, mini);

def test():
	l=[1,8,6,2,5];
	(maxnum, maxi) = max(l);
	(minnum, mini) = min(l);
	print l;
	print "max:",maxnum," 第",maxi+1,"位";
	print "min:",minnum," 第",mini+1,"位";

