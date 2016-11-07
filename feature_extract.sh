#!/bin/bash

# picture sim envalue for TT
PWD=$(dirname $_)
echo $PWD

n_cluster=20000
while getopts "f:t:n:o:" arg
do
	case $arg in 
		f) fdir=$OPTARG ;;
		t) tdir=$OPTARG ;;
		n) n_cluster=$OPTARG ;;
	esac
done
if [ -z $fdir ]; then
	echo Usage: -f from
	exit 1
fi
if [ -z $tdir ]; then
	tdir=$fdir-out
        mkdir -p $tdir
fi

mkdir -p $fdir-sift
mkfifo /tmp/tt_lock
exec 10<>/tmp/tt_lock
for ((i=0;i<4;i++)) ;do
	echo >&10
done
for d in `ls $fdir` ; do
	if [ ! -d $fdir-sift/$d ]; then
		mkdir -p $fdir-sift/$d
		read -u 10
		{
			$PWD/run full-sift $fdir/$d $fdir-sift/$d
			echo >&10
		}&
	fi
done
find $fdir-sift/ -type f > aname
$PWD/find_center $n_cluster fname cluster_center
for d in `ls $fdir` ; do
	find $fdir-sift/$d -type f > fname
	$PWD/gen_feature $n_cluster fname cluster_center > $tdir/$d.txt
done

wait
exec 10>&-
rm cluster_center fname /tmp/tt_lock
exit 0


