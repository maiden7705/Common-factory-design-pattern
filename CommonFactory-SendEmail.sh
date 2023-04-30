#!/bin/sh
# CommonFactory-SendEmail.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/04/29
#
# Utility to send emails out
#
# usage: sh ./CommonFactory-SendEmail.sh <ProjectName(withOrWithoutEnvironment)> <subjectArea> <JobStatusCode> <JobName> <bodyText[OPTIONAL]>
# e.g. :
# sh /opt/IBM/data/utils/CommonFactory-SendEmail.sh "BWAdHoc" "SF" "SF" 2 "stg_SF_Lookup_Account_110_warning"
# sh /opt/IBM/data/utils//CommonFactory-SendEmail.sh Dev_BWAdHoc "#jp_SUBJECTAREA#" "#jp_REPORTING_SUBJECTAREA#" 3 "seq_SF_Common_RunJobs" "<p>Job&nbsp;<strong>Jobs/Salesforce/Common/seq_SF_Common_RunJobs</strong> failed at script&nbsp;<strong>getLastPartFromFilePath.sh</strong> running for param&nbsp;\'<strong><span style=\'color: #993300;\'>JobNameMask=Lookup</span></strong>\' and \'<strong><span style=\'color: #993300;\'>RunType=LookupExtract</span></strong>\' on trying to fetch&nbsp;<strong>ProjectName</strong></p>"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255

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
		echo 'Aborting CommonFactory-SendEmail.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: ProjectName subjectArea reportingSubjectArea StatusCode ExactJobName (OPTIONAL)BodyTextHtml (OPTIONAL)AttachmentLink'
		printFirstTableLine "ProjectName" "Name of the project this job is under. e.g.: 'Test_BWAdHoc'"
		printFirstTableLine "subjectArea" "Name of the subject area of this project. e.g.: 'EPIQ_Target_ProductEventReview'"
		printFirstTableLine "reportingSubjectArea" "Name of the reporting subject area of this project. e.g.: 'EPIQ'"
		printSecondTableLine "the reason for two 'subjectArea' and 'reportingSubjectArea'"
		printFirstTableLine "StatusCode" "From the following list of status codes"
		printSecondTableLine "0,1,2,3,4,11,12,13,21,96,97,98"
		printSecondTableLine "See datastage product documentation for more details"
		printSecondTableLine "https://www-304.ibm.com/support/docview.wss?uid=swg21469644"
		printFirstTableLine "ExactJobName" "The Exact name of the job, without wildcard of anything"
		printSecondTableLine "e.g. : 'stg_SF_Lookup_Account_110_Extract'"
		printFirstTableLine "[OPTIONAL]BodyText[Html]" "[OPTIONAL parameter]The Body text you want to print"
		printSecondTableLine "you can OPTIONALLY even sent an HTML body, example below"
		printSecondTableLine "for e.g.: 'Some body text on line in<br/>' : "
		printSecondTableLine "'Some keyword in <b>BOLD</b> on next line<br/>' : "
		printSecondTableLine "'<strong><span style='color: #993300;'>SOME TEXT IN RED COLOR IN BOLD AND LITTLE BIGGER </span></strong><br/>'"
		printFirstTableLine "[OPTIONAL]AttachmentLink" "[OPTIONAL parameter]everything provided from 6th param onwards would be attachment path"
		centerPrint "returns following status codes"
		printFirstTableLine "returns 1" "Invalid number of arguements passed"
		printFirstTableLine "returns 2" "Cannot find <subjectArea>_FAILUREEMAIL or <subjectArea>_NOTIFEMAIL environment variable"
		printSecondTableLine "make sure you have supplied a valid 'subjectArea' at second parameter"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		centerPrint "SAMPLE COMMAND TEXT BELOW : "
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-SendEmail.sh "Dev_BWAdHoc" "SF" "SF" 2 "stg_SF_Lookup_Account_110_warning"'
		echo "OR with a body text and attachment passed, like this:"
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-SendEmail.sh "Dev_BWAdHoc" "SF" "SF" 2 "stg_SF_Lookup_Account_110_warning" "<p>Some body text in <b>BOLD</b><br/></p>" "/opt/IBM/data/etl/bwadhoc/salesforce/reject/sq_Product_305_Update.rej"'
		 exit 1
	fi
}

printScriptHelpTxt $@

getProjectName()
{
	varPrgNm=$1
	count=0; TEMPFILE=${varPrgNm}_`date "+%Y%m%d-%H%M%S"`.tmp; echo $count > $TEMPFILE
	SAVEIFS=$IFS
	while IFS='_' read -ra projPart; do
		for i in "${projPart[@]}"; do
			count=$[$(cat $TEMPFILE) + 1];echo $count > $TEMPFILE;
		done
	done <<< "${varPrgNm}"
	rm -f $TEMPFILE
	# echo $count
	
	if [[ ${count} -eq 2 ]];then
		echoWithoutLineBreak "${varPrgNm}"
	else
		echoWithoutLineBreak "${varHostName}_${varPrgNm}"
	fi
}

