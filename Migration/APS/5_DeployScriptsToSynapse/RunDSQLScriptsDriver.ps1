#
# RunDSQLScriptsDriver.ps1
#
# FileName: RunDSQLScriptsDriver.ps1
# =================================================================================================================================================
# Scriptname: RunDSQLScriptsDriver.ps1
# 
# Change log:
# Created: Jan 24, 2017
# Updated: May, 2021
# Author: Andy Isley, Andrey Mirskiy
# Company: 
# 
# =================================================================================================================================================
# Description:
#       Driver run a .sql or .dsql script against a SQL/Synapse/APS Server
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

function Display-ErrorMsg($ImportError, $ErrorMsg)
{
	Write-Host $ImportError
}

Function GetPassword($securePassword)
{
       $securePassword = Read-Host "PDW Password" -AsSecureString
       $P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
       return $P
}

Function GetDropStatement
{ [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$false)] [string]$SchemaName, 
    [Parameter(Position=1, Mandatory=$true)] [string]$ObjectName,
    [Parameter(Position=2, Mandatory=$false)] [string]$ParentObjectName,
    [Parameter(Position=3, Mandatory=$true)] [string]$ObjectType
    ) 

    if($ObjectType.TOUpper() -eq "TABLE")
    {
		$Query = "If Exists(Select 1 From sys.tables t Where t.type='U' AND t.name = '" + $ObjectName + "' and schema_name(schema_id) = '" + $SchemaName + "') DROP TABLE [" + $SchemaName + "].[" + $ObjectName + "]"
    }
    elseif($ObjectType.TOUpper() -eq "VIEW")
    {
        $Query = "IF EXISTS (SELECT 1 FROM sys.views t WHERE t.type='V' AND t.name = '" + $ObjectName + "' AND SCHEMA_NAME(schema_id) = '" + $SchemaName + "') DROP VIEW [" + $SchemaName + "].[" + $ObjectName + "]"
    }
    elseif($ObjectType.TOUpper() -eq "SP")
    {
        $Query = "IF EXISTS (SELECT 1 FROM sys.objects t WHERE t.type = 'P' AND t.name = '" + $ObjectName + "' AND SCHEMA_NAME(schema_id) = '" + $SchemaName + "') DROP PROC [" + $SchemaName + "].[" + $ObjectName + "]"
    }
    elseif($ObjectType.TOUpper() -eq "SCHEMA")
    {
        $Query = "IF EXISTS (SELECT 1 FROM sys.schemas t WHERE t.name = '" + $ObjectName + "' AND SCHEMA_NAME(schema_id) = '" + $SchemaName + "') DROP SCHEMA [" + $SchemaName + "]"       
	}
	elseif($ObjectType.TOUpper() -eq "EXT")
    {
        $Query = "IF EXISTS (SELECT 1 FROM sys.Objects t WHERE t.name = '" + $ObjectName + "' AND SCHEMA_NAME(schema_id) = '" + $SchemaName + "') DROP EXTERNAL TABLE [" + $SchemaName + "].[" + $ObjectName + "]"    
	}
	elseif($ObjectType.TOUpper() -eq "FUNCTION")
    {
        $Query = "IF EXISTS (SELECT 1 FROM sys.Objects t WHERE t.type = 'FN' AND t.name = '" + $ObjectName + "' AND SCHEMA_NAME(schema_id) = '" + $SchemaName + "') DROP EXTERNAL TABLE [" + $SchemaName + "].[" + $ObjectName + "]"    
	}
	elseif($ObjectType.TOUpper() -eq "USER")
	{
		$Query = "IF EXISTS (SELECT 1 FROM sys.database_principals u WHERE u.is_fixed_role<>1 AND u.principal_id<>0 AND u.type_desc = 'SQL_USER' AND u.name = '" + $ObjectName + "')  DROP USER [" + $ObjectName + "]"
	}
	elseif($ObjectType.TOUpper() -eq "ROLE")
	{
		$Query = "IF EXISTS (SELECT 1 FROM sys.database_principals u WHERE u.is_fixed_role<>1 AND u.principal_id<>0 AND u.type_desc = 'ROLE' AND u.name = '" + $ObjectName + "')  DROP USER [" + $ObjectName + "]"
	}
	elseif($ObjectType.TOUpper() -eq "INDEX")
	{
		$Query = "IF EXISTS (SELECT 1 FROM sys.indexes t WHERE t.name = '" + $ObjectName + "' and object_id('" + $ParentObjectName + "')=t.object_id) DROP INDEX [" + $ObjectName + "] ON " + $ParentObjectName
	}
	elseif($ObjectType.TOUpper() -eq "STATISTIC")
	{
		$Query = "IF EXISTS (SELECT 1 FROM sys.stats t WHERE t.name = '" + $ObjectName + "' and object_id('" + $ParentObjectName + "')=t.object_id) DROP STATISTICS " + $ParentObjectName + ".[" + $ObjectName + "]"
	}
	else 
    {
        $Query = ""
    }

	return $Query
}


