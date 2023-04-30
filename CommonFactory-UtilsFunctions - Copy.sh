#!/bin/sh
# CommonFactory-UtilsFunctions.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/05/27
#
# Script that holds all important reusable utility functions


varUTILSFOLDER='/opt/IBM/data/utils/'
varSENDEMAILUTIL='CommonFactory-SendEmail.sh'
DATE_WITH_TIME=`date "+%Y%m%d-%H%M%S" | tr -d '\n'`
cd $varUTILSFOLDER

# while passing "$@" to a function
# it strips their qoutes
# thus if you pass "some variable" "some variable2" to function, thus making it two arguements
# the function recieves it as some variable some variable2 making it incorrectly 4 arguements
# thus needing to requote it
function requote() {
    local res=""
    for x in "${@}" ; do
        # try to figure out if quoting was required for the $x:
        grep -q "[[:space:]]" <<< "$x" && res="${res} '${x}'" || res="${res} '${x}'"
    done
    # remove first space and print:
    sed -e 's/^ //' <<< "${res}"
}

# prints tabulated message used in help desk of a script
# this is for the first line of help text, with parameter name
printFirstTableLine ()
{
	# check if proper number of arguements were passed
	if [ $# -ne 2 ]; then
		echo "Invalid arguement to function printFirstTableLine()"
		echo 'Arguments should be, in this order: ParameterName Desription'
		echo "ParameterName	: Name of the parameter you want to explain"
		echo "Desription	: Short Descripton of parameter with example"
		echo "prints		: ParameterName : Short Descripton in tabulated way as show below"
		echo "sample output if passed correctly"
		printf "%-25s%s\n" "ParameterName1" ": This is the short description of parameter1"
		printf "%-25s%s\n" "ParameterName2" ": This is the short description of parameter2"
		return 1
	fi
	
	printf "%-25s%s\n" "$1" ": ${2}"
}

# prints tabulated message used in help desk of a script
# this is for the second line of help text, without paramter name.
printSecondTableLine ()
{
	if [ $# -ne 1 ]; then
		echo "Invalid arguement to function printSecondTableLine()"
		echo 'Arguments should be, in this order: Desription Continued'
		echo '!NOTE! : This works in conjunction with function printFirstTableLine()'
		echo '!NOTE! : If your description wants to continue to next line for cleaner output in same table format as firstline'
		echo "prints              	: Short Description continue from first line"
		echo "Desription: Short Descripton of parameter with example"
		echo "prints:  				: Short Descripton in tabulated way as show below"
		echo "sample output if passed correctly in conjunction with function printFirstTableLine()"
		printf "%-25s%s\n" "ParameterName1" ": This is the short description of parameter1"
		printf "%26s%s\n" ":" " This is the short description of parameter1 continued into second line"
		return 1
	fi
	
	printf "%26s%s\n" ":" " ${1}"
}

function getStringArraySize()
{
	# check if proper number of arguements were passed
	if [ $# -lt 2 ]; then
		echo "Invalid arguement to function getStringArraySize()"
		echo 'Arguments should be, in this order: StringToCheck Seperator'
		printFirstTableLine "StringToCheck" "string which contains the seperator"
		printSecondTableLine "by which you want to split and get array size of"
		printFirstTableLine "Seperator" "seperator by which you want to split the string"
		printSecondTableLine "and get array size of"
		centerPrint "OUTPUTS"
		printFirstTableLine "numeric" "total array size when supplied 'StringToCheck' is splitted by 'Seperator'"
		centerPrint "returns following exit codes"
		printFirstTableLine "returns 1" "when both the arguments are not supplied to function correctly"
		centerPrint "sample function call:"
		echo 'someVariable=`getStringArraySize "some_string_splitted_by_underscore" _`'
		echo 'value of someVariable = 5'
		return 1
	fi
	
	varStringToCheck=$1
	varSeperator=$2
	#echo "varStringToCheck=${varStringToCheck}"
	#echo "varSeperator=${varSeperator}"
	SAVEIFS=$IFS
	#IFS='${varSeperator}' read -r -a array <<< "${varStringToCheck}"
	IFS=$varSeperator
	array=($varStringToCheck)
	echoWithoutLineBreak ${#array[@]}
	#echo ${#arr[@]}
	# for x in ${!array[@]};
	# do
		# echo "${array[$x]}"
	# done
}

# Get environment string for different hostname
getEnvironment()
{
	varHostName=`hostname | tr -d '\n'`
	# echo $varHostName | tr -d '\n'
	case $varHostName in
	*dapp*					) echo "Dev" | tr -d '\n';;
	*qapp*					) echo "Test" | tr -d '\n';;
	*papp*					) echo "Prod" | tr -d '\n';;
	
	esac
}

varHostName=`getEnvironment`

centerPrint() 
{
	if [ $# -ne 1 ]; then
		echo "Invalid arguement to function centerPrint()"
		echo 'Arguments should be, in this order: stringToPrint'
		printFirstTableLine "where stringToPrint" "What do you want to print at the center of the screen"
		printFirstTableLine "returns" "Corresponding string printed at the center of the console"
		printSecondTableLine "e.g.: ========== some string ============"
		return 1
	fi
	
	varStringToPrint=$1
	termwidth="$(tput cols)"
	padding="$(printf '%0.1s' ={1..70})"
	printf '%*.*s %s %*.*s\n' 0 "$(((termwidth-2-${#1})/2))" "$padding" "${varStringToPrint}" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

echoWithoutLineBreak()
{
	#echo "No of arguement supplied are: " $#
	if [ $# -lt 1 ]; then
		echo "Invalid arguement to function echoWithoutLineBreak()"
		echo 'Arguments should be, in this order: variableToEcho'
		printFirstTableLine "where variableToEcho" "what do you want to echo to console"
		printFirstTableLine "returns" "supplied variable echo'ed without linebreak"
		return 1
	fi
	variableToEcho=$1
	echo $variableToEcho | tr -d '\n';
}

getRunTypeCode()
{
	if [ $# -ne 1 ]; then
		echo "Invalid arguement to function getRunTypeCode()"
		echo 'Arguments should be, in this order: RunTypeName'
		printFirstTableLine "where RunTypeName" "One of the job runtype valid values"
		printSecondTableLine "e.g. 'LookupExtract' or 'Transform'"
		printFirstTableLine "returns" "corresponding stepcode mask"
		printSecondTableLine "e.g. 110 for 'LookupExtract' or 2 for 'Transform'"
		return 1
	fi
	
	case $1 in
	LookupExtract		) echoWithoutLineBreak "110";;
	Extract				) echoWithoutLineBreak "1";;
	Transform			) echoWithoutLineBreak "2";;
	Load				) echoWithoutLineBreak "3";;
	*					) echoWithoutLineBreak "INVALID";;
	esac
}

