#!/bin/bash
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=/root/development
source /usr/local/bin/virtualenvwrapper.sh
workon rally
rally task start /root/rally-install/rally/samples/tasks/scenarios/vm/boot-ping-ssh-vm-share-network.yaml
rally task report $(rally task list | cut -d' ' -f2| tail -2 | head -n 1) --out /root/rally-install/output.html