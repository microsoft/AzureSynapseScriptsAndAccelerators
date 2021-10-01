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


$defaultScriptsDriverFile = "$PSScriptRoot\One_ExternalTablesDriver_Generated.csv"

$ScriptsDriverFile = Read-Host -prompt "Enter the name of the Export csv Driver File or Press Enter to accept default: [$defaultScriptsDriverFile] "
	if($ScriptsDriverFile -eq "" -or $ScriptsDriverFile -eq $null)
	{$ScriptsDriverFile = $defaultScriptsDriverFile}	


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
