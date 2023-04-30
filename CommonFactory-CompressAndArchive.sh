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
		echo 'Arguments should be, in this order: ProjectName SubjectArea JobNameMask PurgeAfterDays ArchivalMode ProcessingFolderPath RejectFolderPath ArchiveFolderPath RowLimiter'
		printFirstTableLine "ProjectName" "Projectname of this workspace, e.g. 'Dev_BWAdHoc' or 'Test_BWAdHoc'"
		printFirstTableLine "SubjectArea" "SubjectArea for this run, e.g. 'SF' or 'GblSales'"
		printSecondTableLine "For 'CommonFactory' design pattern, and more info on concept of [SUBJECTAREA] and [JOBNAME]"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		printFirstTableLine "JobNameMask" "JobNameMask for this run, e.g. 'InventoryRecon' or 'AccountTeamProductLine'"
		printSecondTableLine "For 'CommonFactory' design pattern, and more info on concept of [SUBJECTAREA] and [JOBNAME]"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		printFirstTableLine "PurgeAfterDays" "How Far back you want to keep the archive files"
		printSecondTableLine "'[JobNameMask]_[DATE_WITH_TIME].gz' for the run of this job"
		printSecondTableLine "provide numeric values for no.# of days. e.g. 6 or 15"
		printFirstTableLine "ArchivalMode" "What are the modes you want to archive"
		printSecondTableLine "from the following four options:"
		printSecondTableLine "[NONE]"
		printSecondTableLine "[REJECTS_ONLY]"
		printSecondTableLine "[REJECTS_AND_PROCESSING_ALLFILES]"
		printSecondTableLine "[REJECTS_AND_PROCESSING_LOADFILES]"
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
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "SAMPLE COMMAND TEXT BELOW : "
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-CompressAndArchive.sh "Dev_BWAdHoc" "SF" "InventoryDelta" "7" "REJECTS_ONLY" "/opt/IBM/data/etl/bwadhoc/salesforce/processing/" "/opt/IBM/data/etl/bwadhoc/salesforce/reject" "/opt/IBM/data/etl/bwadhoc/salesforce/archive" 500'
		exit 1
	fi
}

printScriptHelpTxt $@

Projectname=$1
SubjectArea=$2
JobNameMask=$3
PurgeAfterDays=$4
ArchivalMode=$5
ProcessingFolder=$6
RejectFolder=$7
ArchiveFolder=$8
varRowLimiter=$9
#ReconEmailSent=$10
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

# step-00 : if we are simply asked to delete everything
# and DO NOT archive any of the files involved.
if [[ $ArchivalMode == 'NONE' ]]; then
	# delete all the fiels involved
	DeleteProcessingFiles
	DeleteRejectFiles
	exit 0
fi
# step-01A : Delete the temp folders, if they exist from before
DeleteTempFolders
# step-01B : create a gzip temoporary folder for this job / subject area
CreateTempFolders

if [[ $ArchivalMode == 'REJECTS_ONLY' ]]; then
	ArchiveRejectFiles
fi
# step-03 : Find all the processing files and archive them
if [[ $ArchivalMode == 'REJECTS_AND_PROCESSING_ALLFILES' ]]; then
	ArchiveRejectFiles
	ArchiveProcessingFiles "All"
fi

# step-04 : Find only the load (300*) processing files and archive them
if [[ $ArchivalMode == 'REJECTS_AND_PROCESSING_LOADFILES' ]]; then
	ArchiveRejectFiles
	ArchiveProcessingFiles "Load"
fi

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
find . -name "${SubjectArea}_${JobNameMask}_*Files_*.tar.gz" | tar -czf ${SubjectArea}_${JobNameMask}_${DATE_WITH_TIME}.tar.gz --files-from -

# step-05A : finally remove all the files involved
DeleteTemporaryGZipFiles
DeleteTempFolders
DeleteProcessingFiles
DeleteRejectFiles

find ${ArchiveFolder} -mindepth 1 -name "${SubjectArea}_${JobNameMask}*_*.gz" -mtime +${PurgeAfterDays} -exec rm -f {} \;

#restore the original IFS back
IFS=$SAVEIFS