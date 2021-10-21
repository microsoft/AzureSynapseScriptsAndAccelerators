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
#       Generate "Create External Table" statements for Synapse 
#        
# =================================================================================================================================================
# 
# Authors: Andy Isley, Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\4_CreateExternalTablesSynapse\ScriptCreateExternalTableDriver.ps1


#Requires -Version 5.1
#Requires -Modules SqlServer


###############################################################################################
# User Input Here
###############################################################################################

$defaultScriptsDriverFile = "$PSScriptRoot\One_ExternalTablesDriver_Generated.csv"

$ScriptsDriverFile = Read-Host -prompt "Enter the name of the Export csv Driver File or Press Enter to accept default: [$defaultScriptsDriverFile] "
	if($ScriptsDriverFile -eq "" -or $ScriptsDriverFile -eq $null)
	{$ScriptsDriverFile = $defaultScriptsDriverFile}	


###############################################################################################
# Main logic Here
###############################################################################################

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
    $InputFolderPath = Get-AbsolutePath $InputFolderPath
    $OutputFolderPath = Get-AbsolutePath $OutputFolderPath

    if (!(Test-Path $OutputFolderPath))
	{
		New-Item "$OutputFolderPath" -ItemType Dir | Out-Null
    }

    $OutputFolderPathFullName = Join-Path -Path $OutputFolderPath -ChildPath "$FileName.sql"
    $InputFolderPathFileName = Join-Path -Path $InputFolderPath -ChildPath $InputFileName 
        
    $SourceFile = Get-Content -Path $InputFolderPathFileName

    $WithFound = $false

    #$query = "IF NOT EXISTS (SELECT * FROM sys.schemas WHERE [name]='" + $SchemaName + "') EXEC('CREATE SCHEMA [" + $SchemaName +"]')`r`nGO`r`n`r`n"
    
    $query = ""

    foreach($l in $SourceFile)
    {
        if($l -match 'CREATE TABLE' -and !$WithFound)
        {
            $CreateClause = "CREATE EXTERNAL TABLE [" + $SchemaName + "].[" + $ObjectName + "]"
            if($l -match "[(]") 
                {$CreateClause = $CreateClause + "("}
            $query += $CreateClause + "`r`n"
        }
        elseif($l -match 'WITH[\s]*\(' -and !$WithFound) 
        {
            $WithFound = $true
            $ExternalWith = " WITH (  
                LOCATION='" + $ExportLocation + "',  
                DATA_SOURCE = " + $DataSource + ",  
                FILE_FORMAT = " + $FileFormat + "`r`n)"

            $query += $ExternalWith + "`r`n"
            #$query += "GO`r`n"
        }
        elseif(!$WithFound)
        {
            $query += $l + "`r`n"
        }
    }
    $query | Out-File -FilePath $OutputFolderPathFullName
}



$startTime = Get-Date

$csvFile = Import-Csv $ScriptsDriverFile

ForEach ($ObjectToScript in $csvFile ) 
{
	$Active = $ObjectToScript.Active
    if ($Active -eq '1') 
	{
		$OutputFolderPath = $ObjectToScript.OutputFolderPath
		$FileName = $ObjectToScript.FileName
		$InputFolderPath= $ObjectToScript.InputFolderPath
		$InputFileName= $ObjectToScript.InputFileName
		$SchemaName = $ObjectToScript.SchemaName
		$ObjectName = $ObjectToScript.ObjectName
		$DataSource = $ObjectToScript.DataSource
		$FileFormat = $ObjectToScript.FileFormat
		$FileLocation = $ObjectToScript.FileLocation				      
		Write-Host "Processing Export Script for: $SchemaName.$ObjectName"
		ScriptCreateExternalTableScript $OutputFolderPath $FileName $InputFolderPath $InputFileName $SchemaName $ObjectName $DataSource $FileFormat $FileLocation	
	}
}


$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
