FILE=$1.run$2.rabbit
echo que size > $FILE

while true
do
	date >> $FILE
	echo -n "Number of messages ">> $FILE
    rabbitmqctl list_queues | awk '{print $2}' | awk '{ SUM += $1} END { print SUM }' >> $FILE
    echo -n "Number of queues ">> $FILE
    rabbitmqctl list_queues | wc -l >> $FILE
    rabbitmqctl list_queues | grep -P -v "\t0" >> $FILE
    echo "------------------">> $FILE
    echo "">> $FILE
        sleep 4
done
