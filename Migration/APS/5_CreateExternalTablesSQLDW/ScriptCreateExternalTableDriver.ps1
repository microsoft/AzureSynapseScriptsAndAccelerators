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


Import-Module "$PSScriptRoot\CreateSQLDWExtTableStatements.ps1" -Force


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
