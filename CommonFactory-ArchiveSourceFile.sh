#!/bin/sh
# CommonFactory-ArchiveSourceFile.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/06/26 
#
# Check if supplied/path/filename.extension exist, and if so, move it to supplied/path/archive/filename.extension.bkp
#
# usage: sh ./CommonFactory-ArchiveSourceFile.sh "full/path/to/folder/location/filename.extension"
# e.g. :
# sh ./CommonFactory-ArchiveSourceFile.sh "/interfaces/salesforce/inbound/sq_SF_ProductFullSet20180514-200812-887.csv"
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
		echo 'Aborting CommonFactory-ArchiveSourceFile.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: fullFileNameWithPath'
		printFirstTableLine "fullFileNameWithPath" "Full file name along with the complete path"
		printSecondTableLine 'e.g. : "/opt/IBM/data/etl/bwadhoc/salesforce/inbound/sq_SF_ProductFullSet20180514-200812-887.csv"'
		centerPrint "returns following status codes"
		printFirstTableLine "returns 1" "Invalid number of arguements passed"
		printFirstTableLine "returns 2" "The 'fullFilePath' supplied at param #1 doesnt exist"
		printFirstTableLine "returns 3" "if filename after path doesnt exist"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "SAMPLE COMMAND TEXT BELOW : "
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-ArchiveSourceFile.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound/sq_SF_ProductFullSet20180514-200812-887.csv"'
		echo 'bad arguement e.g.: sh /opt/IBM/data/utils/CommonFactory-ArchiveSourceFile.sh "/some/path/that/doesnt/exist/filename.txt"'
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
	echo Invalid path to file: $varFullPath
	exit 2 
fi

# step 02 - check if file at the folder supplied exists ?
# exit return code 3 if it doesn't
if [ ! -f "$varFullFileWithPath" ]; then
	centerPrint "Invalid file or not accessible: $varFullFileWithPath"
	exit 3 
fi

# step 03 - check if the archive folder exist at the path?
# if not, create one
if [ ! -d "$varFullPath/archive" ]; then
	centerPrint "creating archive directory under $varFullPath as it doesn't exists"
	mkdir -m a=rwx $varFullPath/archive
fi

mv -f ${varFullPath}/${varFileNameWithExtension} ${varFullPath}/archive/${varFileNameWithExtension}.bkp
echo " *** *************************************** *** "
echo " *** tar and compress the source file backup *** "
cd ${varFullPath}/archive
find . -name "${varFileNameWithExtension}.bkp" | tar -czf ${varFileNameWithExtension}.bkp.tar.gz --files-from -

centerPrint "The file ${varFullFileWithPath} is successfully compressed to ${varFullPath}/archive/${varFileNameWithExtension}.bkp.tar.gz"
exit 0

IFS=$SAVEIFS
