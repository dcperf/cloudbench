#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Copyright(c) 2020 Yin, Congmin <congmin.yin@intel.com>

date
fio_size=(4 16 64)
fio_depth=(1 8 16 32)
fio_jobs=(1)

#echo "" > item.csv
i=0
j=0
k=0
while (($i<3))
do
	#echo size =  ${fio_size[$i]}
	j=0
	k=0
	while (($j<4))
	do
		#echo depth =  ${fio_depth[$j]}
		k=0
		while (($k<1))
		do
			#echo size =  ${fio_size[$i]} depth =  ${fio_depth[$j]} jobs = ${fio_jobs[$k]}
			export FIO_SIZE=${fio_size[$i]}
			export FIO_DEPTH=${fio_depth[$j]}
			export FIO_JOBS=${fio_jobs[$k]}
			#echo $FIO_SIZE $FIO_DEPTH $FIO_JOBS
			#echo ${FIO_SIZE}k-${FIO_DEPTH}depth-${FIO_JOBS}jobs 
			echo ${FIO_SIZE}k-${FIO_DEPTH}depth 
			#echo $FIO_SIZE-$FIO_DEPTH-$FIO_JOBS  
			let "k++"
		done
		let "j++"
	done
	let "i++"
done
date
