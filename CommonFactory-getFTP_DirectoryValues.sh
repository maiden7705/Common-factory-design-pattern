#!/bin/sh
# CommonFactory-getFTP_DirectoryValues.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/05/25
#
# Traverse the project's parameter set folder for 'ps_FTPDirectory' values for your 'subjectarea' and 'objectname'
# returns the list of value filenames for your project in comma seperated list
#
# usage: sh ./CommonFactory-getFTP_DirectoryValues.sh <projectpath> <subjectarea>
# e.g. :
# sh /opt/IBM/data/utils/CommonFactory-getFTP_DirectoryValues.sh "/opt/IBM/InformationServer/Server/Projects/Dev_BWAdHoc/" "SF"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255

varPARAMETERSETFIXEDFOLDER="/ParameterSets/ps_FTPDirectory"
varJOBNAME='seq_SF_Common_002_GetFromSFTP'

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
	if [ ${#varArgCount[@]} -lt 2 ]; then
		echo 'Aborting CommonFactory-getFTP_DirectoryValues.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: ProjectPath SubjectArea'
		printFirstTableLine "ProjectPath" "Valid full path to project"
		printSecondTableLine "This can be passed through datastage sequencer through the system variable : @PATH"
		printFirstTableLine "SubjectArea" "Subject Area you want to search parameterset value filenames for."
		printSecondTableLine "for e.g.: passing 'GlbSales' would yield GlbSales_Cust, GlbSales_Sales"
		printSecondTableLine "refer to standards document, section 2-2-6-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		printFirstTableLine "returns" "comma seperated list of values matching 'SUBJECTAREA_*'"
		echo "returns follow exit codes:"
		printFirstTableLine "returns 1" "if incorrect number of arguements were supplied"
		printFirstTableLine "returns 2" "if NO parameter called 'ps_FTPDirectory' was found"
		printSecondTableLine "This is in the rare case that parameter is deleted or renamed"
		printFirstTableLine "returns 3" "If in case value file is empty for parameterset: 'ps_FTPDirectory'"
		printFirstTableLine "returns 4" "If no value files matching the predicate 'SUBJECTAREA_*' was found."
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "EXAMPLE BELOW"
		echo 'sh /opt/IBM/data/utils/CommonFactory-getFTP_DirectoryValues.sh "/opt/IBM/InformationServer/Server/Projects/Dev_BWAdHoc/" "GlbSales"'
		echo 'returns a comma seperated list of parameterset values e.g.: GlbSales_Cust, GlbSales_Sales'
		 exit 1
	fi
}

printScriptHelpTxt $@

varPROJPATH=$1
varSUBJECTAREA=$2

# step 01 - create a parameterset folder full path
varPARAMETERSETPATH=${varPROJPATH}/${varPARAMETERSETFIXEDFOLDER}
# varPARAMETERSETPATH="/opt/IBM/InformationServer/Server/Projects/Dev_BWAdHoc//ParameterSets/ps_FTPDirectory"
# step 02 - check if such a folder exist,
# if not, then we dont want to continue further
if [ ! -d "${varPARAMETERSETPATH}" ]; then
   exit 2
fi

# step 04 - get total count of value files in this folder
varVALUESCOUNT=`ls $varPARAMETERSETPATH | wc -l | tr -d '\n'`
varVALUESET=''
counter=1
# step 05 - now perform a list command inside this parameterset folder and save the result in a file
#			redirect stderr out to dev/null too
if ls $varPARAMETERSETPATH 1> /dev/null 2>&1; then
	ls $varPARAMETERSETPATH &> ${varJOBNAME}_${DATE_WITH_TIME}.txt
	SAVEIFS=$IFS
	while IFS='' read -r eachValue || [[ -n "$eachValue" ]]; do
		# echo "The value is : $eachValue"
		if [[ ${eachValue} == "${varSUBJECTAREA}_"* ]]; then
			[[ -z ${varVALUESET} ]] && varVALUESET="$eachValue" || varVALUESET="$varVALUESET,$eachValue"
		fi
		
		if [ "$counter" -eq "$varVALUESCOUNT" ]; then
			# [[ -z ${varVALUESET} ]] && echo 'NOTFOUND' | tr -d '\n'; exit 1; || echo $varVALUESET | tr -d '\n'; exit 0;
			if [[ -z ${varVALUESET} ]]; then
				rm -f ${varJOBNAME}_${DATE_WITH_TIME}.txt
				 exit 4
			else
				echoWithoutLineBreak $varVALUESET; 
				rm -f ${varJOBNAME}_${DATE_WITH_TIME}.txt
				 exit 0
			fi
		fi
		counter=$((counter + 1))
	done < ${varJOBNAME}_${DATE_WITH_TIME}.txt
	rm -f ${varJOBNAME}_${DATE_WITH_TIME}.txt
	IFS=$SAVEIFS
else
     exit 3
fi
