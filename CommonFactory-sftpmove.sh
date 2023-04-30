#!/bin/sh
# CommonFactory-sftpmove.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/04/24
#
# This FTP script uses the "rename" command to "move" a file from one name to another
# name on the FTP server without having to transfer the data
#
# By including a Path in the "FILENAMETO" you can also move the file to another directory
# on the FTP server.
#
# usage:  ./CommonFactory-sftpmove.sh <host> <userid> <remotepath> <filenamefrom> <filenameto>
# e.g. : sh /opt/IBM/data/utils/CommonFactory-sftpmove.sh "sapdevsftp" "dwadmin" "/SAP/SALESFORCE/PRODUCT/" "out/product20180514-200812-887.txt" "archive/product20180514-200812-887.txt.etl.bkp"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255

printScriptHelpTxt()
{
	# When arguements are recieved by function through $@
	# they are stripped off the quotes
	# so we need to re-quote them in order for the 'if' check below to not fail
	# on finding more number of arguements than was actually passed
	# e.g. if "some var" "some var2" are stripped of their quotes
	# then they evaualte as 4 arguements passsed, instead of 2
	# echo "before reqoute function in printScriptHelpTxt()"
	CMD=$(requote "${@}")
	varArgCount=( $CMD )
	#echo $CMD
	#echo $varArgCount
	
	# check if proper number of arguements were passed
	if [ ${#varArgCount[@]} -lt 5 ]; then
	#if [ $# -lt 5 ]; then
	echo 'Aborting CommonFactory-sftpmove.sh - invalid number of arguments'
		echo 'Arguments are: Hostname UserID RemotePathname FilenameFrom FilenameTo'
		printFirstTableLine "Hostname" "Name of the SFTP server to fetch from /put data to"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPLogin.Hostname#"
		printFirstTableLine "UserID" "User ID to login into Host with"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPLogin.UserID#"
		printFirstTableLine "RemotePathname" "Remote path on SFTP server to fetch from"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPDirectory.RemotePath#"
		printFirstTableLine "FilenameFrom" "The current location of SFTP file on server's RemotePathname"
		printFirstTableLine "FilenameTo" "The destination location of SFTP file on server's RemotePathname"
		centerPrint "returns following exit codes:"
		printFirstTableLine "return 1" "Incorrect number of arguements supplied"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "EXAMPLE BELOW"
		echo 'sh /opt/IBM/data/utils/CommonFactory-sftpmove.sh "#ps_FTPLogin.HostName#" "#ps_FTPLogin.UserId#" "#ps_FTPDirectory.RemotePath#" "out/#slp_checkEachFile.$Counter#" "archive/#slp_checkEachFile.$Counter#.etl.bkp"'
		 exit 1
	fi
}

# printScriptHelpTxt $@

HOST=$1
USERID=$2
REMOTEPATH=$3
FILENAMEFROM=$4
FILENAMETO=$5
echo $HOST $USERID $REMOTEPATH $FILENAMEFROM $FILENAMETO 

echo HOMEDIR=$HOME 
echo /usr/bin/sftp  \<\< EOF
#
/usr/bin/sftp -oPort=9500 -oIdentityFile=$HOME/.ssh/id_dsa $USERID@$HOST << EOF
cd $REMOTEPATH
rename $FILENAMEFROM $FILENAMETO
bye
EOF
wait

