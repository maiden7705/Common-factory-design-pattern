#!/bin/sh
# CommonFactory-dummyTrigger.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/10/02
#
# based on the action provided, either CREATE a dummy trigger OR DELETE a dummy trigger for given chain
#
# usage: sh ./CommonFactory-listAllFiles.sh <inboundFolderLocation> <fileMask>
# e.g. :
# sh ./CommonFactory-listAllFiles.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound" "product*.txt"
# sh ./CommonFactory-listAllFiles.sh "/interfaces/salesforce/inbound" "sq_SF_InventoryFullSet*.csv"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255

varSALESFORCEINTERFACEPATH="/interfaces/salesforce/inbound"

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
		echo 'Aborting CommonFactory-dummyTrigger.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: triggerNameToCreate folderLocation'
		printFirstTableLine "triggerNameToCreate" "Name of the trigger to create"
		printSecondTableLine 'this will mostly be a chain or job name'
		printSecondTableLine 'e.g. : "CPS_SF_ProdAccount"'
		printFirstTableLine "folderLocation" "folder where to place the trigger at"
		printSecondTableLine 'e.g. : "/opt/IBM/data/etl/bwadhoc/salesforce/processing/"'
		centerPrint "returns following status codes"
		printFirstTableLine "returns 1" "Invalid number of arguements passed"
		printFirstTableLine "returns 2" "Invalid folder location at second parameter"
		centerPrint "SAMPLE COMMAND TEXT BELOW : "
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-dummyTrigger.sh "CPS_SF_ProdAccount" "/opt/IBM/data/etl/bwadhoc/salesforce/processing/"'
		echo 'creates a trigger file at '
		exit 1
	fi
}

#echo "number of arguements passed: $#

printScriptHelpTxt $@

triggerNameToCreate=$1
folderLocation=$2


if [ ! -d "$folderLocation" ]; then
	exit 2
fi

# step-01 - first delete the oldest trigger file of this name
if ls ${folderLocation}/${triggerNameToCreate}*.trg 1> /dev/null 2>&1; then
	rm "$(ls -t ${folderLocation}/${triggerNameToCreate}*.trg | tail -1)"
fi

# step-02-cd into the drive and create the new trigger
cd $folderLocation;
echo "DONE" > ${triggerNameToCreate}_${DATE_WITH_TIME}.trg


IFS=$SAVEIFS
