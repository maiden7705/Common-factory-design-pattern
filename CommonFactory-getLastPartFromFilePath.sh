#!/bin/sh
# CommonFactory-getLastPartFromFilePath.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/05/01
#
# simple util to return last part of filePath
#
# usage: sh /opt/IBM/data/utils/CommonFactory-getLastPartFromFilePath.sh "/path/to/filename", returns filename
# e.g. :
# sh #ps_BWAdHoc.$env_BWADHOC_UTILS#/CommonFactory-getLastPartFromFilePath.sh /opt/IBM/InformationServer/Server/Projects/Dev_BWAdHoc
#, returns 'Dev_BWAdHoc'

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
	
	# check if proper number of arguements were passed
	if [ ${#varArgCount[@]} -lt 1 ]; then
		echo 'CommonFactory-getLastPartFromFilePath.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: fullPath'
		printFirstTableLine "where fullPath" "fullPath to the file: e.g. full/path/to/filename"
		printFirstTableLine "outputs" "'filename' part"
		echo "returns following exit codes:"
		printFirstTableLine "returns 1" "If required 'fullPath' arguement is not supplied"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "SAMPLE COMMAND BELOW:"
		echo 'e.g.: sh /opt/IBM/data/utils/getLastPartFromFilePath.sh "full/path/to/FolderOrFileName"'
		echo 'returns: FolderOrFileName'
		 exit 1
	fi
}

printScriptHelpTxt $@

varFullPath="$(basename $1)"
echoWithoutLineBreak "${varFullPath}"