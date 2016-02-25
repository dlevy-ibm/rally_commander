FILE=fdbmonitor$1.txt
echo node size > $FILE

#Copy the rabbit files
fdboutput(){
  echo -n $1 " ">> $FILE
  ssh $1 bridge fdb show | wc -l >> $FILE
}

while true
do
	date >> $FILE
    fdboutput controller1
    fdboutput controller2
    fdboutput compute17
    fdboutput compute57
    echo "------" >> $FILE
    echo "" >> $FILE
    sleep 4
done
