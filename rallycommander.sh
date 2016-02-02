#!/bin/bash
WAIT_TIME=150
DEPLOYER="root@169.57.123.165"
NMON_RUNTIME=30000
NMON_WINDOW=2
NUMBER_OF_RUNS=4
#Kill the program if we dont have correct arguemnts
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument required (output directory), $# provided"

#Kill the nmon process
killprocess() {
   ssh $DEPLOYER ssh $1 "'
       pgrep -f $2 | xargs kill -9
   '"
}

#Copy the nmon files
copynmon(){
  ssh $DEPLOYER ssh $2 "'
        cat run$3.nmon
  '" >> $1/$2.run$3.nmon
}

#Copy the nmon files
copytop(){
  ssh $DEPLOYER ssh $2 "'
        cat /root/run$3.top
  '" >> $1/$2.run$3.top
}

runrally(){
	echo "Running rally tests"
	cat rallyrun.sh | sed "s/REPLACE_VAL/$1/g"| ssh $DEPLOYER
	scp $DEPLOYER:/root/rally-install/output$1.html $2/output$1.html
}



echo Create results folder: $1
mkdir $1
for i in `seq 1 $NUMBER_OF_RUNS`;
do
    echo "---- Beginning run $i of $NUMBER_OF_RUNS---"
    echo "Running nmon and top on controller1 and controller2"
    ssh $DEPLOYER ssh controller1 nmon -fT -s $NMON_WINDOW -c $NMON_RUNTIME -F /root/run$i.nmon
    ssh $DEPLOYER ssh controller2 nmon -fT -s $NMON_WINDOW -c $NMON_RUNTIME -F /root/run$i.nmon
    ssh $DEPLOYER -f -n ssh controller1 -f -n top -d 4 -b -o USER >> $1/controller1.run$i.top
    ssh $DEPLOYER -f -n ssh controller2 -f -n top -d 4 -b -o USER >> $1/controller2.run$i.top
    echo "Sleep for 10 (s)"
    sleep 10
    #ssh $DEPLOYER ssh controller1 top -b -d 10 > top$i.txt
    runrally $i $1
    echo "Waiting $WAIT_TIME (s) before next test run..."
    sleep $WAIT_TIME
    echo "Killing nmon1 and nmon2"
    killprocess controller1 nmon
    killprocess controller2 nmon
    killprocess controller1 top
    killprocess controller2 top
    copynmon $1 controller1 $i
    copynmon $1 controller2 $i
    #copytop $1 controller1 $i
    #copytop $1 controller2 $i
done  

echo "Process complete"
