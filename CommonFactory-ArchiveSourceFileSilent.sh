#!/bin/sh
# CommonFactory-ArchiveSourceFileSilent.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/06/26
#
# Check if supplied/path/filename.extension exist, and if so, move it to supplied/path/archive/filename.extension.bkp
#
# usage: sh ./CommonFactory-ArchiveSourceFileSilent.sh "full/path/to/folder/location/filename.extension"
# e.g. :
# sh ./CommonFactory-ArchiveSourceFileSilent.sh "/interfaces/salesforce/inbound/sq_SF_ProductFullSet20180514-200812-887.csv"
# if the path and filename are correct, it will move this file to "/interfaces/salesforce/inbound/archive/sq_SF_ProductFullSet20180514-200812-887.csv.bkp"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255
SAVEIFS=$IFS
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
	if [ ${#varArgCount[@]} -lt 1 ]; then
		echo 'Aborting CommonFactory-ArchiveSourceFileSilent.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: fullFileNameWithPath'
		printFirstTableLine "fullFileNameWithPath" "Full file name along with the complete path"
		printSecondTableLine 'e.g. : "/opt/IBM/data/etl/bwadhoc/salesforce/inbound/sq_SF_ProductFullSet20180514-200812-887.csv"'
		centerPrint "returns following status codes"
		printFirstTableLine "returns 0" "Under all circunstances, this DO NOT report error code"
		printSecondTableLine "The intent of this script is to be placed in sad (error) path of the sequencer flow"
		printSecondTableLine "So there is no more collection after this to collect negative or non zero exit codes"
		centerPrint "SAMPLE COMMAND TEXT BELOW : "
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-ArchiveSourceFileSilent.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound/sq_SF_ProductFullSet20180514-200812-887.csv"'
		echo 'bad arguement e.g.: sh /opt/IBM/data/utils/CommonFactory-ArchiveSourceFileSilent.sh "/some/path/that/doesnt/exist/filename.txt"'
		echo 'if the path and filename are correct, this script will move it to "/opt/IBM/data/etl/bwadhoc/salesforce/inbound/archive/sq_SF_ProductFullSet20180514-200812-887.csv.bkp"'
		exit 1
	fi
}

printScriptHelpTxt $@

varFullFileWithPath=$1
varFullPath="${varFullFileWithPath%/*}"
varFileNameWithExtension="${varFullFileWithPath##*/}"
varFileExtension="${varFileNameWithExtension##*.}"
varFileName="${varFileNameWithExtension%.*}"

# echo the arguement supplied : ${varFullFileWithPath}
# echo the path is : ${varFullPath}
# echo the filename is : ${varFileNameWithExtension}
# echo the file extension is : ${varFileExtension}
# echo the file name part is : ${varFileName}

# step 01 - check if folder supplied even exists ?
# exit return code 2 if it doesn't
if [ ! -d "$varFullPath" ]; then
	centerPrint "Cannot archive, Invalid path to file: $varFullPath"
	exit 0 
fi

# step 02 - check if file at the folder supplied exists ?
# exit return code 3 if it doesn't
if [ ! -f "$varFullFileWithPath" ]; then
	centerPrint "Invalid file or not accessible: $varFullFileWithPath"
	exit 0 
fi

# step 03 - check if the archive folder exist at the path?
# if not, create one
if [ ! -d "$varFullPath/archive" ]; then
	centerPrint "creating archive directory under $varFullPath as it doesn't exists"
	mkdir -m a=rwx $varFullPath/archive
fi

mv -f ${varFullPath}/${varFileNameWithExtension} ${varFullPath}/archive/${varFileNameWithExtension}.bkp
centerPrint "The file ${varFullFileWithPath} is successfully moved to ${varFullPath}/archive/${varFileNameWithExtension}.bkp"
exit 0

IFS=$SAVEIFS
