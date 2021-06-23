#!/bin/bash

# FileName: netezzaassessment.sh
# =================================================================================================================================================
# Scriptname: netezzaassessment.sh
# 
# Change log:
# Created: June 16, 2021
# Author(s): Oscar Zamora
# Group: Appliance Migration Accelerator Program
# 
# =================================================================================================================================================
# Description:
#       Shell script will run all assessment scripts for Netezza, if Linux/Unix is the only available platform
#       This is an an alternative script if powershell is not available to run from Windows, for Netezza platforms
#
# Arguments: 
#   hostname
#   databasename
#   username
#   password
#   [/deletecsv] -- if /deletecsv is not passed, all csv files existing in Results folder will be preserved
#   [Scripts folder] Folder where all scripts are located
#   [Results folder] Folder where all Results will be stored
#
# Requirements: 
# nzsql Netezza Client installed on local machine with driver available
# Capability to provide execution access to this shell script
# Access to the Netezza Appliance for login and running the assessment commands
#
# nzsql parameter reference list: https://www.ibm.com/docs/en/psfa/7.1.0?topic=nzsql-command-line-options
# =================================================================================================================================================
# SCRIPT BODY
# =================================================================================================================================================


# Required Arguments
# $1 = hostname
# $2 = databasename 
# $3 = username
# $4 = password

# Optional Arguments
# $5 = Delete existing CSV output files ("/deletecsv" as parameter)
# $6 = Scripts folder
# $7 = Results folder

# Set Variables
today=$(date +"%Y%m%d%H%M%S")
rootfolder=`pwd`

# Set Variables
Scriptsfolder=$6
Resultsfolder=$7

if [ -z $6 ]
then
    Scriptsfolder="$rootfolder/Scripts/Netezza/"
fi

if [ -z $7 ]
then
    Resultsfolder="$rootfolder/Results"
fi

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ]
then
	echo "Usage: $0 host database username password [/deletecsv] [Scripts folder] [Results folder]"
	echo "if /deletecsv is not passed, all csv files existing in Results folder will be preserved"
	echo "Default Scripts Folder: $Scriptsfolder"
	echo "Default Results Folder: $Resultsfolder"
	exit 1
fi

# Delete contents if specified

# create Results folder if it does not exist
if [ ! -d $Resultsfolder ]
then
  mkdir -p $Resultsfolder
fi

# Delete contents if specied
if [ $5 == '/deletecsv' ]
then
	rm $Resultsfolder/*.csv
fi

# Change directory to Scripts folder
cd $Scriptsfolder

# Create command.nzsql dynamically, iterating through each .sql file
for f in $(ls *.sql); 
do 
     output=`echo "$Resultsfolder/$f""${today}.csv" | sed 's/\.sql/_/'`
	 echo "Generating File: $output"
     nzsql -h $1 -d $2 -u $3 -pw $4 -F',' -r -A -t -f $f -o $output
done;

# Remove header row 2 with dashes
sed -i '/-[^-]*-/d' $Resultsfolder/*.csv
cd $rootfolder

# Check for output contents on the last file generated
if [ ! -d $output ]
then
	echo "Last iteration not found. There might have been an error running the scripts."
	echo "File not found: $output"
fi

# Display folders
echo "Scripts Folder: $Scriptsfolder"
echo "Results Folder: $Resultsfolder"
