./after $1 > t1
sed -i 's/..\/sift\/\(.*\)\.sift/\1/' t1
sort t1 > t
grep Train t > t2
join -t ':' train_label.txt t2 | sed 's/.*jpg\:\([0-9]*\)\:/\1/' > svm_train
grep Test t  | sed 's/Test[0-9]*\.jpg:/0/' > svm_test
grep Test t  | awk -F: '{print $1}' > fname