getJobType()
{
	if [ $# -ne 1 ]; then
		echo "Invalid arguement to function getJobType()"
		echo 'Arguments should be, in this order: JobType'
		printFirstTableLine "where JobType" "Type of job you want to run,"
		printSecondTableLine "allowed only one of the below vb"
		printSecondTableLine "Sequencer | Parallel"
		printFirstTableLine "returns" "'seq' for 'Sequencer' OR 'stg' for 'Parallel'"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal here:"
		printSecondTableLine "http://team.sjm.com/sites/Corp/GIT-EnterpriseInformationManagement/Int%20Service/ETL/Shared%20Documents/EIM-ETL-SD-PD-002388-Standards.docx"
		return 1
	fi
	
	case $1 in
	Sequencer			) echoWithoutLineBreak "seq";;
	Parallel			) echoWithoutLineBreak "stg";;
	*					) echoWithoutLineBreak "INVALID";;
	esac
}

getJobStatusText()
{
	case $1 in
	0		) echo "RUNNING" | tr -d '\n';;
	1		) echo "OK" | tr -d '\n';;
	2		) echo "WARNING" | tr -d '\n';;
	3		) echo "FAILED" | tr -d '\n';;
	4		) echo "QUEUED" | tr -d '\n';;
	11		) echo "VALIDATION OK" | tr -d '\n';;
	12		) echo "VALIDATION WARNING" | tr -d '\n';;
	13		) echo "VALIDATION FAILED" | tr -d '\n';;
	21		) echo "RESET RUN OK" | tr -d '\n';;
	96		) echo "CRASHED" | tr -d '\n';;
	97		) echo "STOPPED BY OPERATOR" | tr -d '\n';;
	98		) echo "JOB NOT COMPILED" | tr -d '\n';;
	100		) echo "INFORMATIONAL" | tr -d '\n';;
	150		) echo "IN PROGRESS" | tr -d '\n';;
	"S"		) echo "STARTED" | tr -d '\n';;
	"C"		) echo "COMPLETED" | tr -d '\n';;
	*		) echo "STATUS CANNOT BE DETERMINED" | tr -d '\n';;
	
	esac
}

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

# Loop through this project's environment's  variable
# returns the value on match
getEnvVarValue()
{
	if [ $# -ne 2 ]; then
		echo "Invalid arguement to function getEnvVarValue()"
		echo 'Arguments should be, in this order: ProjectName EnvVariable'
		printFirstTableLine "ProjectName" "name of the project you are"
		printFirstTableLine "where Desription" "Short Descripton of parameter with example"
		printFirstTableLine "prints" "ParameterName : Short Descripton in tabulated way as show below"
		echo "sample output if passed correctly in conjunction with function printFirstTableLine()"
		printf "%-25s%s\n" "ParameterName1" ": This is the short description of parameter1"
		printf "%26s%s\n" ":" " This is the short description of parameter1 continued into second line"
		return 1
	fi
		
	$DSHOME/bin/dsadmin -listenv ${1} | while read -r line
	do
		SAVEIFS=$IFS
		IFS='=' read -r -a array <<< "$line"
		if [[ "$2" == "${array[0]}" ]]
		then
			case "$2" in
			env_${varSubjectArea}_FAILUREEMAIL					) echo ${array[1]} | tr -d '\n'; return;;
			env_${varSubjectArea}_NOTIFEMAIL					) echo ${array[1]} | tr -d '\n'; return;;
			*													) exit 2;;
			esac
		fi
		IFS=$SAVEIFS
	done
}

