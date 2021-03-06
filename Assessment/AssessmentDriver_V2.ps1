﻿# FileName: PreAssessmentDriver.ps1
# =================================================================================================================================================
# Scriptname: PreAssessmentDriver.ps1
# 
# Change log:
# Created: July 13, 2017, Open Sourced August 2018 for APS Assessment 
# Updated November 2018, Added Netezza Assessment and Changed Config file to .json in addition to previous .csv file
# Updated December 2020, Added APS assessment scripts
# Author(s): Andy Isley, Gaiye Zhou, Mark Pryce-Maher, Andrey Mirskiy
# Company: 
# 
# =================================================================================================================================================
# Description:
#       Driver to extract data out of a Database(SQL/Netezza) for the purpose to gather info to complete an Assessment 
#       for migrating to another Platform
#
# =================================================================================================================================================


# =================================================================================================================================================
# REVISION HISTORY
# =================================================================================================================================================
# Date: 
# Issue:  Initial Version
# Solution: 
# 
# =================================================================================================================================================

# =================================================================================================================================================
# FUNCTION LISTING
# =================================================================================================================================================
# Function:
# Created:
# Author:
# Arguments:
# =================================================================================================================================================
# Purpose:
#
# =================================================================================================================================================
#
# Notes: 
#
# =================================================================================================================================================
# SCRIPT BODY
# =================================================================================================================================================

function Display-ErrorMsg($ImportError, $ErrorMsg) {
    Write-Host $ImportError  -ForegroundColor Red
}

function Display-LogMsg($LogMsg) {
    if ($VerboseLogging -eq "True") { Write-Host  (Get-Date).ToString() $LogMsg -ForegroundColor Green }
}

Function GetPassword($securePassword)
{
       $securePassword = Read-Host "Password:" -AsSecureString
       $P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
       return $P
}

# This one has not been referenced 
Function GetDBVersionStatement($SourceSystem, $csvVersionFileFullPath)
{	

	$csvVersionFile = Import-Csv $csvVersionFileFullPath

	foreach($VersionStmt in $csvVersionFile)
	{
		$System = $VersionStmt.System
		if($System -eq $SourceSystem) 
		{
			$VersionSQLStatement = $VersionStmt.SQLStatement
			break  # Gail: Why do we need a break statement here? 
		}
		##Need error statement if version statement is not found
		Return $VersionSQLStatement
	}
}

Function GetListQuery ($ListQueries, $Version, $SourceSystem)
{
	#Exit if $SourceSystem is not returned. 
	if($SourceSystem -eq "" -or $SourceSystem -eq $null)
	{
		Display-ErrorMsg "No source system was found."
		exit (0)
	}
	#Exit if $verion is not returned.
	if ($Version -eq "" -or $Version -eq $null)
	{
		Display-ErrorMsg "No version found for Source System.  $SourceSystem"
		exit (0)
	}
	#Exit if $ListQuery is not returned.
	if($ListQueries -eq "" -or $ListQueries -eq $null)
	{
		Display-ErrorMsg "No List Query was found for System. $SourceSystem  Please check your configuration."
		exit (0)
	}
	#Processing input now
	foreach($v in $ListQueries)
	{
		if(($v | Select-Object System).System -eq $SourceSystem)
		{
			if($Version -ge [System.version]($v | Select-Object VersionFrom).VersionFrom -and $Version -le ($v | Select-Object VersionTo).VersionTo)
			{
				Display-LogMsg "Source System and Version: " $SourceSystem " Version: " $Version 
				$ListQuery = ($v | Select-Object Query).Query 
				break
			}
		}
	}

	if ($ListQuery -eq $null) {
        Display-ErrorMsg "No List Query was found for System: $SourceSystem"
        exit (0)
	}

	return $ListQuery 
}