varFailureEmails=''
varNotifEmails=''
varSenderEmail=''
varProjName=$1
varSubjectArea=$2
varReportingSubjectArea=$3
varCorrectedProjName=`getProjectName $varProjName`
varStausCode=$4
varStatusText=`getJobStatusText $varStausCode`
# echo "status text is : $varStatusText"; exit;
varJobName=$5
varOPTIONALbodyText=$6
# get_mimetype()
# {
	# if [ -z "$1" ]
	# then
		# echo "no filepassed to check mime-type: syntax: get_mimetype \"path/to/filename.txt\" "
		# return;
	# fi
  # filename=$1
  # # get the mime-type now
  # file --mime-type $filename | awk -F ": " '{print $2}' | tr -d '\n'
# }

get_mimetype(){
  # warning: assumes that the passed file exists
  file --mime-type "$1" | sed 's/.*: //' 
}

getEnvironmentVariableValue()
{
	getEnvVarValue ${varCorrectedProjName} $1
}

getMailParamSetValues()
{
	local -r paramset='Mail_Param_Set'
	varparamsetAttribute=$1
	
	$DSHOME/bin/dsjob -projectinfo $varCorrectedProjName | while read -r projInfo; do
		# echo "project info line is : $projInfo"; continue;
		IFS=':' read -r -a projInfoArray <<< "$projInfo"
		if [[ ${projInfoArray[0]} == "Project Path"* ]]; then
			varProjFolderPath=`echo ${projInfoArray[1]} | tr -d '[:space:]'`
			cd $varProjFolderPath/ParameterSets/$paramset
			case $varHostName in
			'Dev'					) cat "DEV" | while read -r paramsetValues
										do
											IFS='=' read -r -a array <<< "$paramsetValues"
											if [[ "${varparamsetAttribute}" == "${array[0]}" ]]; then
												echoWithoutLineBreak "${array[1]}"
											fi
										done;;
			'Test'					) cat "QA" | while read -r paramsetValues
										do
											IFS='=' read -r -a array <<< "$paramsetValues"
											if [[ "${varparamsetAttribute}" == "${array[0]}" ]]; then
												echoWithoutLineBreak "${array[1]}"
											fi
										done;;
			'Prod'					) cat "PROD" | while read -r paramsetValues
										do
											IFS='=' read -r -a array <<< "$paramsetValues"
											if [[ "${varparamsetAttribute}" == "${array[0]}" ]]; then
												echoWithoutLineBreak "${array[1]}"
											fi
										done;;
			
			esac
		fi
	done
	
}

varFailureEnv="env_${varReportingSubjectArea}_FAILUREEMAIL"
varNotifEnv="env_${varReportingSubjectArea}_NOTIFEMAIL"
varFailureEmails="$(getEnvironmentVariableValue "$varFailureEnv")"
varNotifEmails="$(getEnvironmentVariableValue "$varNotifEnv")"
# echo Failure email is : $varFailureEmails; echo Notif email is : $varNotifEmails; exit;
# getMailParamSetValues 'SenderAddress'
varSenderEmail=`getMailParamSetValues 'SenderAddress'`
varBadSubjctArea=0
# if subject area was not passed, it will fail to fetch
# recipient list from 'env_${varReportingSubjectArea}_FAILUREEMAIL'
# and 'env_${varReportingSubjectArea}_NOTIFEMAIL',
# In this case, we will default to the recipient in 'Mail_Param_Set' defaults
if [[ -z ${varFailureEmails} ]]; then
	varFailureEmails=`getMailParamSetValues 'FailureAddress'`
	varBadSubjctArea=1
	else
	varFailureEmails="${varFailureEmails}"
fi

if [[ -z ${varNotifEmails} ]]; then
	varNotifEmails=`getMailParamSetValues 'DefaultAddress'`
	varBadSubjctArea=1
	else
	varNotifEmails="${varNotifEmails}"
fi

#echo "sender address is : ${varSenderEmail}";
#echo "email list incase of failure : ${varFailureEmails}";
#echo "email list for general notif : ${varNotifEmails}";


from=$varSenderEmail
if (( $varStausCode != 1 )); then
	to=$varFailureEmails
	subject="${varCorrectedProjName} : ${varSubjectArea}_${varJobName} Run is at status: $varStatusText"
	[[ -z ${varOPTIONALbodyText} ]] && body="<html><body>The job <b>$varJobName</b> failed run with status: <b><font size="3" color=\"red\">$varStatusText</font></b><br/></body></html>" || body="<html><body>${varOPTIONALbodyText}<br/><br/><strong>Job Run Status : <font size="3" color=\"red\">$varStatusText</font></strong><br/></body></html>"
	else
	to=$varNotifEmails
	subject="${varCorrectedProjName} : ${varSubjectArea}_${varJobName} Run finished successfully"
	[[ -z ${varOPTIONALbodyText} ]] && body="<html><body>The job <b>${varSubjectArea}_$varJobName</b> completed the run successfully !<br/></body></html>" || body="<html><body>${varOPTIONALbodyText}<br/><br/><strong>Job Run Status : <font size="3" color=\"green\">$varStatusText</font></strong><br/></body></html>"
