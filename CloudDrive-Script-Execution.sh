#CloudDrive is located in the home directory, so change into that.
cd ~

#A directory listing shows the clouddrive directory, let's change into that directory
ls
cd clouddrive

#create a demo script in our clouddrive and save it out.
vi demo.sh
#!/bin/bash
az vm list --output table

#Mark the script usermode executable
chmod u+x demo.sh

#Run the script
./demo.sh