Function GetListToProcessOver($Query, $ServerName, $Database, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem, $Port)
{
	$ResultAs="DataSet"	
	
	$runSQLStementsParams = @{
		ServerName = $ServerName;
		Database=$Database;
		Query=$Query;
		Username=$Username;
		Password=$Password;
		ConnectionType=$ConnectionType;
		QueryTimeout=$QueryTimeout;
		ConnectionTimeout=$ConnectionTimeout;
		InputFile=$InputFile;
		ResultAs=$ResultAs;
		Variables=$Variables;
		SourceSystem=$SourceSystem;
		Port=$Port
	}

	$ReturnValues = RunSQLStatement @runSQLStementsParams

	#$ReturnValues = RunSQLStatement -ServerName $ServerName -Database $Database -Query $Query -Username $Username -Password $Password -ConnectionType $ConnectionType -QueryTimeout $QueryTimeout -ConnectionTimeout $ConnectionTimeout -InputFile $InputFile -ResultAs $ResultAs -Variables $Variables -SourceSystem $SourceSystem -Port $Port
	
	#Check for Error
	if($ReturnValues.Get_Item("Status") -eq 'Success')
	{
		$ds = $ReturnValues.Get_Item("DataSet")
	}
	else {

		Display-ErrorMsg "Error procssing query. GetListToProcessOver(). Exiting "
		Display-ErrorMsg "Query:$Query "

		$theErrorMessage = $ReturnValues.Get_Item("Msg").Exception.Message

		Display-ErrorMsg "Issue with Executing SQL :: $theErrorMessage " 

		exit(0)
	}
	
	return $ds
}

function Create-Directory([string]$dir)
{
	If (!(test-path $dir)) 
	{
		New-Item -ItemType Directory -Force -Path $dir
	}
}

function Get-FileName([string]$uFilename, [string]$PreAssessmentOutputPath) {
    # Store the files in different folders
    if ($StoreInFolders -eq "True") {
        $newDriectory = $PreAssessmentOutputPath + "\" + $FileCurrentTime

        If (!(test-path $newDriectory)) {
            New-Item -ItemType Directory -Force -Path $newDriectory 
        }

        $exportFilename = $newDriectory + "\" + $uFilename + "" + ".csv"
    }
    else {
        $exportFilename = $PreAssessmentOutputPath + "\" + $uFilename + "_" + "$FileCurrentTime.csv"
    }

    Return [string]$exportFilename
    #= Join-Path -Path $PreAssessmentOutputPath -ChildPath New
}
Function WriteQueryToCSV($FileName, $Query, $Variables, $ServerName, $Database, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem, $Port)
{
	$ResultAs="DataSet"	
	
	$ReturnValues = RunSQLStatement $ServerName $Database $Query $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port
	
	if($ReturnValues.Get_Item("Status") -eq 'Success')
	{
		$ds = $ReturnValues.Get_Item("DataSet")
		Display-LogMsg $FileName 
		for ($i = 0; $i -lt $ds.Tables.Count; $i++) {
			$rows = $ds.Tables[$i].Rows.Count
			Display-LogMsg "Looping through Objects:$i - Items:$rows"
			$ds.Tables[$i] | export-csv "$FileName" -notypeinformation -Append
		}
	}
	else 
	{
		$Errmsg =  "Error Executing SQL Statement: " + $ReturnValues.Get_Item("Msg")
		Display-ErrorMsg -ImportError $Errmsg
	}
	
}

