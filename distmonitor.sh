source stackrc
HYPERVISORS=$(nova hypervisor-list | cut -d'|' -f3 | tail -n +4 | head -n -1)
FILE=distmonitor$1.txt
echo compute number > $FILE

while true
do
    for X in $HYPERVISORS
    do
       echo -n $X " ">> $FILE
       nova hypervisor-servers $X | tail -n +4 | head -n -1 | wc -l >> $FILE
    done
    echo "------------------">> $FILE
	sleep 30
done


