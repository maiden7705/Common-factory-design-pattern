#!/bin/sh
# CommonFactory-CompressAndArchive.sh
# Author:  Adil Baig
# Create Date: 03/28/2018
# Last Modified date: 03/28/2018
#Note: This script archives all inbound, processing and reject files at archive location supplied

# execution example:
# sh /opt/IBM/data/utils/CommonFactory-CompressAndArchive.sh "SF" "SF" "AccountTeamProductLine" 6 "/opt/IBM/data/etl/bwadhoc/salesforce/processing" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/archive"
# sh #ps_BWAdHoc.$env_BWADHOC_UTILS#CommonFactory-CompressAndArchive.sh "#jp_SUBJECTAREA#" "#jp_REPORTING_SUBJECTAREA#" "#jp_JOBNAME#" #jp_PurgeAfterDays# "#ps_BWAdHoc.$env_BWADHOC_PROCESSING#" "#ps_BWAdHoc.$env_BWADHOC_REJECTS#" "#ps_BWAdHoc.$env_BWADHOC_ARCHIVE#"

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
	if [ ${#varArgCount[@]} -lt 9 ]; then
		echo 'Aborting CommonFactory-CompressAndArchive.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: ProjectName SubjectArea ReportingSubjectArea JobNameMask PurgeAfterDays ProcessingFolderPath RejectFolderPath ArchiveFolderPath RowLimiter'
		printFirstTableLine "ProjectName" "Projectname of this workspace, e.g. 'Dev_BWAdHoc' or 'Test_BWAdHoc'"
		printFirstTableLine "SubjectArea" "SubjectArea for this run, e.g. 'SF' or 'GblSales'"
		printSecondTableLine "For 'CommonFactory' design pattern, and more info on concept of [SUBJECTAREA] and [JOBNAME]"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		printFirstTableLine "ReportingSubjectArea" "ReportingSubjectArea for this run, e.g. 'SF' or 'GblSales'"
		printSecondTableLine "This may be at the same level as 'SubjectArea' or different"
		printSecondTableLine "For 'CommonFactory' design pattern, and more info on concept of [REPORTINGSUBJECTAREA] and [JOBNAME]"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		printFirstTableLine "JobNameMask" "JobNameMask for this run, e.g. 'InventoryRecon' or 'AccountTeamProductLine'"
		printSecondTableLine "For 'CommonFactory' design pattern, and more info on concept of [SUBJECTAREA] and [JOBNAME]"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		printFirstTableLine "PurgeAfterDays" "How Far back you want to keep the archive files"
		printSecondTableLine "'[JobNameMask]_[DATE_WITH_TIME].gz' for the run of this job"
		printSecondTableLine "provide numeric values for no.# of days. e.g. 6 or 15"
		printFirstTableLine "ProcessingFolderPath" "Location where 'sq_[JobNameMask]*.csv' processing files and"
		printSecondTableLine "'sq_[JobNameMask]*Debug.csv' debug files resides"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		printSecondTableLine "This can be supplied through your #ps_BWAdHoc.$env_BWADHOC_PROCESSING# parameter"
		printFirstTableLine "RejectFolderPath" "Location where 'sq_[JobNameMask]*.rej' reject files resides"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printSecondTableLine "This can be supplied through your #ps_BWAdHoc.$env_BWADHOC_REJECTS# parameter"
		printFirstTableLine "ArchiveFolderPath" "Location where you'd compress the processing and reject files"
		printSecondTableLine "'[JobNameMask]_[DATE_WITH_TIME].gz' fiels for future reference"
		printSecondTableLine "e.g. '/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printSecondTableLine "This can be supplied through your #ps_BWAdHoc.$env_BWADHOC_REJECTS# parameter"
		printFirstTableLine "RowLimiter" "The number line reject file to create for purpose of notification attachment"
		printSecondTableLine "supply a numeric value. e.g., if 500 is passed it will create:"
		printSecondTableLine "'sq_[JobNameMask]_3*rowLimited.rej' file with only 500 rows in it"
		centerPrint "returns following status codes"
		printFirstTableLine "returns 1" "Invalid number of arguements passed"
		printFirstTableLine "returns 2" "If 'ProcessingFolderPath' is invalid or not accessible to the script"
		printFirstTableLine "returns 3" "If 'RejectFolderPath' is invalid or not accessible to the script"
		printFirstTableLine "returns 4" "If 'ArchiveFolderPath' is invalid or not accessible to the script"
		printFirstTableLine "returns 5" "filename mis-match: a 'sq_{JobNameMask}*.csv'"
		printSecondTableLine "and its corresponding 'sq_{JobNameMask}*.rej' was not found to compare"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "SAMPLE COMMAND TEXT BELOW : "
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-CompressAndArchive.sh "Dev_BWAdHoc" "SF" "SF" "InventoryRecon" "7" "/opt/IBM/data/etl/bwadhoc/salesforce/processing/" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/archive" 500'
		exit 1
	fi
}

printScriptHelpTxt $@

Projectname=$1
SubjectArea=$2
ReportingSubjectArea=$3
JobNameMask=$4
PurgeAfterDays=$5
ProcessingFolder=$6
RejectFolder=$7
ArchiveFolder=$8
varRowLimiter=$9
returnCode=0
varRejectsFound=0
# Step-00 - pre-check : Check if any of the folders supplied
# are invalid or not accesible to this script.
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

# step-01A : Delete the temp folders, if they exist from before
rm -rf ${ProcessingFolder}/${JobNameMask}_gzipTemp
rm -rf ${ProcessingFolder}/${JobNameMask}_gzipTempDebug
rm -rf ${RejectFolder}/${JobNameMask}_gzipTemp
rm -rf ${RejectFolder}/${JobNameMask}_gzipTempEmail

# step-01 : create a gzip temoporary folder for this job / subject area
mkdir ${ProcessingFolder}/${JobNameMask}_gzipTemp
mkdir ${ProcessingFolder}/${JobNameMask}_gzipTempDebug
mkdir ${RejectFolder}/${JobNameMask}_gzipTemp
mkdir ${RejectFolder}/${JobNameMask}_gzipTempEmail

# step-02A : find all files in the processing folder pertaining to process execution.
find ${ProcessingFolder} -name "sq_${JobNameMask}*" -type f | while read eachFile; do
	# step -02A - Get Row count of the file greater than 1
	rowCount=`cat ${eachFile} | wc -l | tr -d '\n'`
	fileName=`echoWithoutLineBreak "$eachFile"`
	if [ "${rowCount}" -gt "1" ]
	then
		# file should not contain "Debug" keyword as those are ETL analysis files only.
		if [[ ${fileName} != *"Debug"* ]]
		then
			cp -f ${eachFile} ${ProcessingFolder}/${JobNameMask}_gzipTemp/
		else
			cp -f ${eachFile} ${ProcessingFolder}/${JobNameMask}_gzipTempDebug/
		fi
	fi
done

# step-02B : get the count reporting email body template
varEmailTemplateString=`getAllCountReportEmailBody $SubjectArea $JobNameMask`


# step-02C : create '_rowLimited.rej' version of each reject file
find ${RejectFolder} -name "sq_*${JobNameMask}*.rej" -type f | while read eachFile; do
	ErrFileName=$(basename $eachFile)
	ErrFileName="${ErrFileName%.*}"
	head -$varRowLimiter $eachFile > ${RejectFolder}/${ErrFileName}_rowLimited.rej
done

# step-03 : find all files in the reject folder pertaining to process execution.
find ${RejectFolder} -name "sq_*${JobNameMask}*.rej" -type f | while read eachFile; do
	# step -03A - Get Row count of the file greater than 1 AND 
	# file should not be a debug file that are used for ETL analysis only.
	rowCount=`cat ${eachFile} | wc -l | tr -d '\n'`
	fileName=`echoWithoutLineBreak "$eachFile"`
	if [ "${rowCount}" -gt "1" ]
	then
		if [[ ${fileName} == *"rowLimited"* ]]
			then cp -f ${eachFile} ${RejectFolder}/${JobNameMask}_gzipTempEmail/
		else		
			cp -f ${eachFile} ${RejectFolder}/${JobNameMask}_gzipTemp/
		fi
	fi
done


# step-04A : check if the folder have any file, if it does
# ONLY THEN tar the temporary gzip folders at archive location with datetime stamp
shopt -s nullglob dotglob     # To include hidden files
cd ${ProcessingFolder}/${JobNameMask}_gzipTemp
files=(${ProcessingFolder}/${JobNameMask}_gzipTemp/*)
if [ ${#files[@]} -gt 0 ] 
then tar -czf ${ArchiveFolder}/${SubjectArea}_${JobNameMask}_processingFiles_${DATE_WITH_TIME}.tar.gz *; fi

cd ${ProcessingFolder}/${JobNameMask}_gzipTempDebug
files=(${ProcessingFolder}/${JobNameMask}_gzipTempDebug/*)
if [ ${#files[@]} -gt 0 ]
then tar -czf ${ArchiveFolder}/${SubjectArea}_${JobNameMask}_DebugFiles_${DATE_WITH_TIME}.tar.gz *; fi

cd ${RejectFolder}/${JobNameMask}_gzipTemp
files=(${RejectFolder}/${JobNameMask}_gzipTemp/*)
if [ ${#files[@]} -gt 0 ]
then tar -czf ${ArchiveFolder}/${SubjectArea}_${JobNameMask}_rejectFiles_${DATE_WITH_TIME}.tar.gz *; fi

cd ${RejectFolder}/${JobNameMask}_gzipTempEmail
files=(${RejectFolder}/${JobNameMask}_gzipTempEmail/*)
if [ ${#files[@]} -gt 0 ]
then 
	tar -czf ${ArchiveFolder}/${SubjectArea}_${JobNameMask}_emailNotif_${DATE_WITH_TIME}.tar.gz *; 
	returnCode=1;
fi

# step-04B : tar all the previous tar files into one main tar file
cd ${ArchiveFolder}
#tar -czf ${SubjectArea}_${JobNameMask}_${DATE_WITH_TIME}.tar.gz -X "${SubjectArea}_${JobNameMask}_"*"Files_"*".tar.gz"
find . -name "${SubjectArea}_${JobNameMask}_*Files_*.tar.gz" | tar -czf ${SubjectArea}_${JobNameMask}_${DATE_WITH_TIME}.tar.gz --files-from -
# tar -czf SF_AccountTeamProductLine_20180329023712.tar.gz -X "SF_AccountTeamProductLine_"*"Files_"*".tar.gz"
# tar -czf SF_AccountTeamProductLine_20180329023712.tar.gz -X "SF_AccountTeamProductLine"*"Files"*".tar.gz"
# find . -name "SF_AccountTeamProductLine_*Files_*.tar.gz" | tar -czf SF_AccountTeamProductLine_20180329023712.tar.gz --files-from -

# remove the individual tar folders we created at step-04A
cd ${ArchiveFolder}
find . -name "${SubjectArea}_${JobNameMask}_*Files_*.tar.gz" -exec rm -f {} \;

# step-05A : finally remove the temporary gzip folders and all the files in it
rm -rf ${ProcessingFolder}/${JobNameMask}_gzipTemp
rm -rf ${RejectFolder}/${JobNameMask}_gzipTemp
rm -rf ${RejectFolder}/${JobNameMask}_gzipTempEmail
rm -rf ${ProcessingFolder}/${JobNameMask}_gzipTempDebug

# step-05B : remove all the run files to cleanup procesing and reject drive.
# step-05B.1 -> remove processsing files
cd ${ProcessingFolder}
find ${ProcessingFolder} -name "sq_${JobNameMask}*" -exec rm -f {} \;
# step-05B.2 -> remove all reject files
cd ${RejectFolder}
find ${RejectFolder} -name "sq_${JobNameMask}*.rej" -exec rm -f {} \;

# step 05C : Purge the actual master tar file after N days too, passed thru parameter
# 20180329164418
find ${ArchiveFolder} -mindepth 1 -name "${SubjectArea}_${JobNameMask}*_[2-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*.gz" -mtime +${PurgeAfterDays} -exec rm -f {} \;

if [ ${returnCode} -eq 0 ]
then
	sh $varUTILSFOLDER/CommonFactory-SendEmail.sh "${Projectname}" "${SubjectArea}" "${ReportingSubjectArea}" 1 "${JobNameMask}" "${varEmailTemplateString}"
	echoWithoutLineBreak $returnCode
else
	sh $varUTILSFOLDER/CommonFactory-SendEmail.sh "${Projectname}" "${SubjectArea}" "${ReportingSubjectArea}" 100 "${JobNameMask}" "${varEmailTemplateString}" "${ArchiveFolder}/${SubjectArea}_${JobNameMask}_emailNotif_${DATE_WITH_TIME}.tar.gz"
	echoWithoutLineBreak $returnCode ${DATE_WITH_TIME}
fi

#restore the original IFS back
IFS=$SAVEIFS