Function WriteShowSpaceUsedToCSV($FileName, $Query, $Variables, $ServerName, $DBName, $SchemaNAme, $TableName, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem, $Port)
{

	$ResultAs="DataSet"	

	$ReturnValues = RunSQLStatement $ServerName $DBName $Query $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port

	$rows = New-Object PSObject 		 
	$rows | Add-Member -MemberType NoteProperty -Name "DataBase" -Value $DBName -force
	$rows | Add-Member -MemberType NoteProperty -Name "SchemaName" -Value $SchemaName -force
	$rows | Add-Member -MemberType NoteProperty -Name "TableName" -Value $TableName -force

	if($ReturnValues.Get_Item("Status") -eq 'Success')
	{
		$ds = $ReturnValues.Get_Item("DataSet")

		foreach ($Row in $ds.Tables[0].Rows)
		{
			$numOfRowsInTable = $Row.Item("ROWS")  # number of rows in the table

			
			$reservedSpaceKB = $Row.Item("RESERVED_SPACE")
			$dataSpaceKB = $Row.Item("DATA_SPACE")
			$indexSpaceKB = $Row.Item("INDEX_SPACE")
			$unUsedSpaceKB= $Row.Item("UNUSED_SPACE")

			$reservedSpaceMB = $reservedSpaceKB/1024
			$dataSpaceMB = $dataSpaceKB/1024
			$indexSpaceMB = $indexSpaceKB/1024
			$unUsedSpaceMB = $unUsedSpaceKB/1024

			$reservedSpaceGB = $reservedSpaceMB/1024
			$dataSpaceGB =  $dataSpaceMB/1024
			$indexSpaceGB = $indexSpaceMB/1024
			$unUsedSpaceGB= $unUsedSpaceMB/1024

			$reservedSpaceTB = $reservedSpaceGB/1024
			$dataSpaceTB =  $dataSpaceGB/1024
			$indexSpaceTB = $indexSpaceGB/1024
			$unUsedSpaceTB = $unUsedSpaceGB/1024

			$pdwNodeId = $Row.Item("PDW_NODE_ID")
			$distributionID = $Row.Item("DISTRIBUTION_ID")
			$rowKey = $DBName + '_' + $SchemaName + '_' + $TableName
	
			$rows | Add-Member -MemberType NoteProperty -Name "Rows" -Value $numOfRowsInTable   -force

			
			$rows | Add-Member -MemberType NoteProperty -Name "RESERVED_SPACE_KB" -Value $reservedSpaceKB  -force
			$rows | Add-Member -MemberType NoteProperty -Name "DATA_SPACE_KB" -Value $dataSpaceKB -force
			$rows | Add-Member -MemberType NoteProperty -Name "INDEX_SPACE_KB" -Value $indexSpaceKB -force
			$rows | Add-Member -MemberType NoteProperty -Name "UNUSED_SPACE_KB" -Value $unUsedSpaceKB -force
			
			$rows | Add-Member -MemberType NoteProperty -Name "RESERVED_SPACE_MB" -Value $reservedSpaceMB -force
			$rows | Add-Member -MemberType NoteProperty -Name "DATA_SPACE_MB" -Value $dataSpaceMB -force
			$rows | Add-Member -MemberType NoteProperty -Name "INDEX_SPACE_MB" -Value $indexSpaceMB -force
			$rows | Add-Member -MemberType NoteProperty -Name "UNUSED_SPACE_MB" -Value $unUsedSpaceMB -force
		
			$rows | Add-Member -MemberType NoteProperty -Name "RESERVED_SPACE_GB" -Value $reservedSpaceGB  -force
			$rows | Add-Member -MemberType NoteProperty -Name "DATA_SPACE_GB" -Value $dataSpaceGB -force
			$rows | Add-Member -MemberType NoteProperty -Name "INDEX_SPACE_GB" -Value $indexSpaceGB -force
			$rows | Add-Member -MemberType NoteProperty -Name "UNUSED_SPACE_GB" -Value $unUsedSpaceGB -force
			
			$rows | Add-Member -MemberType NoteProperty -Name "RESERVED_SPACE_TB" -Value $reservedSpaceTB  -force
			$rows | Add-Member -MemberType NoteProperty -Name "DATA_SPACE_TB" -Value $dataSpaceTB -force
			$rows | Add-Member -MemberType NoteProperty -Name "INDEX_SPACE_TB" -Value $indexSpaceTB -force
			$rows | Add-Member -MemberType NoteProperty -Name "UNUSED_SPACE_TB" -Value $unUsedSpaceTB -force


			$rows | Add-Member -MemberType NoteProperty -Name "PDW_NODE_ID" -Value $pdwNodeId -force
			$rows | Add-Member -MemberType NoteProperty -Name "DISTRIBUTION_ID" -Value $distributionID  -force
			$rows | Add-Member -MemberType NoteProperty -Name "ROW_KEY" -Value $rowKey -force
		
			$rows | Export-Csv -Path "$FileName" -Append -Delimiter "," -NoTypeInformation
		}
		Display-LogMsg "Success for Query: DB: ($DBName) Query: $Query "
	}
	else {

		# DBCC PDW_SHOWSPACEUSED Fails for Certain Tables. 
		Display-ErrorMsg "    Did Not Succeed for Query: DB ($DBName) Query: $Query "
	}
}

