# FileName: PreAssessmentDriver.ps1
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
	Write-Log-File ImportError
}


# Enchanded Logging 
function Display-LogMsg($LogMsg) {
    if ($VerboseLogging -eq "True") { Write-Host  (Get-Date).ToString() $LogMsg -ForegroundColor Green }
	Write-Log-File $LogMsg
}


Function Write-Log-File($logMsg)
{
	Add-Content -Path $LoggingDir -Value $LogMsg
}


Function GetPassword($securePassword)
{
       $securePassword = Read-Host "Password" -AsSecureString
       $P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
       return $P
}


# This one has not been referenced 
Function GetDBVersionStatement($SourceSystem, $csvVersionFileFullPath)
{	
	Display-LogMsg "GetDBVersionStatement: SourceSystem:$SourceSystem"
	Display-LogMsg "GetDBVersionStatement: csvVersionFileFullPath:$csvVersionFileFullPath"

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


#Function GetListQuery ($ListQueries, $Version, $SourceSystem, $RunFor)
Function GetListQuery ($BaseJSON, $Version, $SourceSystem, $RunFor)
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
	if($RunFor -eq 'DB')
		{$ListQueries = ($BaseJSON | Select-Object DBListingQuery).DBListingQuery}
	elseif($RunFor -eq 'TABLE') 
		{$ListQueries = ($BaseJSON | Select-Object TableListingQuery).TableListingQuery}
	elseif($RunFor -eq 'VIEW') 
		{$ListQueries = ($BaseJSON | Select-Object ViewListingQuery).ViewListingQuery}
	elseif($RunFor -eq 'PROCEDURE') 
		{$ListQueries = ($BaseJSON | Select-Object ProcedureListingQuery).ProcedureListingQuery}
	elseif($RunFor -eq 'EXPROCEDURE') 
		{$ListQueries = ($BaseJSON | Select-Object ProcedureExtListingQuery).ProcedureExtListingQuery}
	elseif($RunFor -eq 'MACRO') 
		{$ListQueries = ($BaseJSON | Select-Object MacroListingQuery).MacroListingQuery}
	elseif($RunFor -eq 'FUNCTION') 
		{$ListQueries = ($BaseJSON | Select-Object FunctionListingQuery).FunctionListingQuery}
	elseif($RunFor -eq 'EXFUNCTION') 
		{$ListQueries = ($BaseJSON | Select-Object FunctionExtListingQuery).FunctionExtListingQuery}
	elseif($RunFor -eq 'TRIGGER') 
		{$ListQueries = ($BaseJSON | Select-Object TriggerListingQuery).TriggerListingQuery}
	else
	{
		Display-ErrorMsg "RunFor Type is not valid. $RunFor  Please check your configuration."
		exit (0)
	}

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
				Display-LogMsg "Source System and Version:  $SourceSystem  Version:  $Version " 
				$ListQuery = ($v | Select-Object Query).Query 
				
				Display-LogMsg "ListQuery:$ListQuery"
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


Function GetListToProcessOver($Query, $ServerName, $DSNName, $Database, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem, $Port)
{
	$ResultAs="DataSet"	
	
	$runSQLStementsParams = @{
		ServerName = $ServerName;
		DSNName = $DSNName;
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

		#exit(0)
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


Function WriteQueryToCSV($FileName, $Query, $Variables, $ServerName, $DSNName, $Database, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem, $Port, $AddDatabaseName)
{
	$ResultAs="DataSet"	
	
	$ReturnValues = RunSQLStatement $ServerName $DSNName $Database $Query $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port
	
	if($ReturnValues.Get_Item("Status") -eq 'Success')
	{
		$ds = $ReturnValues.Get_Item("DataSet")
		Display-LogMsg $FileName 
		for ($i = 0; $i -lt $ds.Tables.Count; $i++) {
			$rows = $ds.Tables[$i].Rows.Count
			Display-LogMsg "Looping through Objects:$i - Items:$rows"
            $record = $ds.Tables[$i]
            if ($AddDatabaseName -eq $true) {
                #$record
                $record | Add-Member -NotePropertyName Database -NotePropertyValue $Database
            }

            if ($rows -eq 0) {
                # Add header line in case of empty table
                $headerLine = ""

                if ($AddDatabaseName -eq $true) {
                    $headerLine += """Database"","
                }

                $columnNames = $ds.Tables[$i].Columns | Select -ExpandProperty "ColumnName"
                $columnNamesLine = '"' + ($columnNames -join '","') + '"'
                $headerLine += $columnNamesLine

                # Do not add header line to existing file (it already contains header line)
                if ((Test-Path -Path $FileName) -eq $false) {
                    $headerLine | Out-File -FilePath $FileName -Encoding utf8 -Append
                }
            }
            else {
                $record | Export-Csv "$FileName" -NoTypeInformation -Append -Encoding UTF8 -Delimiter ',' -Force
            }
		}
	}
	else 
	{
		$Errmsg =  "Error Executing SQL Statement: " + $ReturnValues.Get_Item("Msg")
		Display-ErrorMsg -ImportError $Errmsg
	}	
}


Function WriteShowSpaceUsedToCSV($FileName, $Query, $Variables, $ServerName, $DBName, $SchemaNAme, $ObjectName, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem, $Port)
{

	$ResultAs="DataSet"	

	$ReturnValues = RunSQLStatement $ServerName $DSNName $DBName $Query $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port

	$rows = New-Object PSObject 		 
	$rows | Add-Member -MemberType NoteProperty -Name "DataBase" -Value $DBName -force
	$rows | Add-Member -MemberType NoteProperty -Name "SchemaName" -Value $SchemaName -force
	$rows | Add-Member -MemberType NoteProperty -Name "TableName" -Value $ObjectName -force

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
			$rowKey = $DBName + '_' + $SchemaName + '_' + $ObjectName
	
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
		
			$rows | Export-Csv -Path "$FileName" -Append -Delimiter "," -NoTypeInformation -Encoding UTF8
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
		
	if($RunFor.ToUpper() -eq "DB" -or $RunFor.ToUpper() -eq "SERVER")
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
            WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DSNName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
		}
	}
	else 
	{
		
		$Query = $ObjectListQuery #[4].ToString() # This one works if the location in Json file does not change. 
		#$Query = ($ObjectListQuery | Select-Object $Query).Query #Did not work. 

		$Objects = GetListToProcessOver $Query $ServerName $DSNName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port 


		foreach($row in $Objects.Tables[0])
		{
			#Add Variable Statement
			$ObjectName =  $row["Name"]
			$SchemaName =  $row["SchemaName"]
		
			$Variables = "@DBName:$DBName|@ObjectName:$ObjectName|@SchemaName:$SchemaName"

			if($CommandType -eq "SQL")
			{
				WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DSNName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
			}
			elseif($CommandType -eq "DBCC")
			{
				##Need to add the DBCC statement for APS/ADW
				if($SQLStatement.TOUpper() -eq 'PDW_SHOWSPACEUSED')
				{

					$SQLStatement2 = "DBCC PDW_SHOWSPACEUSED (""$SchemaName.$ObjectName"");"

					# Need to figure out how this will work later 
					#$ExternalTable = $row["Is_external"]								
					if ($SourceSystem -eq "SYNAPSE")
					{
						$ExternalTable = $row["Is_external"]
					}
					else
					{
						$ExternalTable = $false
					}

					if($ExternalTable -eq $false)
					{
						WriteShowSpaceUsedToCSV $FileName $SQLStatement2 $Variables $ServerName $DBName $SchemaName $ObjectName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
					}
				}	
			}
		}							
	}
}


Function GetDBEngineEdition($DBEditionQuery, $ServerName, $DSNName, $Port, $Database, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem)
{
	$ResultAs="DataSet"
	
	#Display-LogMsg "VersionQuery:$VersionQuery"

	$ReturnValues = RunSQLStatement $ServerName $DSNName $Database  $DBEditionQuery $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port
	
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


Function GetDBVersion($VersionQueries, $ServerName, $DSNName, $Port, $Database, $Username, $Password, $ConnectionType, $QueryTimeout, $ConnectionTimeout, $SourceSystem, $Type)
{
	#Display-LogMsg "GetDBVersion:: $VersionQueries "
	
	foreach($v in $VersionQueries)
	{
		if(($v | Select-Object System).System -eq $SourceSystem)
		{
			$VersionQuery = ($v | Select-Object Query).Query
			Display-LogMsg "GetDBVersion:: $VersionQuery "
			Break
		}
	}

	If($VersionQuery -eq $null)
	{
		Display-ErrorMsg "No Version Query found for System: $SourceSystem"
		exit
	}
	 
    $ResultAs="DataSet"
	
	Display-LogMsg "VersionQuery:$VersionQuery"

	$ReturnValues = RunSQLStatement $ServerName $DSNName $Database $VersionQuery $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port
	
	#Check for Error
	if($ReturnValues.Get_Item("Status") -eq 'Success')
	{
		$ds = $ReturnValues.Get_Item("DataSet")
		foreach ($row in $ds.Tables[0]) 
		{
			if($Type -eq "VersionNumber")
			{
				$testversion = $row["Version"]
				Display-LogMsg "Raw Version number: ^$testversion^" 
				
				# clean up the version number - remove strings to make simplier for Teradata
				$testversion = $testversion -replace('[^.0-9]','')
				$testversion = $testversion.trim()
		
				If($SourceSystem -eq 'SNOWFLAKE') 
				{
					$VersionValue =  $testversion -match '(\d*\.\d*\.\d*)'
				} 
				else {
					$VersionValue =  $testversion -match '(\d*\.\d*\.\d*\.\d*)'
				}

				#$VersionValue =  $testversion -match '(\d*\.\d*\.\d*\.\d*)'
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

	Display-LogMsg "Version Number: ^$Version^"

	#Need to break out of code here if $verion is not returned.
	return $Version 
}


    $culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $culture


	# Verbose logging : True for more detail, False for minimal logging

	#$VerboseLogging = "True"
	$Version = $null

	# Set default JSON config file. This file will have all configurations needed. One file to have all info. 
	# User can overrite the file full path when prompted. 
	$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
	$PreAssessmentDriverFile_Config_Default = "$ScriptPath\AssessmentDriverFile.json"
	

	$FileCurrentTime = get-date -Format yyyyMMddHHmmss

	# Set and create logging directory
	$LoggingDir = "$ScriptPath\logs\" 
	Create-Directory $LoggingDir
	$LoggingDir = $LoggingDir + "$FileCurrentTime.log"

	Display-LogMsg "Starting the assesement tool"		

	$PreAssessmentConfigFile = "$ScriptPath\AssessmentConfigFile.json"

	#Base Config for Customer Info
	$PreAssessmentConfigJSON = (Get-Content $PreAssessmentConfigFile) -join "`n" | ConvertFrom-Json
	$SourceSystemDefault = $PreAssessmentConfigJSON.SourceSystem
	$ConnectionTypeDefault = $PreAssessmentConfigJSON.ConnectionType
	$ServerNameDefault = $PreAssessmentConfigJSON.ServerName
	$DSNNameDefault = $PreAssessmentConfigJSON.DSNName
	$DBFilter = $PreAssessmentConfigJSON.DBFilter
	$PreAssessmentOutputPath = $PreAssessmentConfigJSON.PreAssessmentOutputPath

	#Open the Default Config Json file
	$BaseJSON = (Get-Content $PreAssessmentDriverFile_Config_Default) -join "`n" | ConvertFrom-Json

	$GeneralConfig = ($BaseJSON | Select-Object General_Config).General_Config 

	foreach($v in $GeneralConfig)
	{
		$PreAssessmentDriverFile = ($v | Select-Object PreAssessmentDriverFile).PreAssessmentDriverFile
		$PreAssessmentScriptPath = ($v | Select-Object PreAssessmentScriptPath).PreAssessmentScriptPath
		$ValidSourceSystems = ($v | Select-Object ValidSourceSystems).ValidSourceSystems
		$QueryTimeout = ($v | Select-Object QueryTimeout).QueryTimeout
		$ConnectionTimeout = ($v | Select-Object ConnectionTimeout).ConnectionTimeout
		$VerboseLogging = ($v | Select-Object VerboseLogging).VerboseLogging
	}
	#($PreAssessmentConfigJSON | Select-Object SourceSystem).SourceSystem


	$SourceSystem = Read-Host -prompt "Enter the name Source System Type to connect to($ValidSourceSystems). Default on Enter: [$SourceSystemDefault]"
	If($ValidSourceSystems -notmatch "(\b$SourceSystem\b)" -and ($SourceSystem -ne "" -or $SourceSystem -ne $null))
	{
	    write-host "Source System Entered does not match one of the supported systems. $ValidSourceSystems"
        exit (0)
	}
	if($SourceSystem -eq "" -or $null -eq $SourceSystem)
	{
			$SourceSystem = $SourceSystemDefault
	}
	elseif($SourceSystem -ne $SourceSystemDefault)
	{
		$PreAssessmentConfigJSON.SourceSystem = $SourceSystem
		$NewJson = $PreAssessmentConfigJSON | ConvertTo-Json
		Set-Content -Path $PreAssessmentConfigFile -Value $NewJson
	}
	
	$DatabaseFilter = Read-Host -prompt "Would you like to filter the Database to Inventory. % = All DBs or dbname,dbname delimited.  Default on Enter: [$DBFilter]"
	If( $DatabaseFilter -ceq $null -or $DatabaseFilter -eq "")
	{
	    $DBFilter = $PreAssessmentConfigJSON.DBFilter
	}
	else 
	{
		$DBFilter = $DatabaseFilter
		$PreAssessmentConfigJSON.DBFilter = $DatabaseFilter
		$NewJson = $PreAssessmentConfigJSON | ConvertTo-Json
		Set-Content -Path $PreAssessmentConfigFile -Value $NewJson
	}
	

	If($SourceSystem -eq 'TERADATA' -or $SourceSystem -eq 'SNOWFLAKE' -or $SourceSystem -eq 'ORACLE' -or $SourceSystem -eq 'DB2')
	{
		$DSNName = Read-Host -prompt "Enter the ODBC DSN Name to connect with(Note: Maybe Case Sens). Default on Enter: [$DSNNameDefault]"
		if($DSNName -ceq "" -or $DSNName -ceq $null)
		{
				$DSNName = $DSNNameDefault
		}
		elseif($DSNName -cne $DSNNameDefault)
		{
			$PreAssessmentConfigJSON.DSNName = $DSNName
			$NewJson = $PreAssessmentConfigJSON | ConvertTo-Json
			Set-Content -Path $PreAssessmentConfigFile -Value $NewJson
		}
	}
	else {
		$ServerName = Read-Host -prompt "Enter the name/ip of the Server to connect to. Default on Enter: [$ServerNameDefault]"
		if($ServerName -eq "" -or $ServerName -eq $null)
		{
				$ServerName = $ServerNameDefault
		}
		elseif($ServerName -ne $ServerNameDefault)
		{
			$PreAssessmentConfigJSON.ServerName = $ServerName
			$NewJson = $PreAssessmentConfigJSON | ConvertTo-Json
			Set-Content -Path $PreAssessmentConfigFile -Value $NewJson
		}
	}

	#$PreAssessmentDriverFile_Config = $PreAssessmentDriverFile_Config_Default
	#$PreAssessmentDriverFile_Config  = Read-Host -prompt "Enter the name of the PreAssessment JSON Config File. Default on Enter: [$PreAssessmentDriverFile_Config_Default]"
	#if($PreAssessmentDriverFile_Config -eq "" -or $PreAssessmentDriverFile_Config -eq $null)
	#	{
	#			$PreAssessmentDriverFile_Config = $PreAssessmentDriverFile_Config_Default
	#	}


	if ($SourceSystem -eq "APS" -or $SourceSystem -eq "SYNAPSE")
	{
		$APSConfig = ($BaseJSON | Select-Object APS).APS
		foreach($v in $APSConfig)
		{
			$DB_Default = ($v | Select-Object Database).Database
			$Port = ($v | Select-Object Port).Port
			$ConnectionMethodSupported = ($v | Select-Object ConnectionMethod).ConnectionMethod
		}
		$APSConfig = ($BaseJSON | Select-Object SYNAPSE).SYNAPSE
		foreach($v in $APSConfig)
		{
			#$DBVersionText = ($v | Select-Object DatabaseVersionName).DatabaseVersionName
			$DBEdition = ($v | Select-Object DatabaseEngineEdition).DatabaseEngineEdition
			$ConnectionMethodSupported = ($v | Select-Object ConnectionMethod).ConnectionMethod
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
			$ConnectionMethodSupported = ($v | Select-Object ConnectionMethod).ConnectionMethod
		}
	}
	
	# Code to Handle Teradata
	if ($SourceSystem -eq "TERADATA")
	{
		$TeradataConfig = ($BaseJSON | Select-Object Teradata).Teradata
		foreach($v in $TeradataConfig)
		{
			$DB_Default = ($v | Select-Object Database).Database
			$Port = ($v | Select-Object Port).Port
			$nzBinaryFolder = ($v | Select-Object nzBinaryFolder).nzBinaryFolder 
			$SchemaExportFolder = ($v | Select-Object SchemaExportFolder).SchemaExportFolder
			$ConnectionMethodSupported = ($v | Select-Object ConnectionMethod).ConnectionMethod
		}
	}


	# Code to Handle SQLServer
	if ($SourceSystem -eq "SQLSERVER")
	{
		$SqlServerConfig = ($BaseJSON | Select-Object Sqlserver).Sqlserver
		foreach($v in $SqlServerConfig)
		{
			$DB_Default = ($v | Select-Object Database).Database
			$Port = ($v | Select-Object Port).Port
			$ConnectionMethodSupported = ($v | Select-Object ConnectionMethod).ConnectionMethod
		}
	}

	# Code to handle Oracle 
	if ($SourceSystem -eq "ORACLE")
	{
		$OracleConfig = ($BaseJSON | Select-Object Oracle).Oracle
		foreach($v in $OracleConfig)
		{
			$DB_Default = ($v | Select-Object Database).Database
			$Port = ($v | Select-Object Port).Port
			$ConnectionMethodSupported = ($v | Select-Object ConnectionMethod).ConnectionMethod
		}
	}

	# Code to handle DB2 
	if ($SourceSystem -eq "DB2")
	{
		$DB2Config = ($BaseJSON | Select-Object DB2).DB2
		foreach($v in $DB2Config)
		{
			$DB_Default = ($v | Select-Object Database).Database
			$Port = ($v | Select-Object Port).Port
			$ConnectionMethodSupported = ($v | Select-Object ConnectionMethod).ConnectionMethod
		}
	}

	#$DB_DefaultAlt = ($BaseJSON | Select-Object DatabaseAlt).DatabaseAlt

	$VersionQueries = ($BaseJSON | Select-Object VersionQuery).VersionQuery 
	$DBListQueries = ($BaseJSON | Select-Object DBListingQuery).DBListingQuery 
	#Andy Isley$ObjectListQueries = ($BaseJSON | Select-Object TableListingQuery).TableListingQuery 

	#Settings for Export
	 
	#$SchemaExportObjects = ($BaseJSON | Select-Object SchemaExportObjects).SchemaExportObjects 
	#$SchemaExportFile = ($BaseJSON | Select-Object SchemaExportFile).SchemaExportFile
	#$DatabasesForSchemaExport = ($BaseJSON | Select-Object DatabasesForSchemaExport).DatabasesForSchemaExport 
	#$PrefixDatabaseNameToSchema = ($BaseJSON | Select-Object PrefixDatabaseNameToSchema).PrefixDatabaseNameToSchema 
	#$CompressTool = ($BaseJSON | Select-Object CompressTool).CompressTool 
	
	$ConnectionType = Read-Host -prompt "How do you want to connect to the DB ($ConnectionMethodSupported). Default on Enter: [$ConnectionTypeDefault]?"
	If($ConnectionMethodSupported -notmatch "(\b$ConnectionType\b)" -and ($ConnectionType -ne "" -or $null -ne $ConnectionType))
	{
		Display-ErrorMsg "Connection Type does not match one of the allowed methods. $ConnectionMethodSupported"
			exit (0)
	}
	if($ConnectionType -eq "" -or $ConnectionType -eq $null)
	{
			$ConnectionType = $ConnectionTypeDefault
	}
	elseif($ConnectionType -ne $ConnectionTypeDefault)
	{
		$PreAssessmentConfigJSON.ConnectionType = $ConnectionType
		$NewJson = $PreAssessmentConfigJSON | ConvertTo-Json
		Set-Content -Path $PreAssessmentConfigFile -Value $NewJson
	}

	#Adds default if nothing is entered
	#if ($null -eq $ConnectionType -or $ConnectionType -eq "") 
	#{  $ConnectionType = "SQLAUTH" }
	#else {
	#	$ConnectionType = $ConnectionType.ToUpper() 
	#}

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

	Display-LogMsg "Loading from JSON config"
	Display-LogMsg "SourceSystem:$SourceSystem"  
	Display-LogMsg "VersionQueries:$VersionQueries"
	Display-LogMsg "StoreInFolders:$StoreInFolders"
	Display-LogMsg "DBListQueries:$DBListQueries"

	$VersionRaw = GetDBVersion -VersionQueries $VersionQueries -ServerName $ServerName -DSNName $DSNName -Port $Port -Database $DB_Default -QueryTimeout $QueryTimeout -ConnectionTimeout $ConnectionTimeOut -UserName $UserName -Password $Password -ConnectionType  $ConnectionType -SourceSystem $SourceSystem -Type "VersionNumber"
	
	Display-LogMsg  "Version is [$VersionRaw]"

	$VersionRaw = $VersionRaw -replace('[^.0-9]','')
	[System.version]$Version = $VersionRaw # [System.version]$VersionRaw 

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
	


	$DBListQuery = GetListQuery -BaseJSON $BaseJSON -ListQueries $DBListQueries -Version $Version -SourceSystem $SourceSystem -RunFor 'DB'

	#Table level
	#Andy Isley $ObjectListQuery = GetListQuery -ListQueries $ObjectListQueries -Version $Version -SourceSystem $SourceSystem

	#Working with relative path
	if ($PreAssessmentDriverFile -contains ":") {
			#Absolute path entered
	}
	else {
		$PreAssessmentDriverFile = "$ScriptPath\Scripts\$SourceSystem\$PreAssessmentDriverFile"
	}

	#Working with relative path
	if ($PreAssessmentOutputPath -contains ":") {
		#Absolute path entered
	}
	else {
		$PreAssessmentOutputPath = "$ScriptPath\$PreAssessmentOutputPath"
	}

	#Working with relative path
	if ($PreAssessmentScriptPath -contains ":") {
		#Absolute path entered
	}
	else {
		$PreAssessmentScriptPath = "$ScriptPath\$PreAssessmentScriptPath"
	}

	if (!(test-path $PreAssessmentOutputPath))
	{
		New-item "$PreAssessmentOutputPath\" -ItemType Dir | Out-Null
	}
		
	Display-LogMsg "PreAssessmentScriptPath:$PreAssessmentScriptPath"
	Display-LogMsg "PreAssessmentOutputPath:$PreAssessmentOutputPath"


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

				Display-LogMsg "Run for.. $RunFor"

				Write-host "Executing the Script $ScriptName .... started at $(get-date -Format yyyy-MM-dd:HH:mm:ss)"

				If($RunFor.ToUpper() -eq "SERVER")
				{
					Display-LogMsg "Server Query: $SQLStatement " 
					WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DSNName $DB_Default $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
				}
				else #if($RunFor.ToUpper() -eq "TABLE" -or $RunFor.ToUpper() -eq "DB") #Andy Isley Adding other objects
				{

					$Query = $DBListQuery #[4].ToString() # This one works if the location in Json file does not change. 

					Display-LogMsg "DB Query: $Query " 

					$Databases = GetListToProcessOver $Query $ServerName $DSNName $DB_Default $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port 

					$FirstDBLoop = $True

					foreach($row in $Databases.Tables[0])
					{
						$DBName =  $row["Name"]
						
						Display-LogMsg "Looping through Databases $DBName  " 

						#if($DBFilter -ne '%')
						#{
						# Filter is designed so we only access a subset of databases
							$splitFilter = $DBFilter.Split(",")
							foreach($val in $splitFilter)
							{
								
								if($DBName.toUpper() -eq $val.Trim().toUpper() -or $DBFilter -eq '%')
								{
									if(($DBToProcess -ne $DBName -and $DBToProcess.toUpper() -ne 'ALL') -and $DBFilter -ne '%')
									{
										continue
									}

									if($SourceSystem -eq 'SYNAPSE')
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


									if($RunFor.ToUpper() -eq "DB" -or $RunFor.ToUpper() -eq "SERVER")
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
                                            $AddDatabaseName = ($RunFor.ToUpper() -eq "DB")
										    WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DSNName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port $AddDatabaseName
										}
									}
									else 
									{
										Display-LogMsg "Looping through objects"
										$Variables = "@DBName:$DBName|@ObjectName"
										#$Query = $ObjectListQuery #[4].ToString() # This one works if the location in Json file does not change. 
										#$Query = ($ObjectListQuery | Select-Object $Query).Query #Did not work. 
								
										
										#Andy Isley$ObjectListQueries = ($BaseJSON | Select-Object TableListingQuery).TableListingQuery 
										$Query = GetListQuery -BaseJSON $BaseJSON -ListQueries $ObjectListQueries -Version $Version -SourceSystem $SourceSystem -RunFor $RunFor
										$Object = GetListToProcessOver $Query $ServerName $DSNName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port 

										foreach($row in $Object.Tables[0])
										{
											
											#Add Variable Statement
											$ObjectName =  $row["Name"]
											$SchemaName =  $row["SchemaName"]
										
											$Variables = "@DBName:$DBName|@ObjectName:$ObjectName|@SchemaName:$SchemaName"

											Display-LogMsg "Looping through $Variables "
											Display-LogMsg "Executing : $SQLStatement"
											Display-LogMsg "Saving to : $FileName"

											if($CommandType -eq "SQL")
											{
												WriteQueryToCSV $FileName $SQLStatement $Variables $ServerName $DSNName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
											}
											elseif($CommandType -eq "SCHEMA")
											{
												
												$oFile =  "$PreAssessmentOutputPath\$FileCurrentTime\SCHEMA\$RunFor\" 
												Create-Directory  $oFile
												$oFile =  "$oFile\$DBName.$ObjectName.sql"
												Display-LogMsg "Saving to : $oFile"
												WriteQueryToCSV $oFile $SQLStatement $Variables $ServerName $DSNName $DBName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port $false
											}
											elseif($CommandType -eq "DBCC")
											{
												##Need to add the DBCC statement for APS/ADW
												if($SQLStatement.TOUpper() -eq 'PDW_SHOWSPACEUSED')
												{

													$SQLStatement2 = "DBCC PDW_SHOWSPACEUSED (""$SchemaName.$ObjectName"");"

													# Need to figure out how this will work later 
													#$ExternalTable = $row["Is_external"]								
													if ($SourceSystem -eq "SYNAPSE")
													{
														$ExternalTable = $row["Is_external"]
													}
													else
													{
														$ExternalTable = $false
													}

													if($ExternalTable -eq $false)
													{
														WriteShowSpaceUsedToCSV $FileName $SQLStatement2 $Variables $ServerName $DBName $SchemaName $ObjectName $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $SourceSystem $Port
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
				Write-host "Executing the Script $ScriptName .... Ended at $(get-date -Format yyyy-MM-dd:HH:mm:ss)"
			}
		}
	}

	Display-LogMsg "Completed."

#}
#Catch # For other exception 
#	 {
#		 Write-Output "Error: "
#	 }

