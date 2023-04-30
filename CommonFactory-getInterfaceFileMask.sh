#!/bin/sh
# Salesforce-OMNI-getInterfaceFileMask.sh
# Author: Adil Baig (baigm01) 
# Creation Date: 2018/04/25
#
# This utility takes the drop location, interfacename and comma seperated "Interfacename|filemask*" format and returns first file match
#
# usage: sh ./Salesforce-OMNI-getInterfaceFileMask.sh <varFilePath> <varInterfaceName> <varFileMaskList>
# e.g. :
# sh ./Salesforce-OMNI-getInterfaceFileMask.sh "/interfaces/salesforce/inbound/" "Product" "Product|sq_SF_ProductFullSet*,InventoryRecon|sq_SF_InventoryFullSet*,InventoryDelta|sq_SF_InventoryDelta*,Shipment|sq_SF_ShipmentFullSet*"

# load the util function file
[ -f /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh ] && . /opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh || exit 255

varFilePath=$1
varInterfaceName=$2
varFileMaskList=$3


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
	if [ ${#varArgCount[@]} -lt 3 ]; then
	   echo 'Aborting Salesforce-OMNI-getInterfaceFileMask.sh - invalid number of arguments'
	   echo 'Arguments should be, in this order: FilePath InterfaceName FileMaskList'
	   printFirstTableLine "where FilePath" "Full path to the location where the SFTP files are dropped"
	   printSecondTableLine "e.g. '/interfaces/salesforce/inbound/'"
	   printFirstTableLine "where InterfaceName" "Name of the interface for which you want to search"
	   printFirstTableLine "where FileMaskList" "comma seperated list of FileMaskList, which holds in each value"
	   printSecondTableLine ", both InterfaceName and corresponding FileMask value"
	   printSecondTableLine "e.g.: Product|sq_ProductFullSet*,InventoryRecon|sq_InventoryFullSet*,InventoryDelta|sq_InventoryDelta*,Shipment|sq_ShipmentFullSet*"
	   echo "returns following exit codes:"
	   printFirstTableLine "return 1" "Incorrect number of arguements supplied"
	   printFirstTableLine "return 2" "No SFTP files with supplied InterfaceName are found"
	   printFirstTableLine "return 255" "!! ERROR !! : couldnt load the common utils function script at: "
	   printSecondTableLine "/opt/IBM/data/utils/CommonFactory-UtilsFunctions.sh"
	   printSecondTableLine "Make sure its available and not deleted"
	    exit 1
	fi
}

printScriptHelpTxt $@

# loop a comma seperated file mask list
for i in $(echo $varFileMaskList | sed "s/,/ /g")
do
	SAVEIFS=$IFS
    IFS='|' read -r -a array <<< "$i"
	varInterfaceNamePart=${array[0]}
	varFileMaskPart=${array[1]}
	
	if [[ ${varInterfaceNamePart} == ${varInterfaceName} ]] 
	then
		cd $varFilePath; 
		if ls $varFilePath/${varFileMaskPart} 1> /dev/null 2>&1; then
			varFirstFileMatch=`ls -t $varFilePath/${varFileMaskPart} | head -1`
			echo "${varFirstFileMatch}" | tr -d '\n'
			 exit
		fi
	fi
	IFS=$SAVEIFS
done

echo "NOFILES" | tr -d '\n'
