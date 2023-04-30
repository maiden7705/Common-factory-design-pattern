#!/bin/sh
# CommonFactory-StopAtRejectsFound.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/07/05 
#
# Checks if particular job steps had rejects,
# if it did, get the row count of the file, 
#		if its > 1, 
#		report to failure notif email with exact job name, attaching that reject file and informing the reject count.
#
# usage: sh ./CommonFactory-StopAtRejectsFound.sh <projectName> <subjectArea> <reportingSubjectArea> <JobNameMask> <ExactJobName> <RejectFolderPath> <ProcessingFolderPath>
# e.g. :
# sh /opt/IBM/data/utils/CommonFactory-StopAtRejectsFound.sh "Dev_BWAdHoc" "SF" "SF" "7" "InventoryDelta" "stg_SF_InventoryDelta_204_AccountLookup" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/processing/" "/opt/IBM/data/etl/bwadhoc/salesforce/archive" "500"
# sh /opt/IBM/data/utils/CommonFactory-StopAtRejectsFound.sh "Dev_BWAdHoc" "SF" "SF" "7" "InventoryDelta" "stg_SF_InventoryDelta_204_AccountLookup_multipleRjctsDemo" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/processing/" "/opt/IBM/data/etl/bwadhoc/salesforce/archive" "500"
# sh /opt/IBM/data/utils/CommonFactory-StopAtRejectsFound.sh "Dev_BWAdHoc" "SF" "SF" "7" "InventoryDelta" "stg_SF_InventoryDelta_204_AccountLookup_noRjctsDemo" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/processing/" "/opt/IBM/data/etl/bwadhoc/salesforce/archive" "500"
# sh /opt/IBM/data/utils/CommonFactory-StopAtRejectsFound.sh "Dev_BWAdHoc" "SF" "SF" "7" "InventoryDelta" "stg_SF_InventoryDelta_204_AccountLookup_noRjctCountDemo" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/processing/" "/opt/IBM/data/etl/bwadhoc/salesforce/archive" "500"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255

