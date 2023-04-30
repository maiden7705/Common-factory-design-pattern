#!/bin/sh
# CommonFactory-RunJobCmd.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/04/26
#
# Utility runs a ds job and returns the jobs status
#
# usage: sh ./CommonFactory-RunJobCmd.sh <ProjectNameWithoutEnvpart> <commaSeperatedParameters> <JobName> <warningsOK[YES|NO]>
# e.g. :
# sh /opt/IBM/data/utils/CommonFactory-RunJobCmd.sh "Dev_BWAdHoc" "ps_BWAdHoc=salesforce,jp_JOBNAME=Account,jp_DEBUG=1" "stg_SF_Lookup_Account_110_Extract" "YES"
# sh /opt/IBM/data/utils/CommonFactory-RunJobCmd.sh "Dev_BWAdHoc" "SF" "ps_BWAdHoc=salesforce,jp_JOBNAME=Account,jp_DEBUG=1" "stg_SF_Lookup_Contact_110_Extract" "YES"
# sh /opt/IBM/data/utils/CommonFactory-RunJobCmd.sh "BWAdHoc" "SF" "ps_BWAdHoc=salesforce,jp_JOBNAME=Account,jp_DEBUG=1" "stg_SF_Lookup_Account_110_warning" "NO"
# sh /opt/IBM/data/utils/CommonFactory-RunJobCmd.sh "BWAdHoc" "SF" "ps_BWAdHoc=salesforce,jp_JOBNAME=Account,jp_DEBUG=1" "stg_SF_Lookup_Account_110_error" "NO"
# invalid param example, jpFILE does not apply to this job so that will be omitted:
# sh /opt/IBM/data/utils/CommonFactory-RunJobCmd.sh "BWAdHoc" "SF" "ps_BWAdHoc=salesforce,jp_JOBNAME=Account,jp_DEBUG=1,jpFILE=file name.txt" "stg_SF_Lookup_Account_110_error" "NO"
# sh #ps_BWAdHoc.$env_BWADHOC_UTILS#/CommonFactory-RunJobCmd.sh "#uvParams1.ProjectName#" "#uvParams1.FinalParamList#" "#slp_RunJobCmds.$Counter#" "#jp_WARNINGAOK#"
# sh /opt/IBM/data/utils//CommonFactory-RunJobCmd.sh Dev_BWAdHoc SF ps_BWAdHoc=salesforce,jp_JOBNAME=Lookup,jp_DEBUG=0 Dev_BWAdHoc NO

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
	if [ ${#varArgCount[@]} -lt 4 ]; then
		echo 'Aborting CommonFactory-RunJobCmd.sh - invalid number of arguments'
		echo 'Arguments should be, in this order: ProjectName CommaSeperatedParameters JobName warningsOK(YES|NO)'
		printFirstTableLine "ProjectName" "Name of this environment's project"
		printSecondTableLine "e.g. In Dev, pass 'Dev_BWAdHoc'"
		printFirstTableLine "CommaSeperatedParameters" "The comma seperate list of parameters to pass to the job"
		printSecondTableLine "e.g.: 'ps_BWAdHoc=salesforce,jp_JOBNAME=Account,jp_DEBUG=1'"
		printFirstTableLine "JobName" "The exact name of the job without Wildcard or anything"
		printSecondTableLine "e.g.: 'stg_SF_Lookup_Account_110_Extract'"
		printFirstTableLine "warningsOK" "Whether its ok to consider job run with WARNING OK (YES) or NOT OK (NO)"
		printSecondTableLine "for 'NO', it will create a non-zero exit status code for all job run statuses other than 1"
		echo 'e.g.: sh /opt/IBM/data/utils/CommonFactory-RunJobCmd.sh "Prod_BWAdHoc" "ps_BWAdHoc=salesforce,jp_JOBNAME=Account,jp_DEBUG=1" "stg_SF_Lookup_Account_110_warning" "YES"'
		echo "returns following exit codes:"
		printFirstTableLine "returns 1" "If correct number of parameters were not passed"
		printFirstTableLine "returns 2" "If the job passed at parameter $3 is not in a runnable state"
		printFirstTableLine "returns 3" "If the job returned a negative exit code while running"
		printFirstTableLine "returns 4" "If the job finished with a positive exit code that is not allowed"
		printFirstTableLine "returns 5" "The supplied project name was invalid, no such project found"
		printSecondTableLine "That would be all other codes starting from exit code 2: (WARNING)"
		printSecondTableLine "0,1,2,3,4,11,12,13,21,96,97,98"
		printSecondTableLine "See datastage product documentation for more details on exit codes"
		printSecondTableLine "https://www-304.ibm.com/support/docview.wss?uid=swg21469644"
		printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
		printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
		printSecondTableLine "Make sure its available and not deleted"
		
		exit 1
	fi
}

printScriptHelpTxt $@

varProjectName=$1
#varSubjectArea=$2
varParameterValues=$2
varJobName=$3
varNotRunnableMsg="<p>!! The job : <span style='color: #993300;'><strong>$varJobName</strong></span> is not in runnable state, please reset and/or recompile !!</p>"
varWarningsOk=$4
varJobRunString="$DSHOME/bin/dsjob -run -mode NORMAL"
varReturnParamList=''

varbadProjectLog='BADPROJECT'
varbadProjectStatus='-1002'
# since we will pass a universal list of param=value from sequencer job properties, 
# we need to only pass those into this job run that applies to it, 
# if, the passed parameter in the comma seperated param list is found in this job's parameter list, we allow the 'param=value' to be passed
# else, we omit it.
$DSHOME/bin/dsjob -lparams $varProjectName $varJobName &> ${varJobName}_${DATE_WITH_TIME}
if grep -q varbadProjectStatus ${varJobName}_${DATE_WITH_TIME}; then
	#centerPrint "Invalid project: ${varProjectName}"
	rm -f ${varJobName}_${DATE_WITH_TIME}
	echo "!ERROR! : The supplied project name '${varProjectName}' was invalid, no such project found"
	 exit 5
fi

SAVEIFS=$IFS
while IFS='' read -r eachParam || [[ -n "$eachParam" ]]; do
	IFS='.' read -r -a array <<< "$eachParam"
	varParamName=${array[0]}
	varParamSubAttribute=${array[1]}
	#centerPrint "at param : ${varParamName}"
	#If job is in error state, we need to exit and report error
	if [[ ${varParamName} == "ERROR" ]]; then
		rm -f ${varJobName}_${DATE_WITH_TIME}
		echo "Unable to run: $varJobName, not in a runnable state"
		 exit 2; 
	fi
	
	paramArray=$(echoWithoutLineBreak $varParameterValues | sed "s/,/ /g")
	#centerPrint "printing input vs generated array"; read;
	#echo "${varParameterValues}"
	#printf '%s\n' "${paramArray[@]}"
	for eachParamPassed in $(echo $varParameterValues | sed "s/,/ /g")
	do
		#echo $eachParamPassed
		IFS='=' read -r -a paramNameValue <<< "$eachParamPassed"
		if [[ ${paramNameValue[0]} == ${varParamName} ]]; then
			if [[ ${varReturnParamList} != *"${eachParamPassed}"* ]]; then
				[[ -z ${varReturnParamList} ]] && varReturnParamList="$eachParamPassed" || varReturnParamList="$varReturnParamList,$eachParamPassed"
			fi
		fi
	done
done < ${varJobName}_${DATE_WITH_TIME}
rm -f ${varJobName}_${DATE_WITH_TIME}

# now that we have the valid comma seperated list of params: param1=value1, param2=value2, etc.
# form the string -param "param=value" for each combination.
for i in $(echo $varReturnParamList | sed "s/,/ /g")
do
	varJobRunString="$varJobRunString -param \"$i\""
done

centerPrint "Running job: $varJobName"
varJobRunString="$varJobRunString -wait -jobstatus $varProjectName $varJobName"

# Reset job command string would be same as NORMAL run except -mode is RESET
# we will replace that in varJobRunString string and save it into varJobResetString variable
varJobResetString=`echo "${varJobRunString/NORMAL/RESET}" | tr -d '\n'`

#cd into utils folder
cd $varUTILSFOLDER

# lets first reset the job if needed
# this can be found out by checked the job status
$DSHOME/bin/dsjob -jobinfo $varProjectName $varJobName &> ${varJobName}_${DATE_WITH_TIME}

while IFS='' read -r jobInfoLine || [[ -n "$jobInfoLine" ]]; do
	#echo "printing error line: $jobInfoLine" Status code
	
	#If job is in error state, we need to  exit and report error
	if [[ ${jobInfoLine[0]} == "ERROR" ]]; then 
		rm -f ${varJobName}_${DATE_WITH_TIME}
		echo "Unable to run: $varJobName, not a runnable job"
		 exit 2; 
	fi
	
	if [[ ${jobInfoLine} == "Job Status"* ]] || [[ ${jobInfoLine} == "Status code"* ]]; then
		varStatCode=$(echo ${jobInfoLine} | tr -dc '0-9')
		# echo "The Job status is : $varStatCode"
		
		if [ $varStatCode -eq 1002 ]; then
			echo "!ERROR! : The supplied project name '${varProjectName}' was invalid, no such project found"
			rm -f ${varJobName}_${DATE_WITH_TIME}
			 exit 5
		fi
		
		if [ $varStatCode -gt 2 ]; then
			if [ $varStatCode -ne 21 ]; then
				if [ $varStatCode -eq 1004 ]; then
					centerPrint "The job $varJobName is not compiled, please re-compile and run again"
					exit 2
				fi
			. /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh
			varStatusText=`getJobStatusText $varStatCode`
			echo "The status code is : ${varStatCode}"
			centerPrint "The job $varJobName is in : $varStatusText state, resetting the job before we can run it!"
			eval $varJobResetString 1> /dev/null 2>&1;
			fi
		fi
		
		#If job is in negative status code state, the script needs to exit
		if [ $varStatCode -lt 0 ]; then 
			echo "Unable to run: $varJobName, not a runnable job"
			rm -f ${varJobName}_${DATE_WITH_TIME}
			 exit 2 
		fi
	fi
done < ${varJobName}_${DATE_WITH_TIME}
rm -f ${varJobName}_${DATE_WITH_TIME}

# Now that we have evaluated all possible negative or non-runnable positive job codes
# Lets run the job
centerPrint "Job Run string is:"
echo $varJobRunString
eval $varJobRunString &> ${varJobName}_${DATE_WITH_TIME}

# After we run it, we need to evaluate the outcome of the job
while IFS='' read -r line || [[ -n "$line" ]]; do

	if [[ ${line} == "Job Status"* ]] || [[ ${jobInfoLine} == "Status code"* ]]; then
		varStatusCode=$(echo ${line} | tr -dc '0-9')
		
		# If Job simply finished or abort or crash, report it in email along with the state it stopped in
		if [ $varStatusCode -lt 0 ]; then 
			centerPrint "Unable to run: $varJobName"
			#sh $varUTILSFOLDER/$varSENDEMAILUTIL $varProjectName $varSubjectArea $varStatusCode $varJobName $varNotRunnableMsg
			rm -f ${varJobName}_${DATE_WITH_TIME}
			echo "Unable to run: $varJobName, not a runnable job"
			 exit 3
		fi
		
		[ $varWarningsOk == "YES" ] && varAllowedStatus=2 || varAllowedStatus=1
	
		if [ $varStatusCode -gt $varAllowedStatus ]; then
			# echo "inside not alloed status code" >&2
			#sh $varUTILSFOLDER/$varSENDEMAILUTIL $varProjectName $varSubjectArea $varStatusCode $varJobName
			rm -f ${varJobName}_${DATE_WITH_TIME}
			echo "The job: $varJobName, DID NOT finish cleanly (reply code <> 0)"
			 exit 4
		fi
	fi
	
done < ${varJobName}_${DATE_WITH_TIME}
rm -f ${varJobName}_${DATE_WITH_TIME}

IFS=$SAVEIFS