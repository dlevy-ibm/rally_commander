# rally_commander
Running rallycommander.sh locally will do the following:
- Run rally from a deployer node
- Run nmon on controller1 and controller2
- Copy the files back to your local machine

How to run:
- Install nmon analyzer tools:
  sudo apt-get install python-numpy python-matplotlib
- Install nmon analyzer
  http://matthiaslee.com/?q=node/38
- Run the tool
  ./rallycommander output/folder
