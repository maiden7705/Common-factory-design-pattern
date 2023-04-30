#!/bin/sh
# CommonFactory-CheckPointJobs.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/05/28 
#
# Utility that checks if passed job is found in the checkPoint run file
#
# usage: sh ./CommonFactory-CheckPointJobs.sh <subjectArea> <JobNameMask> <Action:Check,Insert,Delete> <ExactJobName>
# e.g. :
# sh /opt/IBM/data/utils/CommonFactory-CheckPointJobs.sh "/opt/IBM/data/etl/bwadhoc/salesforce/processing" "SF_InventoryRecon_20180609-180508" "STARTED" "INSERT"
# sh /opt/IBM/data/utils/CommonFactory-CheckPointJobs.sh "/opt/IBM/data/etl/bwadhoc/salesforce/processing" "SF_InventoryRecon_20180609-180508" "stg_SF_InventoryRecon_202_AccountLookup" "INSERT"
# sh /opt/IBM/data/utils/CommonFactory-CheckPointJobs.sh "/opt/IBM/data/etl/bwadhoc/salesforce/processing" "SF_InventoryRecon_20180609-180508" "stg_SF_InventoryRecon_202_AccountLookup" "CHECK"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255

# check if proper number of arguements were passed
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
	if [ ${#varArgCount[@]} -lt 4 ]; then
		echo 'Aborting CommonFactory-CheckPointJobs.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: projectProcessingFolder CheckpointFilename ExactJobName Action[CHECK|INSERT|DELETE]'
		printFirstTableLine "projectProcessingFolder" "The processing folder location for this project"
		printSecondTableLine "for e.g. : '/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		printFirstTableLine "CheckpointFilename" "name of the checkpoint file to perform 'Action' in"
		printFirstTableLine "ExactJobName" "The Exact Name of the job"
		printFirstTableLine "Action" "The Action to perform when found in the file"
		printSecondTableLine "One of the following three : "
		printFirstTableLine "Action -> CHECK" "returns RAN or PENDING depending on"
		printSecondTableLine "whether 'ExactJobName' match is found in the checkpoint file for this run"
		printFirstTableLine "Action -> INSERT" "Inserts the supplied 'ExactJobName' at the end of the file"
		printFirstTableLine "Action -> DELETE" "Deletes this checkpoint file when done"
		centerPrint "returns following exit codes:"
		printFirstTableLine "return 1" "Incorrect number of arguements supplied"
		printFirstTableLine "return 2" "Processing directory supplied is either invalid or not accessible / writable"
		printFirstTableLine "return 3" "If supplied 'CheckpointFilename' is invalid or not found"
		printFirstTableLine "return 4" "Action supplied is not one of the three allowed:"
		printSecondTableLine "CHECK|INSERT|DELETE"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "example below"
		echo 'sh /opt/IBM/data/utils/CommonFactory-CheckPointJobs.sh "/opt/IBM/data/etl/bwadhoc/salesforce/processing" "SF_InventoryRecon_20180609-180508" "stg_SF_InventoryRecon_202_AccountLookup" "INSERT"'
		echo 'OR'
		echo 'sh /opt/IBM/data/utils/CommonFactory-CheckPointJobs.sh "/opt/IBM/data/etl/bwadhoc/salesforce/processing" "SF_InventoryRecon_20180609-180508" "STARTED" "INSERT"'
	   exit 1
	fi
}

printScriptHelpTxt $@

varCheckPointFileExtension='.chk'
varProcessingFolder=$1
varCheckPointFileName=$2
varExactJobName=$3
varAction=$4
varCheckPointFullFileName=''
file=${varProcessingFolder}/${varCheckPointFileName}
if [[ ${file: -4} == ".chk" ]]; then
		varCheckPointFullFileName=${varProcessingFolder}/${varCheckPointFileName}
	else
		varCheckPointFullFileName=${varProcessingFolder}/${varCheckPointFileName}${varCheckPointFileExtension}
fi


if ! [ -d $varProcessingFolder ] || ! [ -w $varProcessingFolder ]; then
   echo Error in CommonFactory-CheckPointJobs.sh!  Directory not valid or not writeable: $varProcessingFolder
    exit 2
fi
varActionLowerCase=`echoWithoutLineBreak "$varAction" | tr '[:upper:]' '[:lower:]'`
#echo $varActionLowerCase
if [[ ! -f ${varCheckPointFullFileName} ]]; then
	if [[ $varActionLowerCase == 'check' ]] || [[ $varActionLowerCase == 'delete' ]]; then
		echo Error in CommonFactory-CheckPointJobs.sh!  Checkpoint file invalid or not found at: $varProcessingFolder/$varCheckPointFileName$varCheckPointFileExtension
		 exit 3
	fi
fi


if [[ $varActionLowerCase == "insert" ]]; then
	if [[ ! -f ${varCheckPointFullFileName} ]]; then
		echo $varExactJobName >> ${varCheckPointFullFileName}; exit 0
	fi
	
	if grep -q $varExactJobName ${varCheckPointFullFileName}; then
		echoWithoutLineBreak "RAN"; exit 0;
		else
		echo $varExactJobName >> ${varCheckPointFullFileName}; exit 0
	fi
	

fi

if [[ $varActionLowerCase == "delete" ]]; then
	echo "" > ${varCheckPointFullFileName}; exit 0
	#rm -f ${varCheckPointFullFileName}; exit 0;
fi

if [[ $varActionLowerCase == "check" ]]; then
	# grep on file to check if this job or clause was already entered before
	# this will conclude that the job was already run
	if grep -Fxq "${varExactJobName}" "${varCheckPointFullFileName}"; then echoWithoutLineBreak "RAN"; else echoWithoutLineBreak "PENDING"; fi
	exit 0
fi

exit 4


