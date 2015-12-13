#!/bin/bash
./svm-train $@ jd_svm_train jd_model
./svm-predict jd_svm_train jd_model output
./svm-predict jd_svm_test jd_model output
paste -d ',' fname output > submit_file
