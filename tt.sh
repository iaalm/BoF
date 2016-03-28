#!/bin/bash

./find_center $1 fname c_tt
./gen_feature $1 fname c_tt > f_tt
python3 find_close.py f_tt > ../tt_result_$1
#rm f_tt c_tt

