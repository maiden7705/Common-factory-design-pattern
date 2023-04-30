#!/bin/sh
# CommonFactory-sftp.sh
# Author:  Adil Baig
# Create Date: 2018/06/03
#
# Utility that login into the supplied SFTP server through passed Login info
# and paste it into supplied Local server path
#
# e.g. sh /opt/IBM/data/utils/CommonFactory-sftp.sh
#sh #ps_BWAdHoc.$env_BWADHOC_UTILS#CommonFactory-sftp.sh #ps_FTPLogin.HostName# #ps_FTPLogin.UserId# #ps_BWAdHoc.$env_BWADHOC_INBOUND# #ps_FTPDirectory.RemotePath# out/#ps_FTPDirectory.FileMask# "#ps_FTPDirectory.Command# -P"

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
	CMD=$(requote "${@}")
	varArgCount=( $CMD )
	echo $CMD
	echo $varArgCount
	
	# check if proper number of arguements were passed
	if [ ${#varArgCount[@]} -lt 6 ]; then
		echo 'Aborting CommonFactory-sftp.sh - invalid number of arguments'
		echo 'Arguments are: Hostname UserID LocalPathname RemotePathname Filename FTPCommand'
		printFirstTableLine "Hostname" "Name of the SFTP server to fetch from /put data to"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPLogin.Hostname#"
		printFirstTableLine "UserID" "User ID to login into Host with"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPLogin.UserID#"
		printFirstTableLine "LocalPathname" "Local path to put the file at, when fetched"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPDirectory.InterfaceIn#"
		printFirstTableLine "RemotePathname" "Remote path on SFTP server to fetch from"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPDirectory.RemotePath#"
		printFirstTableLine "Filename" "Filename mask to fetch"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPDirectory.FileMask#"
		printSecondTableLine "e.g. 'product*.txt' or 'inventory*.txt'"
		printFirstTableLine "FTPCommand" "FTP command to perform when file is found"
		printSecondTableLine "Can be passed through parameterset: #ps_FTPDirectory.Command#"
		printSecondTableLine "e.g. 'mget -P' OR 'mput'"
		centerPrint "returns following exit codes:"
		printFirstTableLine "return 1" "Incorrect number of arguements supplied"
		printFirstTableLine "return 2" "Invalid location directory or not writable"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint 'EXAMPLE BELOW'
		echo 'sh /opt/IBM/data/utils/CommonFactory-sftp.sh #ps_FTPLogin.HostName# #ps_FTPLogin.UserId# #ps_BWAdHoc.$env_BWADHOC_INBOUND# #ps_FTPDirectory.RemotePath# out/#ps_FTPDirectory.FileMask# "#ps_FTPDirectory.Command# -P"'
		 exit 1
	fi
}

printScriptHelpTxt $@
HOST=$1
USERID=$2
LOCALPATH=$3
REMOTEPATH=$4
FILENAME=$5
FTPCOMMAND=$6
defaultPort=9500

if ! [ -d $LOCALPATH ] || ! [ -w $LOCALPATH ]; then
   echo Error in CommonFactory-sftp.sh!  Directory not valid or not writeable: $LOCALPATH
    exit 2
fi
#
echo HOMEDIR=$HOME
echo FILENAME=$FILENAME
echo /usr/bin/sftp -oPort=${defaultPort} -oIdentityFile=$HOME/.ssh/id_dsa $USERID@$HOST  \<\< EOF
#
/usr/bin/sftp -oPort=${defaultPort} -oIdentityFile=$HOME/.ssh/id_dsa $USERID@$HOST << EOF
lcd $LOCALPATH
cd $REMOTEPATH
$FTPCOMMAND $FILENAME*
bye
EOF
wait