Function WriteQueryToSchema($FileName, $Variables, $DBName, $FirstDBLoop, $SchemaExportFolder)
{
	$FileName =  $FileName.Split('.')[0] + ".sh"
	
	if($FirstDBLoop)
	{
		Add-Content $FileName "#!/bin/bash"
		Add-Content $FileName ""
		Add-Content $FileName "[ -d $SchemaExportFolder ] ||  mkdir -p  $SchemaExportFolder"
		$FirstDBLoop = $False
	}
	If($FirstDBLoop -eq $False)
	{
		Add-Content $FileName "$nzBinaryFolder/nz_ddl $DBName >> $SchemaExportFolder/$DBName.sql"
	}
}

function ContinueProcess {
		
	if($RunFor.ToUpper() -ne "TABLE")
	{
		if($CommandType -eq "SCRIPTDB" -AND $SourceSystem.ToUpper() -eq 'NETEZZA')
		{
			#Display-LogMsg "$DBName $CommandType $SourceSystem"
			$Variables = "@DBName:$DBName"

			WriteQueryToSchema -Filename $ObjFileName -Variables $Variables -DBName $DBName -FirstDBLoop $FirstDBLoop -SchemaExportFolder $SchemaExportFolder
			$FirstDBLoop = $False
		}
		else
		{
			#Add Variable Statement
		#$Variables = "@DBName:$DBName"
		$Variables = "@DBName:$DBName|@SQLServerName:$ServerName"
		WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
		}
	}
	else 
	{
		$Query = $TableListQuery #[4].ToString() # This one works if the location in Json file does not change. 
		#$Query = ($TableListQuery | Select-Object $Query).Query #Did not work. 

		$Tables = GetListToProcessOver $Query $ServerName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port 


		foreach($row in $Tables.Tables[0])
		{
			#Add Variable Statement
			$TableName =  $row["Name"]
			$SchemaName =  $row["SchemaName"]
		
			$Variables = "@DBName:$DBName|@TableName:$TableName|@SchemaName:$SchemaName"

			if($CommandType -eq "SQL")
			{
				WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
			}
			elseif($CommandType -eq "DBCC")
			{
				##Need to add the DBCC statement for APS/ADW
				if($SQLStatement.TOUpper() -eq 'PDW_SHOWSPACEUSED')
				{

					$SQLStatement2 = "DBCC PDW_SHOWSPACEUSED (""$SchemaName.$TableName"");"

					# Need to figure out how this will work later 
					#$ExternalTable = $row["Is_external"]								
					if ($SourceSystem -eq "AZUREDW")
					{
						$ExternalTable = $row["Is_external"]
					}
					else
					{
						$ExternalTable = $false
					}

					if($ExternalTable -eq $false)
					{
						WriteShowSpaceUsedToCSV $FileName $SQLStatement2 $Variables $ServerName $DBName $SchemaName $TableName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
					}
				}	
			}
		}							
	}
}