Function GetSchemaStatement
{ [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$SchemaName, 
        [Parameter(Position=1, Mandatory=$false)] [string]$SchemaAuth
    ) 

	$Query = "IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name]='$SchemaName')
        EXEC('CREATE SCHEMA [$SchemaName]"

    If ($SchemaAuth -ne "")
    {
        $Query += " AUTHORIZATION [" +  $SchemaAuth + "]"
    }
    $Query += "')"
	
	return $Query
}

Function GetTruncateStatement
{ [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$false)] [string]$SchemaName, 
    [Parameter(Position=1, Mandatory=$true)] [string]$ObjectName,
    [Parameter(Position=2, Mandatory=$true)] [string]$ObjectType
    ) 

    if($ObjectType.TOUpper() -eq "TABLE")
    {
		$Query = "IF EXISTS (SELECT 1 FROM sys.tables t WHERE t.name = '" + $ObjectName + "' AND SCHEMA_NAME(schema_id) = '" + $SchemaName + "') TRUNCATE TABLE [" + $SchemaName + "].[" + $ObjectName + "]"
    }
    elseif($ObjectType.TOUpper() -eq "EXT")
    {
		$Query = "IF EXISTS (SELECT 1 FROM sys.tables t WHERE t.name = '" + $ObjectName + "' AND SCHEMA_NAME(schema_id) = '" + $SchemaName + "') TRUNCATE TABLE [" + $SchemaName + "].[" + $ObjectName + "]"
    }
 	else 
    {
        $Query = ""
    }

	return $Query
}

$ReturnValues = @{}


$error.Clear()

##############################################################
# Config File Input 
#############################################################


$defaultScriptsToRunDriverFile = $PSScriptRoot+"\SynapseImportData.csv"

$ScriptsToRunDriverFile = Read-Host -prompt "Enter the name of the ScriptToRun csv File or Press 'Enter' to accept default [$defaultScriptsToRunDriverFile]"
	if($ScriptsToRunDriverFile -eq "" -or $ScriptsToRunDriverFile -eq $null)
	{$ScriptsToRunDriverFile = $defaultScriptsToRunDriverFile}

$ConnectToSynapse = Read-Host -prompt "How do you want to connect to server (ADPass, ADInt, WinInt, SQLAuth)?"
	#if($ConnectToSynapse.ToUpper() -ne "YES") 
	#{$UseIntegrated = Read-Host -prompt "Enter Yes to connect with integrated Security."
	#	if($UseIntegrated.ToUpper() -eq "" -or $UseIntegrated -eq $null) {$UseIntegrated = "YES"}
	#}
$ConnectToSynapse = $ConnectToSynapse.ToUpper()
If($ConnectToSynapse.ToUpper() -eq "SQLAUTH" -or $ConnectToSynapse.ToUpper() -eq "ADPASS")
{
	$UserName = Read-Host -prompt "Enter the UserName if not using Integrated"
		if($UserName -eq "" -or $UserName -eq $null) {$UserName = "sqladmin"}
	$Password = GetPassword
		if($Password -eq "") {Write-Host "A password must be entered"
							break}
}
$StatusLogPath = Read-Host -prompt "Enter the name of the Output File Directory or Press 'Enter' to accept default [$PSScriptRoot]"
	if($StatusLogPath -eq "" -or $StatusLogPath -eq $null) {$StatusLogPath =  $PSScriptRoot}