# check if proper number of arguements were passed
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
	if [ ${#varArgCount[@]} -lt 10 ]; then
		echo 'Aborting CommonFactory-StopAtRejectsFound.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: ProjectName subjectArea ReportingSubjectArea PurgeAfterDays JobNameMask ExactJobName RejectFolderPath ProcessingFolderPath ArchiveFolderPath RowLimiter'
		printFirstTableLine "ProjectName" "Name of this environment's project"
		printSecondTableLine "e.g. In Dev, pass 'Dev_BWAdHoc'"
		printFirstTableLine "subjectArea" "subject area for this run. e.g. 'SF' or 'Abbott', etc"
		printFirstTableLine "ReportingSubjectArea" "ReportingSubjectArea for this run, e.g. 'SF' or 'GblSales'"
		printSecondTableLine "This may be at the same level as 'SubjectArea' or higher or lower"
		printSecondTableLine "refer to CommonFactory Standards document"
		printFirstTableLine "PurgeAfterDays" "How Far back you want to keep the archive files"
		printSecondTableLine "'[JobNameMask]_[DATE_WITH_TIME].gz' for the run of this job"
		printSecondTableLine "provide numeric values for no.# of days. e.g. 6 or 15"
		printFirstTableLine "JobNameMask" "The name of this run, to which all parellel jobs being run belong to"
		printSecondTableLine "e.g. 'InventoryDelta' or 'PhysicianAttributes'"
		printFirstTableLine "ExactJobName" "Exact name of the job to check rejects files of"
		printSecondTableLine "e.g.: 'stg_SF_InventoryDelta_204_AccountLookup'"
		printFirstTableLine "RejectFolderPath" "Location where 'sq_[JobNameMask]*.rej' reject files resides"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printSecondTableLine "This can be supplied through your #ps_BWAdHoc.$env_BWADHOC_REJECTS# parameter"
		printFirstTableLine "ProcessingFolderPath" "Location where 'sq_[JobNameMask]*.csv' processing files and"
		printSecondTableLine "'sq_[JobNameMask]*Debug.csv' debug files resides"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		printFirstTableLine "ArchiveFolderPath" "Location where you'd compress the processing and reject files"
		printSecondTableLine "'[JobNameMask]_[DATE_WITH_TIME].gz' fiels for future reference"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printSecondTableLine "This can be supplied through your #ps_BWAdHoc.$env_BWADHOC_REJECTS# parameter"
		printFirstTableLine "RowLimiter" "The number line reject file to create for purpose of notification attachment"
		printSecondTableLine "supply a numeric value. e.g., if 500 is passed it will create:"
		printSecondTableLine "'sq_[JobNameMask]_3*rowLimited.rej' file with only 500 rows in it"
		centerPrint "returns following exit codes:"
		printFirstTableLine "returns 1" "If correct number of parameters were not passed"
		printFirstTableLine "returns 2" "If 'ProcessingFolderPath' is invalid or not accessible to the script"
		printFirstTableLine "returns 3" "If 'RejectFolderPath' is invalid or not accessible to the script"
		printFirstTableLine "returns 4" "If 'ArchiveFolderPath' is invalid or not accessible to the script"
		printFirstTableLine "returns 5" "Rejects were found and email was sent, stop further jobs"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "SAMPLE COMMAND TEXT BELOW (quote all arguements before passing as good practice) : "		
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-StopAtRejectsFound.sh "Dev_BWAdHoc" "SF" "SF" "7" "InventoryDelta" "stg_SF_InventoryDelta_204_AccountLookup" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/processing/" "/opt/IBM/data/etl/bwadhoc/salesforce/archive" "500"'
		exit 1
	fi
}

printScriptHelpTxt $@

Projectname=$1
SubjectArea=$2
ReportingSubjectArea=$3
PurgeAfterDays=$4
JobNameMask=$5
varExactJobName=$6
RejectFolder=$7
ProcessingFolder=$8
ArchiveFolder=$9
varRowLimiter=${10}

if [ ! -d "$ProcessingFolder" ]; then
	IFS=$SAVEIFS
	exit 2
fi

if [ ! -d "$RejectFolder" ]; then
	IFS=$SAVEIFS
	exit 3
fi

if [ ! -d "$ArchiveFolder" ]; then
	IFS=$SAVEIFS
	exit 4
fi
		#varRejectNameToCheck="sq_${JobNameMask}_${jobNamePart}*"
		#echo ${varRejectNameToCheck}
		#find ${RejectFolder} -name ${varRejectNameToCheck} | while read fileNameMatch; do
		#	echo "found file :${fileNameMatch}"
		#done
		
#varAfterMask=`echoWithoutLineBreak $your_str | grep -o '${JobNameMask}.*' | tr -d '\n'`
# IFS='=' read -r -a jobNameParts <<< "$varExactJobName"
varEmailTemplateString=''
IFS='_' read -r -a jobNameParts <<< "$varExactJobName"
for jobNamePart in "${jobNameParts[@]}"
do
	#echo $jobNamePart
	numericMatch='^[0-9]+$'
	if [[ $jobNamePart =~ $numericMatch ]] ; then
		varRejectNameToCheck="sq_${JobNameMask}_${jobNamePart}*"
		find ${RejectFolder} -name ${varRejectNameToCheck} > ${varExactJobName}_findResult.txt
		#varFilesFoundCount=`find ${RejectFolder} -name ${varRejectNameToCheck} | awk '{n++;print}END{print n}' | tr '\r\n' ' ' | cut -f2 -d' '`
		varFilesFoundCount=`wc -l ${varExactJobName}_findResult.txt | cut -f1 -d' '`
		rm -f ${varExactJobName}_findResult.txt
		loopCounter=1
		#echo "total files found are : $varFilesFoundCount"
		find ${RejectFolder} -name ${varRejectNameToCheck} | while read fileNameMatch; do
			varRejectCount=`wc -l $fileNameMatch | cut -f1 -d' '`
			varRejectCount=$(( varRejectCount - 1 ))
			if (( $varRejectCount > 1 )); then
					varEmailTemplateString=`getthisJobRejectCountReportEmailBody "$SubjectArea" "$JobNameMask" "$jobNamePart" "$varExactJobName"`
					ErrFileName=$(basename $fileNameMatch)
					ErrFileName="${ErrFileName%.*}"
					#if [ "$loopCounter" -eq "$varFilesFoundCount" ]; then
						#echo "reached the last file in the list"
						#echo ${varEmailTemplateString}
						
						# Delete the temp folders, if they exist from before
						DeleteTempFolders
						# Create a gzip temoporary folder for this job / subject area
						CreateTempFolders
						# archive the files and create their rowLimited version for attachment
						ArchiveStepCodeRejectFiles

						cd ${RejectFolder}/${JobNameMask}_gzipTempEmail
						files=(${RejectFolder}/${JobNameMask}_gzipTempEmail/*)
						if [ ${#files[@]} -gt 0 ]
						then 
							tar -czf ${ArchiveFolder}/${varExactJobName}_${DATE_WITH_TIME}.tar.gz *; 
							returnCode=1;
						fi

						if [ ${returnCode} -eq 0 ]
						then
							sh $varUTILSFOLDER/CommonFactory-SendEmail.sh "${Projectname}" "${SubjectArea}" "${ReportingSubjectArea}" 1 "${JobNameMask}" "${varEmailTemplateString}"
							echoWithoutLineBreak "CLEAN"; exit 5;
						else
							sh $varUTILSFOLDER/CommonFactory-SendEmail.sh "${Projectname}" "${SubjectArea}" "${ReportingSubjectArea}" 100 "${JobNameMask}" "${varEmailTemplateString}" "${ArchiveFolder}/${varExactJobName}_${DATE_WITH_TIME}.tar.gz"
							echoWithoutLineBreak "REJECTS_FOUND" 
							echoWithoutLineBreak "REJECTS_FOUND" > ${RejectFolder}/${varExactJobName}_scriptResult.txt
						fi
						DeleteTempFolders
						DeleteRejectRowLimitedFiles
						exit 5
					#fi
			fi
			
			loopCounter=$(( loopCounter + 1 ))
		done
	fi
done
if [ -f ${RejectFolder}/${varExactJobName}_scriptResult.txt ]; then
	varScriptResult=`cat ${RejectFolder}/${varExactJobName}_scriptResult.txt`
	if [[ ${varScriptResult} == "REJECTS_FOUND" ]]; then
		#echo inside the scriptResult file check
		rm -f ${RejectFolder}/${varExactJobName}_scriptResult.txt
		IFS=$SAVEIFS
		exit 5
	
	fi
else
	echoWithoutLineBreak "CLEAN"
	IFS=$SAVEIFS
	exit 0;
fi