#!/bin/bash

# picture sim envalue for TT
PWD=$(dirname $_)
echo $PWD

n_cluster=1024
outfile=tt_result
while getopts "f:t:n:o:" arg
do
	case $arg in 
		f) fdir=$OPTARG ;;
		t) tdir=$OPTARG ;;
		n) n_cluster=$OPTARG ;;
		o) outfile=$OPTARG ;;
	esac
done
if [ -z $fdir -o -z $tdir ]; then
	echo Usage: -f from -t to
	exit 1
fi

if [ ! -d $fdir-sift ]; then
	$PWD/../simon/run sift $fdir $fdir-sift
fi
if [ ! -d $tdir-sift ]; then
	$PWD/../simon/run sift $tdir $tdir-sift
fi
find $fdir-sift -type f > fname
cat fname > aname
find $tdir-sift -type f > tname
cat tname >> aname

$PWD/BoF_for_TT/find_center $n_cluster aname c_tt
$PWD/BoF_for_TT/gen_feature $n_cluster fname c_tt > f_tt
$PWD/BoF_for_TT/gen_feature $n_cluster tname c_tt > t_tt
python3 $PWD/BoF_for_TT/find_close_batch.py f_tt t_tt| grep -oP '(?<=第)\d*(?=帧)|0\.\d*' | sed 'N;N;s/\n/\t/g' | sort -n | unix2dos > $outfile
rm {c,f,t}_tt {t,f,a}name
exit 0


