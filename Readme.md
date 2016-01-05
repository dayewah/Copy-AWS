#Readme
Copy-AWS is a set of powershell scripts to assist in copying files to and from an aws server using the Putty tool pscp.exe

##Example 
```powershell
C:\> Copy-AWS -Source .\file1.txt -Destination /home/ec2-user/folder
```
##ToDo
- Update aws info file to change keypath to keyfile
- Test latest changes