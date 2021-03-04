#
# ScriptMPPObjects.ps1
#
# FileName: ScriptCreateExternalTableDriver.ps1
# =================================================================================================================================================
# Scriptname: ScriptCreateExternalTableDriver.ps1
# 
# Change log:
# Created: July, 2018
# Author: Andy Isley
# Company: 
# 
# =================================================================================================================================================
# Description:
#       Generate "Create External Table" statements for SQLDW 
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

$defaultScriptsDriverFile = "$PSScriptRoot\One_ExternalTablesDriver_Generated.csv"

$ScriptsDriverFile = Read-Host -prompt "Enter the name of the Export csv Driver File or Press Enter to accept default: [$defaultScriptsDriverFile] "
	if($ScriptsDriverFile -eq "" -or $ScriptsDriverFile -eq $null)
	{$ScriptsDriverFile = $defaultScriptsDriverFile}	


#Import-Module "$PSScriptRoot\CreateSQLDWExtTableStatements.ps1" -Force

function ScriptCreateExternalTableScript(
            $OutputFolderPath 
            ,$FileName 
            ,$InputFolderPath 
            ,$InputFileName 
            ,$SchemaName 
            ,$ObjectName 
            ,$DataSource 
            ,$FileFormat 
            ,$ExportLocation 
            ,$FileLocation)
{
    if (!(Test-Path $OutputFolderPath))
	{
		New-Item "$OutputFolderPath" -ItemType Dir | Out-Null
    }

    $OutputFolderPathFullName = $OutputFolderPath + $FileName + '.dsql'
    $InputFolderPathFileName = $InputFolderPath + $InputFileName 
        
    $SourceFile = Get-Content -Path $InputFolderPathFileName

    $WithFound = $false

    foreach($l in $SourceFile)
    {
        if($l -match 'CREATE TABLE' -and !$WithFound)
        {

            $CreateClause = "CREATE EXTERNAL TABLE [" + $SchemaName + "].[" + $ObjectName + "]"
            if($l -match "[(]") 
                {$CreateClause = $CreateClause + "("}
            $CreateClause >> $OutputFolderPathFullName
        }
        elseif($l -match 'WITH \(' -and !$WithFound) 
        {
            $WithFound = $true
            $ExternalWith = " WITH (  
                LOCATION='" + $ExportLocation + "',  
                DATA_SOURCE = " + $DataSource + ",  
                FILE_FORMAT = " + $FileFormat + ")"

            $ExternalWith >> $OutputFolderPathFullName
        }
        elseif(!$WithFound)
        {
            $l >> $OutputFolderPathFullName
        }
    }
}



$startTime = Get-Date

$csvFile = Import-Csv $ScriptsDriverFile

ForEach ($ObjectToScript in $csvFile ) 
{
	$Active = $ObjectToScript.Active
    if ($Active -eq '1') 
	{
        #$DatabaseName = $ObjectToScript.DatabaseName
		$OutputFolderPath = $ObjectToScript.OutputFolderPath
		$FileName = $ObjectToScript.FileName
		$InputFolderPath= $ObjectToScript.InputFolderPath
		$InputFileName= $ObjectToScript.InputFileName
		$SchemaName = $ObjectToScript.SchemaName
		$ObjectName = $ObjectToScript.ObjectName
		$DataSource = $ObjectToScript.DataSource
		$FileFormat = $ObjectToScript.FileFormat
		$FileLocation = $ObjectToScript.FileLocation				      
		# Gail Zhou
		#Write-Host 'Processing Export Script for : '$SourceSchemaName'.'$SourceObjectName
		Write-Host 'Processing Export Script for : '$SchemaName'.'$ObjectName
		ScriptCreateExternalTableScript $OutputFolderPath $FileName $InputFolderPath $InputFileName $SchemaName $ObjectName $DataSource $FileFormat $FileLocation	
	}
}


$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
