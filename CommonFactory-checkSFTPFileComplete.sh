#!/bin/sh
# CommonFactory-checkSFTPFileComplete.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/04/20
#
# This is a regular expression based pattern matching utility
# that matches most of the SAP SFTP file pattern of style "interfacename-YYMMDD-HHMMSS-MSS.txt"
# It extracts the date and timestamp part for Appending it to files further in job chain.
#
# usage: sh ./CommonFactory-checkSFTPFileComplete.sh <inboundFolderLocation> <exactFilename> <SubjectArea> <[OPTIONAL]outboundFileLocation>
# e.g. :
# sh ./CommonFactory-checkSFTPFileComplete.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound" "product20180509-181902-654.txt" "SF"
# or you can provide the outbound path if different from default, for example:
# sh ./CommonFactory-checkSFTPFileComplete.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound" "product20180509-181902-654.txt" "SF" "/interfaces/salesforce/"
# sh #ps_BWAdHoc.$env_BWADHOC_UTILS#CommonFactory-checkSFTPFileComplete.sh #ps_BWAdHoc.$env_BWADHOC_INBOUND# #slp_checkEachFile.$Counter# #jp_SUBJECTAREA# #$env_SALESFORCE_INTERFACEDROPPATH#

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
	if [ ${#varArgCount[@]} -lt 4 ]; then
		echo 'Aborting CommonFactory-checkSFTPFileComplete.sh - invalid number of arguments '
		echo 'Arguments should be, in this order: InboundFolderLocation ExactFilename SubjectArea OutboundPath'
		printFirstTableLine "InboundFolderLocation" "Location to pickup the file from"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/inbound'"
		printFirstTableLine "ExactFilename" "Exact name of the file without any wildcard inclusion"
		printSecondTableLine "e.g. 'product20180417-221813-112.txt'"
		printFirstTableLine "SubjectArea" "The subject area for this project, to be used in creating the outbound file"
		printSecondTableLine "e.g. if you pass 'SF' at param #3, it will used in creating file name as follows:"
		printSecondTableLine "sq_SF_ExactFilename[WithoutDatetimestamp][FullSet|Delta]_%datetimestring%.csv"
		printSecondTableLine "e.g.: sq_SF_ProductFullSet_100_Extract_20180509-181902-654.csv"
		printFirstTableLine "OutboundPath" "Path to where to drop the output file at"
		printSecondTableLine "e.g. '/interfaces/salesforce/inbound'"
		centerPrint "returns following status messages at command output"
		printFirstTableLine "PASS|ExactFilename|END" "The File passed SAP Complete file validation"
		printSecondTableLine "And DID CONTAIN both B_O_F at the beginning of the file"
		printSecondTableLine "and E_O_F at the end of the file"
		printFirstTableLine "FAIL|ExactFilename|END" "The File FAILED SAP Complete file validation"
		printSecondTableLine "And DID NOT CONTAIN E_O_F at the end of the file"
		centerPrint "returns following error codes"
		printFirstTableLine "returns 1" "Invalid number of arguements passed"
		printFirstTableLine "returns 2" "the supplied 'ExactFilename do not exist at the 'InboundFolderLocation'"
		printFirstTableLine "returns 3" "The Inbound path supplied at param #1 doesnt exist on server"
		printFirstTableLine "returns 4" "The Outbound path supplied at param #4 doesnt exist on server"
		printSecondTableLine "make sure you have supplied a valid 'filenameWildcardMask' at second parameter"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		echo "a sample command below:"
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-checkSFTPFileComplete.sh "/opt/IBM/data/etl/bwadhoc/salesforce/inbound" "product20180417-221813-112.txt" "SF" "/interfaces/salesforce/inbound"'
		 exit 1
	fi
}

printScriptHelpTxt $@

varFilePath=$1
varFileName=$2
varSubjectArea=$3
varOutboundPath=$4

if [ ! -d "$varFilePath" ]; then
	 exit 3 
fi

if [ ! -d "$varOutboundPath" ]; then
	 exit 4 
fi


# if file not found, we do not want to proceed any further checks
if [ ! -f $varFilePath/$varFileName ]; then
     exit 2
fi

# check if outbound path was supplied, else default to /interfaces/salesforce/inbound
if [ -z "$4" ]; then
	varOutboundPath=$varSALESFORCEINTERFACEPATH 
fi


varFilenamePrefix=$(echo ${varFileName} | cut -f 1 -d '.' | tr -d '-')
varInterfaceName=$(printf '%s\n' "${varFilenamePrefix//[[:digit:]]/}")
varInterfaceNameTitleCased=`echo ${varInterfaceName} | sed 's/.*/\L&/; s/[a-z]*/\u&/g'`
varDigitPart=`patternMatchSAPFileFormat $varFileName`

# get first and last line of the file for format check
varFirstLine=`head -1 $varFilePath/$varFileName | tr -d '\n'`
varLastLine=`tail -1 $varFilePath/$varFileName | tr -d '\n'`
# echo "Interface name is  : $varInterfaceName"
# echo "file's last line is: $varLastLine"

# try to get first and third column split by pipe,
# if this is indeed a complete file, it MUST HAVE an E_O_F line
varBOF="$(echo $varFirstLine | cut -d'|' -f1)"
varEOF="$(echo $varLastLine | cut -d'|' -f1)"
varLoadType="$(echo $varLastLine | cut -d'|' -f3)"

if [[ ${varBOF} == "B_O_F" ]] && [[ ${varEOF} == "E_O_F" ]]
then
	totalLinesInFile=`wc -l $varFilePath/${varFileName} | cut -f1 -d' '`
	head -$((totalLinesInFile - 1)) ${varFilePath}/${varFileName} > tempFile.txt
	tail -$((totalLinesInFile - 2)) tempFile.txt > tempFile2.txt
	varFileLineCount=`wc -l tempFile2.txt | tr -d '\n' | cut -f1 -d' '`
	if [ "${varFileLineCount}" -eq "0" ]; then
		rm -f tempFile2.txt
		echoWithoutLineBreak "NODATA|$varFileName|END"
		exit
	fi
	rm -f tempFile2.txt
	tail -$((totalLinesInFile - 2)) tempFile.txt > "${varOutboundPath}/sq_${varSubjectArea}_${varInterfaceNameTitleCased}${varLoadType}${varDigitPart}.csv"
	rm -f tempFile.txt
	# rm -f ${varFilePath}${varFileName}
	echoWithoutLineBreak "PASS|$varFileName|END"
else
	echoWithoutLineBreak "FAIL|$varFileName|END"
fi

