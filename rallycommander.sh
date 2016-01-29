#!/bin/bash
WAIT_TIME=150
DEPLOYER="root@169.53.176.174"
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
killnmon() {
   ssh $DEPLOYER ssh $1 "'
       pgrep -f nmon | xargs kill -9
   '"
}

#Copy the nmon files
copynmon(){
  # ssh $DEPLOYER ssh $2 "'
  #     ls -t | grep .*nmon | head -n1 | xargs -r cat
  #  '" >> $1/$2.nmon
  ssh $DEPLOYER ssh $2 "'
        cat run$i.nmom
  '" >> $1/$2.run$3.nmon

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
    echo "Running nmon on controller1 and controller2"
    ssh $DEPLOYER ssh controller1 nmon -fT -s $NMON_WINDOW -c $NMON_RUNTIME -F run$i.nmon
    ssh $DEPLOYER ssh controller2 -f nmon -fT -s $NMON_WINDOW -c $NMON_RUNTIME -F run$i.nmon
    #echo "nmon has been started. Delaying $WAIT_TIME seconds before rally tests"
    sleep 10
    runrally $i $1
    echo "Waiting $WAIT_TIME (s) before next test run..."
    sleep $WAIT_TIME
    echo "Killing nmon1 and nmon2"
    killnmon controller1
    killnmon controller2
    copynmon $1 controller1 $i
    copynmon $1 controller2 $i
done  

echo "Process complete"
