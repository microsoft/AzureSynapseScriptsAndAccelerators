#!/bin/bash

# FileName: oracleassessment.sh
# =================================================================================================================================================
# Scriptname: oracleassessment.sh
# 
# Change log:
# Created: June 9, 2021
# Author(s): Oscar Zamora
# Group: Appliance Migration Accelerator Program
# 
# =================================================================================================================================================
# Description:
#       Shell script will run all assessment scripts for Oracle, if Linux/Unix is the only available platform
#       This is an an alternative script if powershell is not available to run from Windows, for Oracle platforms
#
# Arguments: 
#   user/password@instance -- Oracle Username, password and Instance name in tnsnames.ora
#   [/deletecsv] -- if /deletecsv is not passed, all csv files existing in Results folder will be preserved
#   [Scripts folder] Folder where all scripts are located
#   [Results folder] Folder where all Results will be stored
#
# Requirements: 
# Oracle Client installed on local machine with driver available
# Capability to provide execution access to this shell script
# Access to the Oracle Instace for login and running the assessment commands
# =================================================================================================================================================
# SCRIPT BODY
# =================================================================================================================================================


# Required Arguments
# $1 = sqplus connection string. It has to be passed as "user/password@instance"
# Optional Arguments
# $2 = Delete existing CSV output files ("/deletecsv" as parameter)
# $3 = Scripts folder
# $4 = Results folder

# Set Variables
today=$(date +"%Y%m%d%H%M%S")
rootfolder=`pwd`

# Set Variables
Scriptsfolder=$2
Resultsfolder=$3

if [ -z $3 ]
then
    Scriptsfolder="$rootfolder/Scripts/Oracle/"
fi

if [ -z $4 ]
then
    Resultsfolder="$rootfolder/Results"
fi

if [ -z $1 ]
then
	echo "Usage: $0 user/password@instance [/deletecsv] [Scripts folder] [Results folder]"
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
if [ $2 == '/deletecsv' ]
then
	rm $Resultsfolder/*.csv
fi

# Change directory to Scripts folder
cd $Scriptsfolder

# Create command.sqlplus dynamically, iterating through each .sql file
for f in $(ls *.sql); 
do 
     echo "set termout off;" > command.sqlplus
     echo "set arraysize 1000;" >> command.sqlplus
     echo "set rowprefetch 2;" >> command.sqlplus
     echo "set pages 0;" >> command.sqlplus
     echo "set trimspool on;" >> command.sqlplus
     echo "set linesize 32767;" >> command.sqlplus
     echo "set feedback off;" >> command.sqlplus
     echo "set markup csv on;" >> command.sqlplus
     echo "set pagesize 0 embedded on;" >> command.sqlplus
     echo "spool $Resultsfolder/$f""${today}.csv;" | sed 's/\.sql/_/'  >> command.sqlplus
     cat "$f" >> command.sqlplus
     echo "" >> command.sqlplus
     echo "spool off;" >> command.sqlplus
     echo "set termout on;" >> command.sqlplus
     echo "exit;" >> command.sqlplus
	 echo "Generating File: $Resultsfolder/$f""${today}.csv" | sed 's/\.sql/_/'
     sqlplus $1 @command.sqlplus
done;

#Remove command.sqlplus
rm command.sqlplus

# Remove empty lines from generated CSV files
sed -i '/^$/d' $Resultsfolder/*.csv
cd $rootfolder

# Display folders
echo "Scripts Folder: $Scriptsfolder"
echo "Results Folder: $Resultsfolder"