fi

if (( $varStausCode == 100 )); then
	to=$varNotifEmails
	subject="${varCorrectedProjName} : ${varSubjectArea}_${varJobName} Run completed with rejects"
	[[ -z ${varOPTIONALbodyText} ]] && body="<html><body>The job <b>${varSubjectArea}_$varJobName</b> ran successfully with status : <b><font size="3" color=\"red\">COMPLETED WITH REJECTS</font></b><br/></body></html>" || body="<html><body>${varOPTIONALbodyText}<br/><br/><strong>Job Run Status : <font size="3" color=\"orange\">COMPLETED WITH REJECTS</font></strong><br/></body></html>"
fi

if (( $varStausCode == 150 )); then
	to=$varNotifEmails
	subject="${varCorrectedProjName} : ${varSubjectArea}_${varJobName} Run is in Progress"
	[[ -z ${varOPTIONALbodyText} ]] && body="<html><body>The job <b>${varSubjectArea}_$varJobName</b> Running with status : <b><font size="3" color=\"green\">IN PROGRESS</font></b><br/></body></html>" || body="<html><body>${varOPTIONALbodyText}<br/><br/><strong>Job Run Status : <font size="3" color=\"green\">IN PROGRESS</font></strong><br/></body></html>"
fi		

if [[ $varStausCode = "S" ]] || [[ $varStausCode = "C" ]]; then
	to=$varNotifEmails
	subject="${varCorrectedProjName} : ${varSubjectArea}_${varJobName} Run has $varStatusText"
	[[ -z ${varOPTIONALbodyText} ]] && body="<html><body>The job <b>${varSubjectArea}_$varJobName</b> has <strong>$varStatusText.</strong><br/><br/>" || body="<html><body>${varOPTIONALbodyText}<br/><br/><strong>Job Run Status : <font size="3" color=\"green\">$varStatusText</font></strong><br/></body></html>"
fi

if (( $varBadSubjctArea == 1 )); then
	to=$varFailureEmails
	subject="!! ${varCorrectedProjName} : ${varSubjectArea}_${varJobName} Load : - REPORTING EMAILS NOT FOUND !!"
	if [[ -z ${varOPTIONALbodyText} ]]; then 
		body="<html><body><strong><font size="3" color=\"red\">!! URGENT !!</font></strong><br/>Couldn't find environment variables : <strong>env_<span style='color: #993300;'>$varSubjectArea</span>_NOTIFEMAIL</strong> and <strong>env_<span style='color: #993300;'>$varSubjectArea</span>_FAILUREEMAIL</strong> under project space : <strong>$varCorrectedProjName</strong><br/>
		For the supplied parameter value <strong>jp_REPORTING_SUBJECTAREA='$varSubjectArea'<strong><br/><br/><strong>Job Run Status : <font size="3" color=\"orange\">RUNNING WITHOUT PROJECT SPECIFIC EMAIL LIST</font></strong><br/></body></html>" 
		else
		body="<html><body>${varOPTIONALbodyText}<br/><br/><strong><font size="3" color=\"red\">!! URGENT !!</font></strong><br/>Couldn't find environment variables : <strong>env_<span style='color: #993300;'>$varSubjectArea</span>_NOTIFEMAIL</strong> and <strong>env_<span style='color: #993300;'>$varSubjectArea</span>_FAILUREEMAIL</strong> under project space : <strong>$varCorrectedProjName</strong><br/>
			For the supplied parameter value <strong>jp_REPORTING_SUBJECTAREA='$varSubjectArea'<strong><br/><br/><strong>Job Run Status : <font size="3" color=\"orange\">RUNNING WITHOUT PROJECT SPECIFIC EMAIL LIST</font></strong><br/></body></html>"
	fi		
fi	



boundary="ZZ_/afg6432dfgkl.94531q"
declare -a attachments
# to make all arguement after Nth argument as array, use the code :
attachments=( "${@:7}" ) #where N is the number of arguement after which everything else is attachment

# Build headers
{
printf '%s\n' "From: $from
To: $to
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"$boundary\"

--${boundary}
Content-Type: text/html; charset=\"US-ASCII\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

$body
"
 
# now loop over the attachments, guess the type
# and produce the corresponding part, encoded base64
for file in "${attachments[@]}"; do

  [ ! -f "$file" ] && echo "Warning: attachment $file not found, skipping" >&2 && continue

  mimetype=$(get_mimetype "$file") 
 
  printf '%s\n' "--${boundary}
Content-Type: $mimetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$(basename $file)\"
"
 
  base64 "$file"
  echo
done
 
# print last boundary with closing --
printf '%s\n' "--${boundary}--"
 
} | /usr/lib/sendmail -t -oi   # one may also use -f here to set the envelope-from
IFS=$SAVEIFS