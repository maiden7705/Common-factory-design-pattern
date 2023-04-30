#!/bin/sh
# CommonFactory-listAllFiles.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/04/24
#
# Check if "ls" commands returns any file, if yes, echo a comma seperated list of files matching that pattern.
# However if there are no files with that pattern, 
# suppres the "file cannot be find" error and instead return keyword 'NOFILES'
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
		echo 'Aborting CommonFactory-listAllFiles.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: fullFilePath filenameWildcardMask [OPTIONAL]resultFilter'
		printFirstTableLine "fullFilePath" "Full path to the location of the file"
		printSecondTableLine 'e.g. : "/opt/IBM/data/etl/bwadhoc/salesforce/inbound"'
		printFirstTableLine "filenameWildcardMask" "file name mask with wild card"
		printSecondTableLine 'e.g. : "product*.txt"'
		printFirstTableLine "[OPTIONAL]resultFilter" "flag to filter the result generated"
		printSecondTableLine 'Following Options can be passed'
		printSecondTableLine 'FIRST	: to only return the first match'
		printSecondTableLine 'LAST 	: to only return the last match'
		printFirstTableLine "returns" "comma seperated list of file names that matched to the given mask"
		printSecondTableLine 'e.g.: product20180514-200812-590,product20180509-181902-654,product20180419-200751-760'
		centerPrint "returns following status codes"
		printFirstTableLine "returns 1" "Invalid number of arguements passed"
		printFirstTableLine "returns 3" "The 'fullFilePath' supplied at param #1 doesnt exist on server"
		printSecondTableLine "make sure you have supplied a valid 'filenameWildcardMask' at second parameter"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "SAMPLE COMMAND TEXT BELOW : "
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-listAllFiles.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound" "product*.txt"'
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-listAllFiles.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound" "product*.txt" "FIRST"'
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-listAllFiles.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound" "product*.txt" "LAST"'
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-listAllFiles.sh "/interfaces/salesforce/inbound" "sq_SF_ProductFullSet*csv"'
		exit 1
	fi
}

#echo "number of arguements passed: $#

printScriptHelpTxt $@

varFilePath=$1
varFileNameMask=$2
varResultFilter=$3

if [ ! -d "$varFilePath" ]; then
	
	exit 3 
fi

# do we have any files with this name pattern existing in inbound folder
if ls $varFilePath/$varFileNameMask 1> /dev/null 2>&1; then
	#01 - cd into the path supplied; 
	#02 - list files, replace new line by comma, replace last comma with blank
	#this will return list of files matched but in a comma seperate format
	if [[ -z ${varResultFilter} ]]; then
		# no filter switch was passed, list everything
		cd $varFilePath; ls -t $varFileNameMask | tr '\n' ',' | sed 's/,$//'; exit 0
	fi
	
	if [[ ${varResultFilter} == "FIRST" ]]; then
		cd $varFilePath; ls -t $varFileNameMask | head -1 | tr -d '\n'; exit 0
	fi
	
	if [[ ${varResultFilter} == "LAST" ]]; then
		cd $varFilePath; ls -t $varFileNameMask | tail -1 | tr -d '\n'; exit 0
	fi
		
else
	# no files with the supplied mask found
	echoWithoutLineBreak "NOFILES"
	
    exit 0
fi
IFS=$SAVEIFS
