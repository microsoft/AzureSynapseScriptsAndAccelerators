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
#       This script fixes SQL code (stored procedures, functions, views)
#        1. Adds schema name if schema name is omitted
#        2. Replaces schema names according to schema mappings (APS-->Synapse)
#        3. Adjust #TEMP tables distribution (REPLICATE-->ROUND_ROBIN)
#        
# WARNING:
#       Adding missing schema names does not work properly for CTE aliases. Use flag to control the behavior of the script.
# =================================================================================================================================================
# 
# Authors: Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\2_ConvertDDLScripts\ConvertDDLScriptsDriver.ps1


Import-Module $PSScriptRoot\FixSchemas.ps1 -Force


$addMissingSchemas = $true


$defaultConfigDir = "$PSScriptRoot"
$configFileDir = Read-Host -prompt "Please enter the path of your configuration files. Or press 'Enter' to accept the default [$($defaultConfigDir)]"
if($configFileDir -eq "" -or $configFileDir -eq $null)
	{$configFileDir = $defaultConfigDir}

$defaultConfigFile = "cs_dirs.csv"
$configFile = Read-Host -prompt "Please enter the name of your code migration config file. Press [Enter] if it is [$($defaultConfigFile)]"
if($configFile -eq "" -or $configFile -eq $null)
	{$configFile = $defaultconfigFile}

$defaultSchemasFile = "schemas.csv"
$schemasFile = Read-Host -prompt "Please enter the name of your schema mapping file. Press [Enter] if it is [$($defaultSchemasFile)]"
if($schemasFile -eq "" -or $schemasFile -eq $null)
	{$schemasFile = $defaultSchemasFile}



$startTime = Get-Date

$configFilePath = Join-Path -Path $configFileDir -ChildPath $configFile
$schemasFilePath = Join-Path -Path $ConfigFileDir -ChildPath $schemasFile

$configCsvFile = Import-Csv $configFilePath 
$schemaCsvFile = Import-Csv $schemasFilePath
 

ForEach ($configRow in $configCsvFile) 
{
    if ($configRow.Active -eq '1') 
	{
        $databaseName = $configRow.ApsDatabaseName
        $sourceDir = $configRow.SourceDirectory
        $targetDir = $configRow.TargetDirectory
        $defaultSchema = $configRow.DefaultSchema
        
        if (!(Test-Path -Path $sourceDir)) {
            continue
        }

        foreach ($file in Get-ChildItem -Path $sourceDir -Filter *.dsql)
        {
            $sourceFilePath = $file.FullName
            $targetFilePath = Join-Path -Path $targetDir -ChildPath $file.Name
            (Get-Date -Format HH:mm:ss.fff)+" - "+$sourceFilePath | Write-Host -ForegroundColor Yellow
            $content = Get-Content -Path $SourceFilePath -Raw

            $newContent = $content
            $newContent = FixTempTables -Query $newContent
            if ($addMissingSchemas) {
                $newContent = AddMissingSchemas -Query $newContent -defaultSchema $defaultSchema
            }
            $newContent = ChangeSchemas -DatabaseName $databaseName -SchemaMappings $schemaCsvFile -query $newContent -defaultSchema $defaultSchema

            $targetFolder = [IO.Path]::GetDirectoryName($TargetFilePath)
            if (!(Test-Path $targetFolder))
            {
	            New-item -Path $targetFolder -ItemType Dir | Out-Null
            }

            $newContent | Out-File $TargetFilePath
        }
	}
}

$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