patternMatchCSVList()
{
	if [ $# -ne 2 ]; then
		echo "Invalid arguement to function patternMatchCSVList()"
		echo 'Arguments should be, in this order: StringToMatch RegexPatternToMatch'
		printFirstTableLine "where StringToMatch" "The CSV string to match against"
		printSecondTableLine "e.g. 'value1, value2, value3'"
		printFirstTableLine "where RegexPatternToMatch" "The Regular expression to verify it with:"
		printSecondTableLine "It should be one of the following values only"
		printSecondTableLine "DIGITMATCH | ALPHANUMMATCH | ALPHAMATCH"
		echo "It creates following return codes"
		printFirstTableLine "returns 0" "If supplied csv string matches the supplied pattern"
		printFirstTableLine "returns 1" "If supplied csv string DO NOT MATCH the supplied pattern"
		printFirstTableLine "returns 255" "If invalid number of arguements were passed"
		return 255
	fi
	
	passedStr=$1
	csvType=$2
	#shopt -s extglob
	shopt -u extglob
	
	# various regex match string
	local -r DIGITMATCH="(^|,)[[:digit:]]{3}(,|$)"
	local -r ALPHANUMMATCH="(^|,)[[:alnum:]](,|$)"
	local -r ALPHAMATCH="(^|,)[[:alpha:]](,|$)"
	local -r PIPESEPERATED="(^|,)[[:alpha:]]\|[[:alnum:]](,|$)"
	
	if [[ $csvType == "DIGITMATCH" ]]; then
		ALPHABETEXTRACT=`echo $passedStr | tr -dc [[:alpha:]]`
		if [[ $passedStr =~ $DIGITMATCH ]] && [[ -z $ALPHABETEXTRACT ]]; then return 0; else return 1; fi
	fi
	
	echo "INVALID RegexPatternToMatch"; return 1;
}

match_timestamp()
{
	local 
	if [ -z "$1" ]; then
		echo 'Invalid arguement to function match_timestamp()'
		echo 'Arguments should be, in this order: FileName'
		echo "usage: patternMatchSAPFileFormat 'product20180417-221813-112'"
		echo "returns the digit part : 20180417-221813-112"
		 exit 1
	fi	
	local -r line="$1"
	# perform a regular expression match
	[[ "$line" =~ $TIMESTAMP_PATTERN ]] || return # Return if non-matching


	# we have a match, take each match at matched location into 
	# individual date, timestamp element.
	YR="${BASH_REMATCH[2]}"
	MO="${BASH_REMATCH[3]}"
	DM="${BASH_REMATCH[4]}"
	HH="${BASH_REMATCH[5]}"
	MM="${BASH_REMATCH[6]}"
	SS="${BASH_REMATCH[7]}"
	MS="${BASH_REMATCH[8]}"

	if
	  [[ "$YR" ]] && [[ "$MO" ]] && [[ "$DM" ]]
	then
	  # The date is available, we print it
	  varDateTimeStamp="$YR$MO$DM"
	  if
		[[ "$HH" ]] && [[ "$MM" ]]
	  then
		# The time is available, we print it
		varDateTimeStamp="$varDateTimeStamp-$HH$MM"
		if
		  [[ "$SS" ]]
		then
		  # Seconds are available, we print that too
		  varDateTimeStamp="$varDateTimeStamp$SS"
		  if
			[[ "$MS" ]]
		  then
			# Milliseconds Seconds are available, we print that too
			varDateTimeStamp="$varDateTimeStamp-$MS"
			echoWithoutLineBreak $varDateTimeStamp
		  fi
		fi
	  fi
	  echo
	fi

}

patternMatchSAPFileFormat()
{

	if [ -z "$1" ]; then
		echo 'Invalid arguement to function patternMatchSAPFileFormat()'
		echo 'Arguments should be, in this order: FileName'
		echo "usage: patternMatchSAPFileFormat 'product20180417-221813-112.txt'"
		echo "returns the digit part : 20180417-221813-112"
		 exit 1
	fi

	# Constants declared here once, reused in other function (regex patterns)
	local -r PYR="([12][0-9][0-9][0-9])"
	local -r PMO="([01][0-9])"
	local -r PDM="([1-9]|[0-3][0-9])"
	local -r PHH="([0-2][0-9])?"
	local -r PMM="([0-5][0-9])?"
	local -r PSS="([0-5][0-9])?"
	local -r PMS="([0-9][0-9][0-9])?"

	# Pattern for separator between fields (including no separator at all)
	local -r SP="([^0-9a-zA-Z]*)"
	# Pattern for anything but a digit
	local -r NAD="[^0-9]"
	# pattern that matches SAP SFTP file timestamps with flexibility, 
	# assuming format "interfacename-YYMMDD-HHMMSS-MSS.txt"
	local -r TIMESTAMP_PATTERN="(^|$NAD)$PYR$PMO$PDM-$PHH$PMM$PSS-$PMS($NAD|$)"

	match_timestamp "$1"

}

getCountReportEmailBody()
{
	if [ $# -lt 2 ]; then
		echo "Invalid arguement to function getCountReportEmailBody()"
		echo 'Arguments should be, in this order: JobNameMask'
		printFirstTableLine "JobNameMask" "The jobname mask for which you want to get"
		printSecondTableLine "the total vs success vs reject count email of"
		centerPrint "following variables must be set in your calling job before running this"
		printFirstTableLine "RejectFolder" "the full path to the reject folder"
		printSecondTableLine "e.g. RejectFolder='/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printFirstTableLine "ProcessingFolder" "the full path to the ProcessingFolder folder"
		printSecondTableLine "e.g. ProcessingFolder='/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		centerPrint "LOGIC OF THIS FUNCTION"
		echo 'it will find all files starting with "*${JobNameMask}_3*.rej", match its equivalent "*${JobNameMask}_3*.csv" and compare counts'
		echo 'returns a tabulated HTML email body that can be used in sendmail script'
		return 1
	fi
	
	if [ ! -d "$ProcessingFolder" ]; then
		centerPrint "following variables must be set in your calling job before running this"
		printFirstTableLine "RejectFolder" "the full path to the reject folder"
		printSecondTableLine "e.g. RejectFolder='/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printFirstTableLine "ProcessingFolder" "the full path to the ProcessingFolder folder"
		printSecondTableLine "e.g. ProcessingFolder='/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		return 2
	fi

	if [ ! -d "$RejectFolder" ]; then
		centerPrint "following variables must be set in your calling job before running this"
		printFirstTableLine "RejectFolder" "the full path to the reject folder"
		printSecondTableLine "e.g. RejectFolder='/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printFirstTableLine "ProcessingFolder" "the full path to the ProcessingFolder folder"
		printSecondTableLine "e.g. ProcessingFolder='/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		return 3
	fi
	
	SubjectArea=$1
	JobNameMask=$2
	
	local -r varEmailStyleTag="<style>thead {color:blank; align:left; background-color:LIGHTSKYBLUE} tbody {color:black; align:left} p.sideNote { font-style: italic } table, th, td { border: 2px solid black;align: left; } </style>"
	local -r varEmailTableHeaderTag="The <strong>${SubjectArea}_${JobNameMask}</strong> ran successfully, with following counts:<br/><table><thead><tr><th></th><th align='left'><span style='color:blank;'>TOTAL Count<br/>in the file</span></th><th align='left'><span style='color:green;'>SUCCESS count</span></th><th align='left'><span style='color:red;'>REJECT count</span></th></tr></thead><tbody>"
	local -r varEmailBodyTemplate="<tr><td>STEPNAME</td><td>TOTALCOUNT</td><td>SUCCESSCOUNT</td><td>ERRORCOUNT</td></tr>"
	local -r varEmailClosingTag="</tbody></table><p class='sideNote'>NOTE: In the attached reject file:<br/><strong>100* (extraction)</strong> and <strong>200* (transformation)</strong> rejects are due to various checks put in ETL code per the requirement. <br/><strong>300* (load)</strong> rejects are due to the constraints / triggers put at the target table.</p>"
	
	varEmailTemplateString="${varEmailStyleTag}${varEmailTableHeaderTag}"
	find ${RejectFolder} -name "sq_*${JobNameMask}_3*.rej" -type f | sort | ( while read eachFile; do
	
		varHTMLTableBodyTemplate=''
		ErrFileName=$(basename $eachFile)
		UploadFileNameCsv="${ErrFileName%.*}.csv"
		UploadFileNameTxt="${ErrFileName%.*}.txt"
		UploadFileName=""
		if [ -f $UploadFileNameCsv ]; then
			if [ -f $UploadFileNameTxt ]; then
				# there is no csv file for the given reject file, 
				# we cannot reconcile the two counts on this one
				continue
				else
				UploadFileName=$UploadFileNameTxt
			fi
			else
			UploadFileName=$UploadFileNameCsv	
		fi
		
		#echo $UploadFileName
		ErrFileName=${ErrFileName##*_}
		# #### THIS IS THE NAME TO PUT IN STEPNAME
		varFILENAMETemplate="${ErrFileName%.*}"
		errRowCount=`cat ${eachFile} | wc -l | tr -d '\n'`
		# #### THIS IS ERROR FILE COUNT ####
		varERRORCOUNTTemplate=$((errRowCount - 1))
		uploadRowCount=`cat ${ProcessingFolder}/${UploadFileName} | wc -l | tr -d '\n'`
		# #### THIS IS TOTAL COUNT IN UPLOAD FILE ####
		varTOTALCOUNTTemplate=$((uploadRowCount - 1))
		# #### THIS IS SUCCESS COUNT IN UPLOAD FILE ####
		varSUCCESSCOUNTTemplate=$((varTOTALCOUNTTemplate - varERRORCOUNTTemplate))
		#printf "%10s %10s %10s %10s\n" "filename" "TotalCount" "successCount" "failureCount"
		#printf "%10s %10d %10d %10d\n"  $varFILENAMETemplate $varTOTALCOUNTTemplate $varSUCCESSCOUNTTemplate $varERRORCOUNTTemplate
		varHTMLTableBodyTemplate=`echo "${varEmailBodyTemplate/STEPNAME/${varFILENAMETemplate}}" | tr -d '\n'`
		varHTMLTableBodyTemplate=`echo "${varHTMLTableBodyTemplate/TOTALCOUNT/${varTOTALCOUNTTemplate}}" | tr -d '\n'`
		varHTMLTableBodyTemplate=`echo "${varHTMLTableBodyTemplate/SUCCESSCOUNT/${varSUCCESSCOUNTTemplate}}" | tr -d '\n'`
		varHTMLTableBodyTemplate=`echo "${varHTMLTableBodyTemplate/ERRORCOUNT/${varERRORCOUNTTemplate}}" | tr -d '\n'`
		#echo $varHTMLTableBodyTemplate
		varEmailTemplateString="${varEmailTemplateString}${varHTMLTableBodyTemplate}"
		#echo $varEmailTemplateString
	done
	varEmailTemplateString="${varEmailTemplateString}${varEmailClosingTag}";echo $varEmailTemplateString | tr -d '\n' )
	
}

getAllCountReportEmailBody()
{
	if [ $# -lt 2 ]; then
		echo "Invalid arguement to function getAllCountReportEmailBody()"
		echo 'Arguments should be, in this order: SubjectArea JobNameMask'
		printFirstTableLine "SubjectArea" "The subject area for this run"
		printSecondTableLine "For 'CommonFactory' design pattern, and more info on concept of [SUBJECTAREA] and [JOBNAME]"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal."
		printFirstTableLine "JobNameMask" "The jobname mask for which you want to get"
		printSecondTableLine "the total vs success vs reject count email of"
		centerPrint "following variables must be set in your calling job before running this"
		printFirstTableLine "RejectFolder" "the full path to the reject folder"
		printSecondTableLine "e.g. RejectFolder='/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printFirstTableLine "ProcessingFolder" "the full path to the ProcessingFolder folder"
		printSecondTableLine "e.g. ProcessingFolder='/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		centerPrint "LOGIC OF THIS FUNCTION"
		echo 'it will find all files starting with "*${JobNameMask}_3*.rej", match its equivalent "*${JobNameMask}_3*.csv" and compare counts'
		echo 'returns a tabulated HTML email body that can be used in sendmail script'
		return 1
	fi
	
	if [ ! -d "$ProcessingFolder" ]; then
		centerPrint "following variables must be set in your calling job before running this"
		printFirstTableLine "RejectFolder" "the full path to the reject folder"
		printSecondTableLine "e.g. RejectFolder='/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printFirstTableLine "ProcessingFolder" "the full path to the ProcessingFolder folder"
		printSecondTableLine "e.g. ProcessingFolder='/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		return 2
	fi

	if [ ! -d "$RejectFolder" ]; then
		centerPrint "following variables must be set in your calling job before running this"
		printFirstTableLine "RejectFolder" "the full path to the reject folder"
		printSecondTableLine "e.g. RejectFolder='/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printFirstTableLine "ProcessingFolder" "the full path to the ProcessingFolder folder"
		printSecondTableLine "e.g. ProcessingFolder='/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		return 3
	fi
	
	SubjectArea=$1
	JobNameMask=$2
	
	local -r varEmailStyleTag="<style>thead {color:blank; align:left; background-color:LIGHTSKYBLUE} tbody {color:black; align:left} p.sideNote { font-style: italic } table, th, td { border: 2px solid black;align: left; } </style>"
	local -r varEmailTableHeaderTag="The <strong>${SubjectArea}_${JobNameMask}</strong> ran successfully, with following counts between good and rejected files:<br/><table><thead><tr><th></th><th align='left'><span style='color:blank;'>TOTAL INPUT<br/>count to the step</span></th><th align='left'><span style='color:green;'>SUCCESS count</span></th><th align='left'><span style='color:red;'>REJECT count</span></th></tr></thead><tbody>"
	local -r varEmailBodyTemplate="<tr><td>STEPNAME</td><td>TOTALCOUNT</td><td>SUCCESSCOUNT</td><td>ERRORCOUNT</td></tr>"
	local -r varEmailClosingTag="</tbody></table><p class='sideNote'>NOTE: In the attached reject file:<br/>
	<strong>100* (extraction)</strong> and <strong>200* (transformation)</strong> rejects are due to various checks put in ETL code per the requirement. <br/>
	<strong>300* (load)</strong> rejects are due to the constraints / triggers put at the target table.<br/><br/>
	<strong>NOTE on file size:</strong> The attached reject files are shortened 'rowLimited' version of the main files limited to only ${varRowLimiter} rows.<br/>
	For full reject file analysis, please request ETL team.<br/>
	<strong>NOTE on archival history</strong>: ETL team maintains and can only retrieve for you last ${PurgeAfterDays} days of reject data for analysis, per the requirement.<br/><br/></p>
	Thank you,<br/>-ETL Team"
	
	varEmailTemplateString="${varEmailStyleTag}${varEmailTableHeaderTag}"
	find ${RejectFolder} -name "sq_*${JobNameMask}_*.rej" -type f | sort | ( while read eachFile; do
		#echo "*** loop for file ${eachFile} ****"
		varHTMLTableBodyTemplate=''
		ErrFileName=$(basename $eachFile)
		UploadFileNameCsv="${ProcessingFolder}/${ErrFileName%.*}.csv"
		UploadFileNameTxt="${ProcessingFolder}/${ErrFileName%.*}.txt"
		UploadFileName=""
		if [ ! -f $UploadFileNameCsv ]; then
			if [ ! -f $UploadFileNameTxt ]; then
				# there is no csv file for the given reject file, 
				# we cannot reconcile the two counts on this one
				#echo "inside ${UploadFileNameTxt} & ${UploadFileNameCsv} both not exists"
				continue
				else
				#echo "inside ${UploadFileNameTxt} exists"
				UploadFileName=$UploadFileNameTxt
			fi
			else
			UploadFileName=$UploadFileNameCsv	
			#echo "inside ${UploadFileNameCsv} exists"
		fi
		
		#echo $UploadFileName
		# ErrFileName=${ErrFileName##*_}
		# #### THIS IS THE NAME TO PUT IN STEPNAME
		varFILENAMETemplate="${ErrFileName%.*}"
		errRowCount=`cat ${eachFile} | wc -l | tr -d '\n'`
		# #### THIS IS ERROR FILE COUNT ####
		varERRORCOUNTTemplate=$((errRowCount - 1))
		uploadRowCount=`cat ${UploadFileName} | wc -l | tr -d '\n'` # cat ${ProcessingFolder}/${UploadFileName}
		# #### THIS IS TOTAL COUNT IN UPLOAD FILE ####
		varTOTALCOUNTTemplate=$((uploadRowCount - 1))
		# #### THIS IS SUCCESS COUNT IN UPLOAD FILE ####
		varSUCCESSCOUNTTemplate=$((varTOTALCOUNTTemplate - varERRORCOUNTTemplate))
		#printf "%10s %10s %10s %10s\n" "filename" "TotalCount" "successCount" "failureCount"
		#printf "%10s %10d %10d %10d\n"  $varFILENAMETemplate $varTOTALCOUNTTemplate $varSUCCESSCOUNTTemplate $varERRORCOUNTTemplate
		varHTMLTableBodyTemplate=`echo "${varEmailBodyTemplate/STEPNAME/${varFILENAMETemplate}}" | tr -d '\n'`
		varHTMLTableBodyTemplate=`echo "${varHTMLTableBodyTemplate/TOTALCOUNT/${varTOTALCOUNTTemplate}}" | tr -d '\n'`
		varHTMLTableBodyTemplate=`echo "${varHTMLTableBodyTemplate/SUCCESSCOUNT/${varSUCCESSCOUNTTemplate}}" | tr -d '\n'`
		varHTMLTableBodyTemplate=`echo "${varHTMLTableBodyTemplate/ERRORCOUNT/${varERRORCOUNTTemplate}}" | tr -d '\n'`
		#echo $varHTMLTableBodyTemplate
		varEmailTemplateString="${varEmailTemplateString}${varHTMLTableBodyTemplate}"
		#echo $varEmailTemplateString
	done
	varEmailTemplateString="${varEmailTemplateString}${varEmailClosingTag}";echo $varEmailTemplateString | tr -d '\n' )
	
}

getthisJobRejectCountReportEmailBody()
{
	if [ $# -lt 4 ]; then
		echo "Invalid arguement to function getthisJobRejectCountReportEmailBody()"
		echo 'Arguments should be, in this order: SubjectArea JobNameMask StepCode ExactJobName'
		printFirstTableLine "SubjectArea" "The subject area for this run"
		printSecondTableLine "For 'CommonFactory' design pattern, and more info on concept of [SUBJECTAREA] and [JOBNAME]"
		printSecondTableLine "refer to standards document, section 2-2-1 in 'ETL - DataStage' sharepoint portal."
		printFirstTableLine "JobNameMask" "The jobname mask for which you want to get"
		printSecondTableLine "the total vs success vs reject count email of"
		printFirstTableLine "StepCode" "The step code for this run"
		printSecondTableLine "e.g. 103 or 204, etc"
		printFirstTableLine "ExactJobName" "Exact name of the job to check rejects files of"
		printSecondTableLine "e.g.: 'stg_SF_InventoryDelta_204_AccountLookup'"
		centerPrint "following variables must be set in your calling job before running this"
		printFirstTableLine "RejectFolder" "the full path to the reject folder"
		printSecondTableLine "e.g. RejectFolder='/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		centerPrint "LOGIC OF THIS FUNCTION"
		echo 'it will find all files starting with "*${JobNameMask}_3*.rej", and reprot that job failed, attaching the files to them'
		echo 'returns a tabulated HTML email body that can be used in sendmail script'
		return 1
	fi
	
	if [ ! -d "$RejectFolder" ]; then
		centerPrint "following variables must be set in your calling job before running this"
		printFirstTableLine "RejectFolder" "the full path to the reject folder"
		printSecondTableLine "e.g. RejectFolder='/opt/IBM/data/etl/bwadhoc/salesforce/reject'"
		printFirstTableLine "ProcessingFolder" "the full path to the ProcessingFolder folder"
		printSecondTableLine "e.g. ProcessingFolder='/opt/IBM/data/etl/bwadhoc/salesforce/processing'"
		return 2
	fi
	
	SubjectArea=$1
	JobNameMask=$2
	StepCode=$3
	ExactJobName=$4
	
	local -r varEmailStyleTag="<style>thead {color:blank; align:left; background-color:LIGHTSKYBLUE} tbody {color:black; align:left} p.sideNote { font-style: italic } table, th, td { border: 2px solid black;align: left; } </style>"
	local -r varEmailTableHeaderTag="The run: <strong>${SubjectArea}_${JobNameMask}</strong> stopped at the job <strong>${ExactJobName}</strong> with following rejects:<br/><table><thead><tr><th align='left'><span style='color:blank;'>REJECT FILES FOUND:</span></th><th align='left'><span style='color:red;'>REJECT count</span></th></tr></thead><tbody>"
	local -r varEmailBodyTemplate="<tr><td>FILENAME</td><td>ERRORCOUNT</td></tr>"
	local -r varEmailClosingTag="</tbody></table><p class='sideNote'>NOTE: In the attached reject file (and report):<br/>
	<strong>100* rejects(extraction)</strong> are rejects created during extraction of various sources as well as target<br/>
	<strong>200* rejects(Transformation)</strong> are rejects caused during applying transformation rules on the data<br/>
	<strong>300* rejects(Load)</strong> are rejects created by target system during upload of data. <br/><br/>
	<strong>NOTE on file size:</strong> The attached reject files are shortened 'rowLimited' version of the main files limited to only ${varRowLimiter} rows.<br/>
	For full reject file analysis, please request ETL team.<br/>
	<strong>NOTE on archival history</strong>: ETL team maintains and can only retrieve for you last ${PurgeAfterDays} days of reject data for analysis, per the requirement.<br/><br/></p>
	Thank you,<br/>-ETL Team"
	
	varEmailTemplateString="${varEmailStyleTag}${varEmailTableHeaderTag}"
	find ${RejectFolder} -name "sq_*${JobNameMask}_${StepCode}*.rej" -type f | sort | ( while read eachFile; do
		#echo "*** loop for file ${eachFile} ****"
		varHTMLTableBodyTemplate=''
		ErrFileName=$(basename $eachFile)
		
		#echo $UploadFileName
		# ErrFileName=${ErrFileName##*_}
		# #### THIS IS THE NAME TO PUT IN FILENAME
		varFILENAMETemplate="${ErrFileName%.*}"
		errRowCount=`cat ${eachFile} | wc -l | tr -d '\n'`
		# #### THIS IS ERROR FILE COUNT ####
		varERRORCOUNTTemplate=$((errRowCount - 1))
		if (( $varERRORCOUNTTemplate > 1 )); then
			varHTMLTableBodyTemplate=`echo "${varEmailBodyTemplate/FILENAME/${varFILENAMETemplate}}" | tr -d '\n'`
			varHTMLTableBodyTemplate=`echo "${varHTMLTableBodyTemplate/ERRORCOUNT/${varERRORCOUNTTemplate}}" | tr -d '\n'`
			varEmailTemplateString="${varEmailTemplateString}${varHTMLTableBodyTemplate}"
		fi
	done
	varEmailTemplateString="${varEmailTemplateString}${varEmailClosingTag}";echo $varEmailTemplateString | tr -d '\n' )
}

DeleteTemporaryGZipFiles()
{
	cd ${ArchiveFolder}
	find . -name "${SubjectArea}_${JobNameMask}_*Files_*.tar.gz" -exec rm -f {} \;
}

DeleteProcessingFiles()
{
	# step-05B.1 -> remove processsing files
	cd ${ProcessingFolder}
	find ${ProcessingFolder} -name "sq_${JobNameMask}*" -exec rm -f {} \;
}

DeleteRejectFiles()
{
	# step-05B.2 -> remove all reject files
	cd ${RejectFolder}
	find ${RejectFolder} -name "sq_${JobNameMask}*.rej" -exec rm -f {} \;
}

DeleteRejectRowLimitedFiles()
{
	# step-05B.2 -> remove all reject files
	cd ${RejectFolder}
	find ${RejectFolder} -name "sq_${JobNameMask}*rowLimited.rej" -exec rm -f {} \;
}

CreateTempFolders()
{
	mkdir ${ProcessingFolder}/${JobNameMask}_gzipTemp
	mkdir ${ProcessingFolder}/${JobNameMask}_gzipTempDebug
	mkdir ${RejectFolder}/${JobNameMask}_gzipTemp
	mkdir ${RejectFolder}/${JobNameMask}_gzipTempEmail
}

DeleteTempFolders()
{
	rm -rf ${ProcessingFolder}/${JobNameMask}_gzipTemp
	rm -rf ${ProcessingFolder}/${JobNameMask}_gzipTempDebug
	rm -rf ${RejectFolder}/${JobNameMask}_gzipTemp
	rm -rf ${RejectFolder}/${JobNameMask}_gzipTempEmail
}

ArchiveProcessingFiles()
{
	if [ $# -lt 1 ]; then
		echo "Invalid arguement to function ArchiveProcessingFiles()"
		echo 'Arguments should be, in this order: varFileTypes'
		printFirstTableLine "where varFileTypes" "is either 'All' or 'Load'"
		return 1
	fi
	varFileTypes=$1
	varFileMask=""
	[[ ${varFileTypes} == "All" ]] && varFileMask="sq_${JobNameMask}*" || varFileMask="sq_${JobNameMask}_3*"
	find ${ProcessingFolder} -name $varFileMask -type f | while read eachFile; do
		#step -03A - Get Row count of the file greater than 1
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
	
	# echo "== after categorizing  ProcessingFolder/_gzipTemp and  ProcessingFolder/_gzipTempDebug==";read usrInput
}

ArchiveRejectFiles()
{
	varFromWhere=$1
	# step-02A : create '_rowLimited.rej' version of each reject file first.
	find ${RejectFolder} -name "sq_*${JobNameMask}*.rej" -type f | while read eachFile; do
		ErrFileName=$(basename $eachFile)
		ErrFileName="${ErrFileName%.*}"
		varRowLimiter=$((varRowLimiter + 1))
		head -$varRowLimiter $eachFile > ${RejectFolder}/${ErrFileName}_rowLimited.rej
	done

	# echo "== after creating _rowLimited ==";read usrInput
	# step-02B : Now find all reject files and put them either in email notification folder (*_gzipTempEmail)
	# or in main archival folder (*__gzipTemp)
	find ${RejectFolder} -name "sq_*${JobNameMask}*.rej" -type f | while read eachFile; do
		# step -03A - Get Row count of the file greater than 1 AND 
		# file should not be a debug file that are used for ETL analysis only.
		rowCount=`cat ${eachFile} | wc -l | tr -d '\n'`
		fileName=`echoWithoutLineBreak "$eachFile"`
		#echo "at file: $fileName"
		if [ "${rowCount}" -gt "1" ]
		then
			if [[ "${fileName}" == *"_rowLimited"* ]]
			then 
				#echo "== inside: rowLimited reject file file match =="
				cp -f ${eachFile} ${RejectFolder}/${JobNameMask}_gzipTempEmail/
			else
				#echo "== inside: normal reject file file match =="
				cp -f ${eachFile} ${RejectFolder}/${JobNameMask}_gzipTemp/
			fi
		fi
	done
	
	# echo "== after categorizing  RejectFolder/_gzipTempEmail and  RejectFolder/_gzipTemp==";read usrInput
}

ArchiveStepCodeRejectFiles()
{
	varFromWhere=$1
	# step-02A : create '_rowLimited.rej' version of each reject file of this step code job.
	find ${RejectFolder} -name "sq_*${JobNameMask}_${jobNamePart}*.rej" -type f | while read eachFile; do
		ErrFileName=$(basename $eachFile)
		ErrFileName="${ErrFileName%.*}"
		varRowLimiter=$((varRowLimiter + 1))
		head -$varRowLimiter $eachFile > ${RejectFolder}/${ErrFileName}_rowLimited.rej
	done

	# echo "== after creating _rowLimited ==";read usrInput
	# step-02B : Now find all reject files and put them either in email notification folder (*_gzipTempEmail)
	# or in main archival folder (*__gzipTemp)
	find ${RejectFolder} -name "sq_*${JobNameMask}_${jobNamePart}*.rej" -type f | while read eachFile; do
		# step -03A - Get Row count of the file greater than 1 AND 
		# file should not be a debug file that are used for ETL analysis only.
		rowCount=`cat ${eachFile} | wc -l | tr -d '\n'`
		fileName=`echoWithoutLineBreak "$eachFile"`
		#echo "at file: $fileName"
		if [ "${rowCount}" -gt "1" ]
		then
			if [[ "${fileName}" == *"_rowLimited"* ]]
			then 
				#echo "== inside: rowLimited reject file file match =="
				cp -f ${eachFile} ${RejectFolder}/${JobNameMask}_gzipTempEmail/
			else
				#echo "== inside: normal reject file file match =="
				cp -f ${eachFile} ${RejectFolder}/${JobNameMask}_gzipTemp/
			fi
		fi
	done
	
	# echo "== after categorizing  RejectFolder/_gzipTempEmail and  RejectFolder/_gzipTemp==";read usrInput
}