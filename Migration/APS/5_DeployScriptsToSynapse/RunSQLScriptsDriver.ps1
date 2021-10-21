#======================================================================================================================#
#                                                                                                                      #
#  AzureSynapseScriptsAndAccelerators - PowerShell and T-SQL Utilities                                                 #
#                                                                                                                      #
#  This utility was developed to aid SMP/MPP migrations to Azure Synapse Migration Practitioners.                      #
#  It is not an officially supported Microsoft application or tool.                                                    #
#                                                                                                                      #
#  The utility and any script outputs are provided on "AS IS" basis and                                                #
#  there are no warranties, express or implied, including, but not limited to implied warranties of merchantability    #
#  or fitness for a particular purpose.                                                                                #
#                                                                                                                      #                    
#  The utility is therefore not guaranteed to generate perfect code or output. The output needs carefully reviewed.    #
#                                                                                                                      #
#                                       USE AT YOUR OWN RISK.                                                          #
#                                                                                                                      #
#======================================================================================================================#
#
# =================================================================================================================================================
# Description:
#       Driver to run multiple .sql or .dsql scripts against a SQL Server/Synapse/APS
#        
# =================================================================================================================================================
# 
# Authors: Andy Isley, Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\5_DeployScriptsToSynapse\ScriptCreateExternalTableDriver.ps1


#Requires -Version 5.1
#Requires -Modules SqlServer


Function GetPassword($securePassword)
{
       $securePassword = Read-Host "Please enter the Password" -AsSecureString
       $P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
       return $P
}

Function Get-AbsolutePath
{
    [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$Path
    ) 

    if ([System.IO.Path]::IsPathRooted($Path) -eq $false) {
        return [IO.Path]::GetFullPath( (Join-Path -Path $PSScriptRoot -ChildPath $Path) )
    } else {
        return $Path
    }
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
	elseif($ObjectType.TOUpper() -eq "IMP")
	{
        # This is Synapse import data (INSERT INTO). Hence, no need to drop target object.
		$Query = ""
	}
	elseif($ObjectType.TOUpper() -eq "COPY")
	{
        # This is Synapse import data (COPY INTO). Hence, no need to drop target object.
		$Query = ""
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


Function Get-AbsolutePath
{
    [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$Path
    ) 

    if ([System.IO.Path]::IsPathRooted($Path) -eq $false) {
        return [IO.Path]::GetFullPath( (Join-Path -Path $PSScriptRoot -ChildPath $Path) )
    } else {
        return $Path
    }
}


$ReturnValues = @{}

$error.Clear()

##############################################################
# User Input  here
#############################################################

$defaultScriptsToRunDriverFile = Join-Path -Path $PSScriptRoot -ChildPath "SynapseImportData.csv"

$ScriptsToRunDriverFile = Read-Host -prompt "Enter the name of the ScriptToRun csv File or Press 'Enter' to accept default [$defaultScriptsToRunDriverFile]"
	if($ScriptsToRunDriverFile -eq "" -or $ScriptsToRunDriverFile -eq $null)
	{$ScriptsToRunDriverFile = $defaultScriptsToRunDriverFile}
$ScriptsToRunDriverFile = Get-AbsolutePath -Path $ScriptsToRunDriverFile

$ConnectToSynapse = Read-Host -prompt "How do you want to connect to server (ADPass, ADInt, WinInt, SQLAuth)?"
$ConnectToSynapse = $ConnectToSynapse.ToUpper()
if ($ConnectToSynapse.ToUpper() -eq "SQLAUTH" -or $ConnectToSynapse.ToUpper() -eq "ADPASS") {
	$UserName = Read-Host -prompt "Enter the UserName if not using Integrated"
    if ($UserName -eq "" -or $UserName -eq $null) {
        $UserName = "sqladmin"
    }
	$Password = GetPassword
    if($Password -eq "") {
        Write-Host "A password must be entered"
		break
    }
}
$StatusLogPath = Read-Host -prompt "Enter the name of the Output File Directory or Press 'Enter' to accept default [$PSScriptRoot]"
	if($StatusLogPath -eq "" -or $StatusLogPath -eq $null) {$StatusLogPath =  $PSScriptRoot}
$StatusLog = Read-Host -prompt "Enter the name of the status file or Press 'Enter' to accept default"
	if($StatusLog -eq "" -or $StatusLog -eq $null) {$StatusLog = (Get-Date -Format yyyyMMddTHHmmss) + ".log"}


###############################################################################################
# Main logic Here
###############################################################################################

Import-Module "$PSScriptRoot\RunSQLScriptFile.ps1" -Force -Scope Global

if (!(Test-Path $StatusLogPath)) {
    New-item $StatusLogPath -ItemType Dir | Out-Null
}

$StatusLogFile = Join-Path -Path $StatusLogPath -ChildPath $StatusLog 

$csvFile = Import-Csv $ScriptsToRunDriverFile

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
		
		
        $FilePathAbsolute = Get-AbsolutePath $FilePath
		$ScriptToRun = Join-Path -Path $FilePathAbsolute -ChildPath $FileName
		
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

