#!/bin/bash
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=/root/development
source /usr/local/bin/virtualenvwrapper.sh
workon rally
echo "Passed in value---- REPLACE_VAL" REPLACE_VAL
rally task start /root/rally-install/rally/samples/tasks/scenarios/vm/boot-ping-ssh-vm-share-network.yaml
#Gets the last rally task id
rally task report $(rally task list | cut -d' ' -f2| tail -2 | head -n 1) --out /root/rally-install/outputREPLACE_VAL.html