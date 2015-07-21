#!/bin/bash

if [ $# -ne 2 ]
then
	echo "use $0 no_of_users username_perfix"
	echo "for example $0 10 student"
	echo "creates ten users student1 ... student10"
	echo "exiting ..."
	exit 1
else
	echo "creating $1 users with names ${2}1 ... ${2}$1 "
fi

for n in $(seq 1 $1)
do
	echo "$2$n,user $2$n,$2$n@demo.ex,12345678912"

done
