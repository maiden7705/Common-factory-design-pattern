#!/bin/sh
# CommonFactory-DeleteRunFilesSilent.sh
# Author:  Adil Baig
# Create Date: 06/28/2018 
#Note: This script simply deletes all the run files in processing and reject folder

# execution example:
# sh /opt/IBM/data/utils/CommonFactory-DeleteRunFilesSilent.sh "SF" "SF" "AccountTeamProductLine" 6 "/opt/IBM/data/etl/bwadhoc/salesforce/processing" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/archive"
# sh #ps_BWAdHoc.$env_BWADHOC_UTILS#CommonFactory-DeleteRunFilesSilent.sh "#ps_BWAdHoc.$env_BWADHOC_PROCESSING#" "#ps_BWAdHoc.$env_BWADHOC_REJECTS#"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255

# Save the original IFS of the terminal
SAVEIFS=$IFS

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
	if [ ${#varArgCount[@]} -lt 2 ]; then
		echo 'Aborting CommonFactory-DeleteRunFilesSilent.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: ProcessingFolderPath RejectFolderPath'
		printFirstTableLine "ProcessingFolderPath" "Location where 'sq_[JobNameMask]*.csv' processing files and"
		printSecondTableLine "'sq_[JobNameMask]*Debug.csv' debug files resides"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		printSecondTableLine "This can be supplied through your #ps_BWAdHoc.$env_BWADHOC_PROCESSING# parameter"
		printFirstTableLine "RejectFolderPath" "Location where 'sq_[JobNameMask]*.rej' reject files resides"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printSecondTableLine "This can be supplied through your #ps_BWAdHoc.$env_BWADHOC_REJECTS# parameter"
		centerPrint "returns following status codes"
		printFirstTableLine "returns 0" "This is a silent run and DO NOT generate error code"
		printSecondTableLine "as this is the last error path itself and there is no further error path to collect"
		centerPrint "SAMPLE COMMAND TEXT BELOW : "
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-DeleteRunFilesSilent.sh "/opt/IBM/data/etl/bwadhoc/salesforce/processing/" "/opt/IBM/data/etl/bwadhoc/salesforce/reject"'
		exit 1
	fi
}

printScriptHelpTxt $@

ProcessingFolder=$1
RejectFolder=$2
# Step-00 - pre-check : Check if any of the folders supplied
# are invalid or not accesible to this script.
if [ ! -d "$ProcessingFolder" ]; then
	IFS=$SAVEIFS
	exit 0
fi

if [ ! -d "$RejectFolder" ]; then
	IFS=$SAVEIFS
	exit 0
fi

DeleteProcessingFiles
DeleteRejectFiles

#restore the original IFS back
IFS=$SAVEIFS