$StatusLog = Read-Host -prompt "Enter the name of the status file or Press 'Enter' to accept default"
	if($StatusLog -eq "" -or $StatusLog -eq $null) {$StatusLog = (Get-Date -Format yyyyMMddTHHmmss) + ".log"}


Import-Module "$PSScriptRoot\RunSQLScriptFile.ps1" -Force

if (!(Test-Path $StatusLogPath))
	{
		New-item "$StatusLogPath\" -ItemType Dir | Out-Null
	}

$StatusLogFile = $StatusLogPath + "\" + $StatusLog 

#Try{
$csvFile = Import-Csv $ScriptsToRunDriverFile
#}
#Catch [System.IO.DirectoryNotFoundException]{
#	Display-ErrorMsg("Unable to import PreAssessment csv File: " + $APSPreAssessmentDriverFile)
#}

#Get the header Row
$HeaderRow = "Active","ServerName","DatabaseName","FilePath","CreateSchema","SchemaAuth","ObjectType","ObjectName","FileName","DropTruncateIfExists","SchemaName","Variables","Status","RunDurationSec"
$HeaderRow  -join ","  >> $StatusLogFile

$startTime = Get-Date

ForEach ($S in $csvFile ) 
{
    $StartDate=(Get-Date)
	$Active = $S.Active
	$RunStatement = 1
    if($Active -eq '1') 
	{
        $ServerName = $S.ServerName
		$DatabaseName = $S.DatabaseName
		$FilePath = $S.FilePath
		$FileName = $S.FileName
		$DropTruncateIfExists = $S.DropTruncateIfExists.TOUpper()
		$SchemaName = $S.SchemaName
		$ObjectName = $S.ObjectName
        $ParentObjectName = $S.ParentObjectName
        $CreateSchema = $S.CreateSchema
        $SchemaAuth = $S.SchemaAuth
        $ObjectType = $S.ObjectType
		$Variables = $S.Variables
        
        if ([String]::IsNullOrEmpty($ParentObjectName)) {
            $ParentObjectName = ""
        }
		
		
		
		$ScriptToRun = $FilePath + "\" +$FileName
		
		if($DropTruncateIfExists -eq 'DROP')
		{
            $Query = GetDropStatement -SchemaName $SchemaName -objectName $ObjectName -ParentObjectName $ParentObjectName -ObjectType $ObjectType
            if ($Query -ne "") {
                $ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SynapseADIntegrated $ConnectToSynapse -Database $DatabaseName -Query $Query #-SchemaName $SchemaName -TableName $TableName -DropIfExists $DropIfExists -StatusLogFile $StatusLogFile
            } else {
                $RunStatement = 0
            }
		}
		elseif($DropTruncateIfExists -eq 'TRUNCATE')
		{
			$Query = GetTruncateStatement -SchemaName $SchemaName -objectName $ObjectName -ObjectType $ObjectType
            if ($Query -ne "") {
			    $ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SynapseADIntegrated $ConnectToSynapse -Database $DatabaseName -Query $Query 
            } else {
                $RunStatement = 0
            }
		}
		elseif($DropTruncateIfExists -eq '' -or [string]::IsNullOrEmpty($DropTruncateIfExists))
		{
			$RunStatement = 0
		}

        if (($RunStatement -eq 0) -or ($ReturnValues.Get_Item("Status") -eq 'Success'))
		{
            if ($CreateSchema -eq 1 -and $SchemaName -ne "") 
            {
				$Query = GetSchemaStatement -SchemaName $SchemaName -SchemaAuth $SchemaAuth
				             
                $ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SynapseADIntegrated $ConnectToSynapse -Database $DatabaseName -Query $Query -Variables $Variables #-SchemaName $SchemaName -TableName $TableName -DropIfExists $DropIfExists -StatusLogFile $StatusLogFile
            }
		    if ($ReturnValues.Count -eq 0 -or $ReturnValues.Get_Item("Status") -eq 'Success')
            {
                $ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SynapseADIntegrated $ConnectToSynapse -Database $DatabaseName -InputFile $ScriptToRun -Variables $Variables #-SchemaName $SchemaName -TableName $TableName -DropIfExists $DropIfExists -StatusLogFile $StatusLogFile
            }
		}

		if($ReturnValues.Get_Item("Status") -eq 'Success')
		{
            $EndDate=(Get-Date)
            $Timespan = (New-TimeSpan -Start $StartDate -End $EndDate)
            $DurationSec = ($Timespan.seconds + ($Timespan.Minutes * 60) + ($Timespan.Hours * 60 * 60))
            $Message = "Process Completed for File: " + $FileName + " Duration: " + $DurationSec + " seconds"
	  		Write-Host $Message -ForegroundColor White -BackgroundColor Black
			$Status = $ReturnValues.Get_Item("Status")

			$HeaderRow = 0,$ServerName,$DatabaseName,$FilePath,$CreateSchema,$SchemaAuth,$ObjectType,$ObjectName,$FileName,$DropTruncateIfExists,$SchemaName,$Variables,$Status,$DurationSec
			$HeaderRow  -join ","  >> $StatusLogFile
	   	}
    	else
    	{
             $EndDate=(Get-Date)
             $Timespan = (New-TimeSpan -Start $StartDate -End $EndDate)
             $DurationSec = ($Timespan.seconds + ($Timespan.Minutes * 60) + ($Timespan.Hours * 60 * 60))
             $ErrorMsg = "Error running Script for File: " + $FileName + " Error: " + $ReturnValues.Get_Item("Msg") + "Duration: " + $DurationSec + " seconds"
    		 Write-Host $ErrorMsg -ForegroundColor Red -BackgroundColor Black
			 $Status = "Error: " + $ReturnValues.Get_Item("Msg")
			 $Status = $Status.Replace("`r`n", "")
			 $Status = '"' + $Status.Replace("`n", "") + '"'
			 $HeaderRow = $Active,$ServerName,$DatabaseName,$FilePath,$CreateSchema,$SchemaAuth,$ObjectType,$ObjectName,$FileName,$DropTruncateIfExists,$SchemaName,$Variables,$Status,$DurationSec
			 $HeaderRow  -join ","  >> $StatusLogFile
			 $Status = ""
    	}
	}
	else
	{       
		$ServerName = $S.ServerName
		$DatabaseName = $S.DatabaseName
		$FilePath = $S.FilePath
		$FileName = $S.FileName
		$DropTruncateIfExists = $S.DropTruncateIfExists.TOUpper()
		$SchemaName = $S.SchemaName
		$ObjectName = $S.ObjectName
		$ObjectType = $S.ObjectType
		$CreateSchema = $S.CreateSchema
        $SchemaAuth = $S.SchemaAuth
		$Variables = $S.Variables
		
        $EndDate=(Get-Date)
        $Timespan = (New-TimeSpan -Start $StartDate -End $EndDate)
    	$DurationSec = ($Timespan.seconds + ($Timespan.Minutes * 60) + ($Timespan.Hours * 60 * 60))
		if($Active -eq 2)
		{
			$Status = 'Status = ' + $Active + ' Process skipped.'
		}
		else 
		{
			$Status = 'Status = ' + $Active + ' Process did not run.'	
		}
		$Status = 'Status = ' + $Active + ' Process did not run.'
		$HeaderRow = $Active,$ServerName,$DatabaseName,$FilePath,$CreateSchema,$SchemaAuth,$ObjectType,$ObjectName,$FileName,$DropTruncateIfExists,$SchemaName,$Variables,$Status,$DurationSec
		$HeaderRow  -join ","  >> $StatusLogFile
	}

}

$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green

