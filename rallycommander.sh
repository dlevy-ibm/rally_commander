#!/bin/bash
WAIT_TIME=150
DEPLOYER="root@169.57.123.165"
NMON_RUNTIME=30000
NMON_WINDOW=2
NUMBER_OF_RUNS=1
TARGET_COMPUTE=4


#Kill the program if we dont have correct arguemnts
die () {
    echo >&2 "$@"
    exit 1
}


#Kill the  process
killprocess() {
   ssh $DEPLOYER ssh $1 "'
       pgrep -f $2 | xargs kill -9
   '"
}

#Kill the nmon process
killdeployprocess() {
   ssh $DEPLOYER "pgrep -f $1 | xargs kill -9"
}

#Copy the nmon files
copynmon(){
  ssh $DEPLOYER ssh $2 "'
        cat run$3.nmon
  '" >> $1/$2.run$3.nmon
}

#Copy the rabbit files
copyrabbit(){
  ssh $DEPLOYER ssh $2 "'
        cat $2.run$3.rabbit
  '" >> $1/$2.rabbitcontroller$3.txt
}



runrally(){
	echo "Running rally tests"
	cat rallyrun.sh | sed "s/REPLACE_VAL/$1/g"| ssh $DEPLOYER
	scp $DEPLOYER:/root/rally-install/output$1.html $2/output$1.html
}


rundistributionmonitor(){
    echo "Running distrubtion monitor"
    scp distmonitor.sh $DEPLOYER:/root/distmonitor.sh
    ssh -f $DEPLOYER /root/distmonitor.sh $1
}

runfdbmonitor(){
    echo "Running fdb monitor"
    scp fdbmonitor.sh $DEPLOYER:/root/fdbmonitor.sh
    ssh -f $DEPLOYER /root/fdbmonitor.sh $1
}

runrabbitmonitor(){
    echo "Running rabbit monitor"
    scp -p rabbitmonitor.sh $DEPLOYER:/root/rabbitmonitor.sh
    ssh $DEPLOYER scp -p rabbitmonitor.sh $1:/root/rabbitmonitor.sh
    ssh -f $DEPLOYER ssh -f $1 "'
       /root/rabbitmonitor.sh $1 $2
    '"
    echo "DONE RUNNING RABBIT-----"
}


killtestsuite(){
    echo "Killing all test suite processes"
    echo "Killing nmon"
    killprocess controller1 nmon
    killprocess controller2 nmon
    killprocess compute$TARGET_COMPUTE nmon
    echo "Killing top"
    killprocess controller1 top
    killprocess controller2 top
    killprocess compute$TARGET_COMPUTE top
    echo "Killing distmonitor"
    killdeployprocess distmonitor
    echo "Kill rabbitmonitor"
    killprocess controller1 rabbitmonitor
    killprocess controller2 rabbitmonitor
    echo "Kill fdbmonitor"
    killdeployprocess fdbmonitor
}

#Validate arguments
[ "$#" -eq 1 ] || die "1 argument required (output directory), $# provided"

killtestsuite

#Copy rally test file
scp ./boot-ping-ssh-vm-share-network.yaml $DEPLOYER:/root/rally-install/rally/samples/tasks/scenarios/vm/boot-ping-ssh-vm-share-network.yaml

echo Create results folder: $1
mkdir $1

for i in `seq 1 $NUMBER_OF_RUNS`;
do
    echo "--------------------------------------------"
    echo "--------------------------------------------"
    echo "---- Beginning run $i of $NUMBER_OF_RUNS---"
    echo "--------------------------------------------"
    echo "--------------------------------------------"

    echo "Running nmon on controller1 and controller2 and compute $TARGET_COMPUTE"
    ssh $DEPLOYER ssh controller1 nmon -fT -s $NMON_WINDOW -c $NMON_RUNTIME -F /root/run$i.nmon
    ssh $DEPLOYER ssh controller2 nmon -fT -s $NMON_WINDOW -c $NMON_RUNTIME -F /root/run$i.nmon
    ssh $DEPLOYER ssh compute$TARGET_COMPUTE nmon -fT -s $NMON_WINDOW -c $NMON_RUNTIME -F /root/run$i.nmon
    echo "Running top on controller1 and controller2 and compute $TARGET_COMPUTE"
    ssh $DEPLOYER -f -n ssh controller1 -f -n "top -d 4 -b -o USER | grep -ve root" > $1/controller1.run$i.top
    ssh $DEPLOYER -f -n ssh controller2 -f -n "top -d 4 -b -o USER | grep -ve root" > $1/controller2.run$i.top
    ssh $DEPLOYER -f -n ssh compute$TARGET_COMPUTE -f -n "top -d 4 -b -o USER | grep -ve root" > $1/compute$TARGET_COMPUTE.run$i.top

    echo "Running rabbit monitor on the master controller"
    #runrabbitmonitor controller1 $i
    runrabbitmonitor controller2 $i

    echo "Sleep for 10 (s)"
    sleep 10
    rundistributionmonitor $i
    runfdbmonitor $i
    runrally $i $1
    echo "Waiting $WAIT_TIME (s) before next test run..."
    sleep $WAIT_TIME

    killtestsuite
    
    echo "Copy over result files"
    copynmon $1 controller1 $i
    copynmon $1 controller2 $i
    copyrabbit $1 controller2 $i
    copynmon $1 compute$TARGET_COMPUTE $i
    scp $DEPLOYER:/root/distmonitor$i.txt $1/distmonitor$i.txt
    scp $DEPLOYER:/root/fdbmonitor$i.txt $1/fdbmonitor$i.txt
done  

echo "Process complete"
