#!/bin/sh
# CommonFactory-SearchJobs.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/05/01
#
# Utility that finds all the jobs matching the passed criteria and returns a comma seperated job list
#
# usage: sh ./CommonFactory-SearchJobs.sh <ProjectName> <subjectArea> <JobNameMask> <RunType: LookupExtract|Extract|Transform|Load>
# e.g. :
# sh /opt/IBM/data/utils/CommonFactory-SearchJobs.sh "Dev_BWAdHoc" "SF" "InventoryRecon" "Extract" "Parallel"
# sh /opt/IBM/data/utils/CommonFactory-SearchJobs.sh "Dev_BWAdHoc" "SF" "Lookup" "LookupExtract" "Parallel"
# sh /opt/IBM/data/utils/CommonFactory-SearchJobs.sh "Dev_BWAdHoc" "SF" "Common" "002,003" "Sequencer"
# return value example : stg_SF_Lookup_Account_110_Extract,stg_SF_Lookup_Contact_110_Extract,stg_SF_Lookup_OBJECT_110_Extract,stg_SF_Lookup_RecordType_110_Extract,stg_SF_Lookup_WhiteList_110_Extract

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
	if [ ${#varArgCount[@]} -lt 5 ]; then
		echo 'Aborting CommonFactory-SearchJobs.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: ProjectName subjectArea JobName RunType JobType'
		printFirstTableLine "where ProjectName" "Name of the project this job is running in, e.g. Dev_BWAdHoc"
		printFirstTableLine "where subjectArea" "Subject Area for these job group,"
		printSecondTableLine "e.g. all jobs with subject area 'SF'"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		printFirstTableLine "where JobName" "The JobName mask, that is mostly based on Target Table or Object Name"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		printFirstTableLine "where RunType" "Either one of the following run type text:"
		printSecondTableLine "LookupExtract|Extract|Transform|Load"
		printSecondTableLine "OR"
		printSecondTableLine "Exact comma seperate step codes to run. e.g. : 102,103,105"
		printSecondTableLine "This will fetch the job names to run, with step code exactly as:"
		printSecondTableLine "102 > followed by 103 > followed by 105"
		printFirstTableLine "where JobType" "Either one of the following run type text ONLY:"
		printSecondTableLine "Sequencer|Parallel"
		echo "returns following exit codes:"
		printFirstTableLine "return 1" "Incorrect number of arguements supplied"
		printFirstTableLine "return 2" "Invalid 'RunType' was passed at param #4"
		printFirstTableLine "return 3" "Invalid 'JobType' was passed at param #5"
		printFirstTableLine "return 4" "No Job with supplied parameters was found"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint 'EXAMPLE BELOW'
		echo 'sh /opt/IBM/data/utils/CommonFactory-SearchJobs.sh "Dev_BWAdHoc" "SF" "InventoryRecon" "Extract" "Parallel"'
		echo 'OR'
		echo 'sh /opt/IBM/data/utils/CommonFactory-SearchJobs.sh "Dev_BWAdHoc" "SF" "Lookup" "LookupExtract" "Parallel"'
	    exit 1
	fi
}

printScriptHelpTxt $@

varProjectName=$1
varSubjectArea=$2
varJobNameMask=$3
varRunType=$4

if patternMatchCSVList "${varRunType}" "DIGITMATCH" ;then
	if [ "${varRunType}" != "LookupExtract" ];then
		varRunCategory='SPECIFIC_STEPCODE_RUN';
	fi
	else varRunCategory='GENERIC_STEPCODE_RUN'; 
fi

varRunCode=`getRunTypeCode $varRunType`
varJobType=$5
varJobTypeAbbvr=`getJobType $varJobType`

if [[ $varRunCode == "INVALID" ]] && [[ $varRunCategory == "GENERIC_STEPCODE_RUN" ]]; then
	centerPrint "COMMAND HELP TEXT : "
	printScriptHelpTxt
	 exit 2
fi

if [[ $varJobTypeAbbvr == "INVALID" ]]; then
	echo "Please pass a valid Job Type value, refer the command help text:"
	centerPrint "COMMAND HELP TEXT : "
	printScriptHelpTxt
	 exit 3
fi

# echo "*** The run type code is : $varRunCode"
varJobNameList=''

$DSHOME/bin/dsjob -ljobs $varProjectName > ${varJobNameMask}_${varRunType}_${DATE_WITH_TIME}.txt 2> /dev/null
#echo "compiled string to match : ${varJobTypeAbbvr}_${varSubjectArea}_${varJobNameMask}_${varRunCode}"
SAVEIFS=$IFS
while IFS='' read -r jobName || [[ -n "$jobName" ]]; do
	if [[ ${varRunCategory} == "GENERIC_STEPCODE_RUN" ]] && [[ ${varRunType} != "LookupExtract" ]]; then
		if [[ ${jobName} == "${varJobTypeAbbvr}_${varSubjectArea}_${varJobNameMask}_${varRunCode}"* ]]; then 
		# if [[ ${jobName} == "${varJobTypeAbbvr}_${varSubjectArea}_${varJobNameMask}_"* ]] && [[ ${jobName} == *"${varRunCode}"* ]]; then 
			[[ -z ${varJobNameList} ]] && varJobNameList="$jobName" || varJobNameList="$varJobNameList,$jobName"
		fi
	elif [[ ${varRunCategory} == "GENERIC_STEPCODE_RUN" ]] && [[ ${varRunType} == "LookupExtract" ]]; then
		if [[ ${jobName} == "${varJobTypeAbbvr}_${varSubjectArea}_${varJobNameMask}_"* ]] && [[ ${jobName} == *"${varRunCode}"* ]]; then 
			[[ -z ${varJobNameList} ]] && varJobNameList="$jobName" || varJobNameList="$varJobNameList,$jobName"
		fi
	else
		IFS=',' read -ra stepcodes <<< "$varRunType"
		for stepcode in "${stepcodes[@]}"; do
			if [[ ${jobName} == "${varJobTypeAbbvr}_${varSubjectArea}_${varJobNameMask}_${stepcode}"* ]]; then 
			# if [[ ${jobName} == "${varJobTypeAbbvr}_${varSubjectArea}_${varJobNameMask}_"* ]] && [[ ${jobName} == *"${stepcode}"* ]]; then 
				[[ -z ${varJobNameList} ]] && varJobNameList="$jobName" || varJobNameList="$varJobNameList,$jobName"
			fi
		done
	fi
done < ${varJobNameMask}_${varRunType}_${DATE_WITH_TIME}.txt

rm -f ${varJobNameMask}_${varRunType}_${DATE_WITH_TIME}.txt

echoWithoutLineBreak "${varJobNameList}"

# If variable 'varJobNameList' still is blank, means no such job was found
# THEN  exit with NO JOB FOUND return code
# ELSE exit success
[[ -z ${varJobNameList} ]] && exit 4 || exit 0
IFS=$SAVEIFS