Function GetDBEngineEdition($DBEditionQuery, $ServerName, $Port, $Database, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem)
{
	$ResultAs="DataSet"
	
	#Display-LogMsg "VersionQuery:$VersionQuery"

	$ReturnValues = RunSQLStatement $ServerName $Database $DBEditionQuery $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port
	
	#Check for Error
	if($ReturnValues.Get_Item("Status") -eq 'Success')
	{
		$ds = $ReturnValues.Get_Item("DataSet")
		foreach ($row in $ds.Tables[0]) 
		{
			#$VersionText =  $row["Version"] -match '(\d*\.\d*\.\d*\.\d*)'
			$EngineEdition = $row["EngineEdition"]
			
		}
	}
	else 
	{
		$theErrorMessage = $ReturnValues.Get_Item("Msg").Exception.Message

		Display-ErrorMsg "Issue with Executing SQL :: $theErrorMessage " 

		if ($theErrorMessage.Contains("does not exist") -AND $theErrorMessage.Contains("Database")) {
			Display-ErrorMsg "Check the default database: [MASTER_DB/SYSTEM]"
		}
		if ($theErrorMessage.Contains("Timeout expired") -AND $theErrorMessage.Contains("ERROR")) {
			Display-ErrorMsg "Check the IP Address is correct and the server is running."
		}

		if ($theErrorMessage.Contains("A network-related or instance-specific error occurred") -AND $theErrorMessage.Contains("ERROR")) {
			exit(0)
		}
    }
	#Need to break out of code here if $verion is not returned.
	return $EngineEdition 
}
Function GetDBVersion($VersionQueries, $ServerName, $Port, $Database, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem, $Type)
{
	foreach($v in $VersionQueries)
	{
		if(($v | Select-Object System).System -eq $SourceSystem)
		{
			$VersionQuery = ($v | Select-Object Query).Query
			Break
		}
	}

	If($VersionQuery -eq $null)
	{
		Display-ErrorMsg "No Version Query found for System: $SourceSystem"
		exit
	}
	 
    $ResultAs="DataSet"
	
	#Display-LogMsg "VersionQuery:$VersionQuery"

	$ReturnValues = RunSQLStatement $ServerName $Database $VersionQuery $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port
	
	#Check for Error
	if($ReturnValues.Get_Item("Status") -eq 'Success')
	{
		$ds = $ReturnValues.Get_Item("DataSet")
		foreach ($row in $ds.Tables[0]) 
		{
			if($Type -eq "VersionNumber")
			{
				$testversion = $row["Version"]
				$VersionValue =  $row["Version"] -match '(\d*\.\d*\.\d*\.\d*)'
				$Version = $Matches[0]
			}
			else 
			{
				#$VersionText =  $row["Version"] -match '(\d*\.\d*\.\d*\.\d*)'
				$Version = $row["Version"]
			}
		}
	}
	else 
	{
		$theErrorMessage = $ReturnValues.Get_Item("Msg").Exception.Message

		Display-ErrorMsg "Issue with Executing SQL :: $theErrorMessage " 

		if ($theErrorMessage.Contains("does not exist") -AND $theErrorMessage.Contains("Database")) {
			Display-ErrorMsg "Check the default database: [MASTER_DB/SYSTEM]"
		}
		if ($theErrorMessage.Contains("Timeout expired") -AND $theErrorMessage.Contains("ERROR")) {
			Display-ErrorMsg "Check the IP Address is correct and the server is running."
		}

		if ($theErrorMessage.Contains("A network-related or instance-specific error occurred") -AND $theErrorMessage.Contains("ERROR")) {
			exit(0)
		}
    }
	#Need to break out of code here if $verion is not returned.
	return $Version 
}

	$VerboseLogging = "True"
	$Version = ""

	Display-LogMsg "Starting the assesement tool"		
	# Set default JSON config file. This file will have all configurations needed. One file to have all info. 
	# User can overrite the file full path when prompted. 
	$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
	$PreAssessmentDriverFile_Config_Default = "$ScriptPath\AssessmentDriverFile.json"

	$PreAssessmentDriverFile_Config = Read-Host -prompt "Enter the name of the PreAssessment JSON Config File. Default on Enter: [$PreAssessmentDriverFile_Config_Default]"
	if($PreAssessmentDriverFile_Config -eq "" -or $PreAssessmentDriverFile_Config -eq $null)
		{
				$PreAssessmentDriverFile_Config = $PreAssessmentDriverFile_Config_Default
		}

	$BaseJSON = (Get-Content $PreAssessmentDriverFile_Config) -join "`n" | ConvertFrom-Json

	$GeneralConfig = ($BaseJSON | Select-Object General_Config).General_Config 

	foreach($v in $GeneralConfig)
	{
		$SourceSystem = ($v | Select-Object SourceSystem).SourceSystem
		$PreAssessmentDriverFile = ($v | Select-Object PreAssessmentDriverFile).PreAssessmentDriverFile
		$PreAssessmentOutputPath = ($v | Select-Object PreAssessmentOutputPath).PreAssessmentOutputPath
		$PreAssessmentScriptPath = ($v | Select-Object PreAssessmentScriptPath).PreAssessmentScriptPath
		$ServerName = ($v | Select-Object ServerName).ServerName
		$DBFilter = ($v | Select-Object DBFilter).DBFilter
		$QueryTimeout = ($v | Select-Object QueryTimeout).QueryTimeout
		$ConnectionTimeout = ($v | Select-Object ConnectionTimeout).ConnectionTimeout
	}

	if ($SourceSystem -eq "APS" -or $SourceSystem -eq "AZUREDW")
	{
		$APSConfig = ($BaseJSON | Select-Object APS).APS
		foreach($v in $APSConfig)
		{
			$DB_Default = ($v | Select-Object Database).Database
			$Port = ($v | Select-Object Port).Port
		}
		$APSConfig = ($BaseJSON | Select-Object AZUREDW).AZUREDW
		foreach($v in $APSConfig)
		{
			#$DBVersionText = ($v | Select-Object DatabaseVersionName).DatabaseVersionName
			$DBEdition = ($v | Select-Object DatabaseEngineEdition).DatabaseEngineEdition
		}
	}

	if ($SourceSystem -eq "NETEZZA")
	{
		$NetezzaConfig = ($BaseJSON | Select-Object Netezza).Netezza
		foreach($v in $NetezzaConfig)
		{
			$DB_Default = ($v | Select-Object Database).Database
			$Port = ($v | Select-Object Port).Port
			$nzBinaryFolder = ($v | Select-Object nzBinaryFolder).nzBinaryFolder 
			$SchemaExportFolder = ($v | Select-Object SchemaExportFolder).SchemaExportFolder
		}
	}
	
	#$DB_DefaultAlt = ($BaseJSON | Select-Object DatabaseAlt).DatabaseAlt

	$VersionQueries = ($BaseJSON | Select-Object VersionQuery).VersionQuery 
	$DBListQueries = ($BaseJSON | Select-Object DBListingQuery).DBListingQuery 
	$TableListQueries = ($BaseJSON | Select-Object TableListingQuery).TableListingQuery 

	#$StoreInFolders = ($BaseJSON | Select-Object StoreOutputInSeperateFolders).StoreOutputInSeperateFolders 
	$FileCurrentTime = get-date -Format yyyyMMddHHmmss

	#Settings for Export
	 
	#$SchemaExportObjects = ($BaseJSON | Select-Object SchemaExportObjects).SchemaExportObjects 
	#$SchemaExportFile = ($BaseJSON | Select-Object SchemaExportFile).SchemaExportFile
	#$DatabasesForSchemaExport = ($BaseJSON | Select-Object DatabasesForSchemaExport).DatabasesForSchemaExport 
	#$PrefixDatabaseNameToSchema = ($BaseJSON | Select-Object PrefixDatabaseNameToSchema).PrefixDatabaseNameToSchema 
	#$CompressTool = ($BaseJSON | Select-Object CompressTool).CompressTool 
	

	$ConnectionType = Read-Host -prompt "How do you want to connect to the DB (ADPass, AzureADInt, WinInt, SQLAuth)?"
	
	#Adds default if nothing is entered
	if ($null -eq $ConnectionType -or $ConnectionType -eq "") 
	{  $ConnectionType = "SQLAUTH" }
	else {
		$ConnectionType = $ConnectionType.ToUpper() 
	}

	If($ConnectionType.ToUpper() -eq "SQLAUTH" -or $ConnectionType.ToUpper() -eq "ADPASS")
	{
		$UserName = Read-Host -prompt "$ConnectionType Method used. Please Enter the UserName"
		if(($UserName -eq "") -or ($UserName -eq $null)) 
		{
			$UserName = "sqladmin"
			Display-LogMsg ("User sqladmin is used")
		}
		$Password = GetPassword
		if(($Password -eq "") -or ($Password -eq $null)) 
		{
			Display-ErrorMsg "A password must be entered"
			exit (0)
		}
	}


	$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
	. "$ScriptPath\RunSQLStatement.ps1"


	$VersionRaw = GetDBVersion -VersionQueries $VersionQueries -ServerName $ServerName -Port $Port -Database $DB_Default -QueryTimeout $QueryTimeout -ConnectionTimeout $ConnectionTimeOut -UserName $UserName -Password $Password -ConnectionType  $ConnectionType -SourceSystem $SourceSystem -Type "VersionNumber"
	$Version = [System.version]$VersionRaw
	<# if ($Version -eq $null -or $Version -eq "" ) {		
		
		#Check the version with the alternate system database
		$Version = GetDBVersion -VersionQueries $VersionQueries -ServerName $ServerName -Database $DB_DefaultAlt -QueryTimeout $QueryTimeout -ConnectionTimeout $ConnectionTimeOut -UserName $UserName -Password $Password -ConnectionType $ConnectionType -SourceSystem $SourceSystem -Port $Port
	#>
	if ($Version -eq $null -or $Version -eq "" ) {	
		Display-ErrorMsg "There was a problem getting version from $SourceSystem, please check connection to database."
		exit(0)
	}
		<# else {
			Display-LogMsg "Switching Default database to be $DB_DefaultAlt"
			$DB_Default = $DB_DefaultAlt
		} #>
	#}
	
	Display-LogMsg  "Version is [$Version]"

	$DBListQuery = GetListQuery -ListQueries $DBListQueries -Version $Version -SourceSystem $SourceSystem

	$TableListQuery = GetListQuery -ListQueries $TableListQueries -Version $Version -SourceSystem $SourceSystem

	if (!(test-path $PreAssessmentOutputPath))
		{
			New-item "$PreAssessmentOutputPath\" -ItemType Dir | Out-Null
		}

	Display-LogMsg " PreAssessmentDriverFile is: $PreAssessmentDriverFile" 
	Display-LogMsg "   Processing ..." 

	$csvFile = Import-Csv $PreAssessmentDriverFile
	
	# This is to calcualte how many tables were successful for the Space Used Query 
	$spacedUsedSuccess = 0
	$spacedUsedError = 0

	ForEach ($ScriptToRun in $csvFile ) 
	{
		$Active = $ScriptToRun.Active

		if($Active -eq '1') 
		{

			if($Version -ge $ScriptToRun.VersionFrom -and $Version -le $ScriptToRun.VersionTo -and $SourceSystem -eq $ScriptToRun.SourceSystem)
			{

				$RunFor = $ScriptToRun.RunFor
				$CommandType = $ScriptToRun.CommandType
				$ExportFileName = $ScriptToRun.ExportFileName
				$ScriptName = $ScriptToRun.ScriptName
				#$SQLStatement = $ScriptToRun.SQLStatement
				$DBToProcess = $ScriptToRun.DB

				$ScriptFile = $PreAssessmentScriptPath + $ScriptName
				$SQLStatement = Get-Content -Path $ScriptFile -Raw

				$ObjFileName = Get-FileName $ExportFileName $PreAssessmentOutputPath

				ForEach($fname in $ObjFileName )
				{
					$FileName = $fname
				}

				If($RunFor.ToUpper() -eq "SERVER")
				{
					#Write-Output "Server" 
					WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DB_Default $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
				}
				elseif($RunFor.ToUpper() -eq "TABLE" -or $RunFor.ToUpper() -eq "DB") 
				{

					$Query = $DBListQuery #[4].ToString() # This one works if the location in Json file does not change. 

					$Databases = GetListToProcessOver $Query $ServerName $DB_Default $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port 

					$FirstDBLoop = $True

					foreach($row in $Databases.Tables[0])
					{
						$DBName =  $row["Name"]
							
						#if($DBFilter -ne '%')
						#{
							$splitFilter = $DBFilter.Split(",")
							foreach($val in $splitFilter)
							{
								if($DBName.toUpper() -eq $val.Trim().toUpper() -or $DBFilter -eq '%')
								{
									if(($DBToProcess -ne $DBName -and $DBToProcess.toUpper() -ne 'ALL') -and $DBFilter -ne '%')
									{
										continue
									}

									if($SourceSystem -eq 'AZUREDW')
									{
										$DBEditionQuery = ($v | Select-Object DatabaseEngineEditionQuery).DatabaseEngineEditionQuery
										$DBEngineEdition = GetDBEngineEdition -DBEditionQuery $DBEditionQuery -ServerName $ServerName -Port $Port -Database $DBName -QueryTimeout $QueryTimeout -ConnectionTimeout $ConnectionTimeOut -UserName $UserName -Password $Password -ConnectionType  $ConnectionType -SourceSystem $SourceSystem
										#$DBVersion = GetDBVersion -VersionQueries $VersionQueries -ServerName $ServerName -Port $Port -Database $DBName -QueryTimeout $QueryTimeout -ConnectionTimeout $ConnectionTimeOut -UserName $UserName -Password $Password -ConnectionType  $ConnectionType -SourceSystem $SourceSystem -Type "VersionText"
										#if($DBVersion -notmatch $DBVersionText)
										if($DBEngineEdition -ne $DBEdition)
										{
											Write-host "DB $DBName is not an Azure Synapse SQL Pool Database: Skipping DB"
											continue
										}
										#Write-Host $DBVersion
									}


									if($RunFor.ToUpper() -ne "TABLE")
									{
										if($CommandType -eq "SCRIPTDB" -AND $SourceSystem.ToUpper() -eq 'NETEZZA')
										{
											#Display-LogMsg "$DBName $CommandType $SourceSystem"
											$Variables = "@DBName:$DBName"
				
											WriteQueryToSchema -Filename $ObjFileName -Variables $Variables -DBName $DBName -FirstDBLoop $FirstDBLoop -SchemaExportFolder $SchemaExportFolder
											$FirstDBLoop = $False
										}
										else
										{
											#Add Variable Statement
										    #$Variables = "@DBName:$DBName"
										    $Variables = "@DBName:$DBName|@SQLServerName:$ServerName"
										    WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
										}
									}
									else 
									{
										$Query = $TableListQuery #[4].ToString() # This one works if the location in Json file does not change. 
										#$Query = ($TableListQuery | Select-Object $Query).Query #Did not work. 
								
										$Tables = GetListToProcessOver $Query $ServerName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port 


										foreach($row in $Tables.Tables[0])
										{
											#Add Variable Statement
											$TableName =  $row["Name"]
											$SchemaName =  $row["SchemaName"]
										
											$Variables = "@DBName:$DBName|@TableName:$TableName|@SchemaName:$SchemaName"

											if($CommandType -eq "SQL")
											{
												WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
											}
											elseif($CommandType -eq "DBCC")
											{
												##Need to add the DBCC statement for APS/ADW
												if($SQLStatement.TOUpper() -eq 'PDW_SHOWSPACEUSED')
												{

													$SQLStatement2 = "DBCC PDW_SHOWSPACEUSED (""$SchemaName.$TableName"");"

													# Need to figure out how this will work later 
													#$ExternalTable = $row["Is_external"]								
													if ($SourceSystem -eq "AZUREDW")
													{
														$ExternalTable = $row["Is_external"]
													}
													else
													{
														$ExternalTable = $false
													}

													if($ExternalTable -eq $false)
													{
														WriteShowSpaceUsedToCSV $FileName $SQLStatement2 $Variables $ServerName $DBName $SchemaName $TableName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
													}
												}	
											}
										}							
									} 
								}

							}

					#	}

					}
					
				}
			}
		}
	}

	Display-LogMsg "Completed."

#}
#Catch # For other exception 
#	 {
#		 Write-Output "Error: "
#	 }

