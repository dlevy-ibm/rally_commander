#!/bin/bash
WAIT_TIME=10
DEPLOYER="root@169.53.176.174"

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument required, $# provided"

killnmon() {
   ssh $DEPLOYER ssh $1 "'
   pgrep -f nmon | xargs kill -9
   '"
}

copynmon(){
	ssh $DEPLOYER ssh $2 "'
       ls -t | grep .*nmon | head -n1 | xargs -r cat
    '" >> $1/$2.nmon
}

echo "Running nmon on controller1 and controller2"
ssh $DEPLOYER ssh controller1 nmon -fT -s 30 -c 300
ssh $DEPLOYER ssh controller2 -f nmon -fT -s 30 -c 300
echo "nmon has been started. Delaying $WAIT_TIME seconds before rally tests"
sleep $WAIT_TIME
echo "Running rally tests"
cat rallyrun.sh | ssh $DEPLOYER
sleep $WAIT_TIME
echo "Killing nmon1 and nmon2"
killnmon controller1
killnmon controller2
echo "Copying over result data to: $1"
mkdir $1
scp $DEPLOYER:/root/rally-install/output.html $1
copynmon $1 controller1
copynmon $1 controller2
echo "Process complete"