#
# ConvertDDLScriptsDriver.ps1
#
# FileName: ConvertDDLScriptsDriver.ps1
# =================================================================================================================================================
# 
# Change log:
# Created:    Nov 30, 2020
# Author:     Andrey Mirskiy
# Company:    Microsoft
# 
# =================================================================================================================================================
# Description:
#       Fixes SQL code (stored procedures, functions, views)
#        1. Adds schema name if schema name is omitted
#        2. Replaces schema names according to schema mappings (APS-->Synapse)
#        3. Adjust #TEMP tables distribution (REPLICATE-->ROUND_ROBIN)
#
# =================================================================================================================================================
#
# WARNING:
#       Adding missing schema names does not work properly for CTE aliases. Use flag to control the behavior of the script.
# =================================================================================================================================================


Import-Module $PSScriptRoot\FixSchemas.ps1 -Force


$useThreePartNames = $true
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
        $databaseName = $configRow.SourceDatabaseName  #Changed from ApsDatabaseName 
        $sourceDir = $configRow.SourceDirectory
        $targetDir = $configRow.TargetDirectory
        $defaultSchema = $configRow.DefaultSchema
        
        if (!(Test-Path -Path $sourceDir)) {
            continue
        }

        foreach ($file in Get-ChildItem -Path $sourceDir -Filter *.sql)
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
            $newContent = ChangeSchemas -DatabaseName $databaseName -SchemaMappings $schemaCsvFile -query $newContent -defaultSchema $defaultSchema -useThreePartNames $useThreePartNames

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
