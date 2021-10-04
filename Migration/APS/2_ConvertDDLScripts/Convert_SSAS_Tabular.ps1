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
#       Updates object names in SSAS Tabular project according to schema mappings (APS-->Synapse)
#        
# =================================================================================================================================================
# 
# Authors: Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\2_ConvertDDLScripts\Convert_SSAS_Tabular.ps1


param(
    [Parameter(Mandatory=$false, HelpMessage="Path to SSAS Tabular project folder.")]
    [string]
    $ProjectFolder = "C:\temp\SSAS_Tabular",

    [Parameter(Mandatory=$false, HelpMessage="Path to schema mapping file.")]
    [string] 
    $SchemasFilePath = "C:\temp\schemas.csv",

    [Parameter(Mandatory=$false, HelpMessage="Default schema which will be used if schema name is omitted.")] 
    [string]
    $DefaultSchema = "dbo",

    [Parameter(Mandatory=$false, HelpMessage="Save changes to data source files.")] 
    [bool]
    $UpdateDataSources = $true,

    [Parameter(Mandatory=$false)] 
    [string]
    $AzureSqlServerName = "sqldwsqlserver.database.windows.net",
    
    [Parameter(Mandatory=$false)] 
    [string]
    $SynapseName = "BLINK",

    [Parameter(Mandatory=$false, HelpMessage="Save changes to SSAS Tabular source code.")] 
    [bool]
    $SaveFiles = $true
)


Import-Module $PSScriptRoot\FixSchemas.ps1 -Force


$startTime = Get-Date

$schemaCsvFile = Import-Csv $SchemasFilePath
$bimFiles = Get-Item -Path $ProjectFolder\*.bim


$i = 0
foreach ($bimFile in $bimFiles)
{
    Write-Host "Processing model file - $bimFile" -ForegroundColor Yellow

    $content = Get-Content -Raw -Path $bimFile | ConvertFrom-Json
    $model = $content.model


    $dataSources = @{}
    foreach ($dataSource in $model.dataSources)
    {
        Write-Host "Processing data source - $($dataSource.name)" -ForegroundColor Yellow

        $name = $dataSource.name
        $connectionString = $dataSource.ConnectionString

        # If it's not APS connection
        if (!$connectionString.Contains(",17001")) {
            continue
        }           

        $builder = New-Object -TypeName System.Data.OleDb.OleDbConnectionStringBuilder -ArgumentList $connectionString
        $databaseName = $builder["initial catalog"]
        $userId = $builder["User ID"]
        $dataSources.Add($name, $databaseName)

        if ($UpdateDataSources -eq $true)
        {
            $newConnectionString = "Data Source=$AzureSqlServerName;Initial Catalog=$SynapseName;User ID=$userId;Persist Security Info=true;Encrypt=true;TrustServerCertificate=false"
            $dataSource.ConnectionString = $newConnectionString
            $dataSource.annotations[0].value = "AzureSqlDW"
        }
    }


    foreach ($table in $model.tables)
    {
        Write-Host "Processing table - $($table.name)" -ForegroundColor Yellow
        foreach ($partition in $table.partitions)
        {
            $dataSource = $partition.source.dataSource
            $sourceType = $partition.source.type
            if ($sourceType -eq "query" -or [string]::IsNullOrEmpty($sourceType))
            {
                $query = $partition.source.query
                $currentDatabaseName = $dataSources[$dataSource]

                #Write-Host $query

                $query = AddMissingSchemas -query $query -defaultSchema $DefaultSchema
                $query = ChangeSchemas -DatabaseName $currentDatabaseName -SchemaMappings $schemaCsvFile -query $query -defaultSchema $DefaultSchema
                $partition.source.query = $query

                #Write-Host $query
            }
            elseif ($partition.source.type -eq "m")
            {
                $expression = $partition.source.expression

                $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant, Multiline'
                $pattern = "[\s]+Source[\s]+=[\s]+([^\s]+),"
                $matches = [regex]::Matches($expression, $pattern, $regexOptions)

                if ($matches.Count -gt 0)
                {
                    if ($matches[0].Groups.Count -eq 2)
                    {
                        $dataSource = $matches[0].Groups[1].Value
                        $currentDatabaseName = $dataSources[$dataSource]

                        $pattern = "[\s]+Source\{\[Schema=\""([^\s]+)\"","
                        $matches = [regex]::Matches($expression, $pattern, $regexOptions)
                        if ($matches.Count -gt 0)
                        {
                            if ($matches[0].Groups.Count -eq 2)
                            {
                                $currentSchema = $matches[0].Groups[1].Value
                                $newSchema = $schemaCsvFile | Where {$_.ApsDbName -eq $currentDatabaseName -and $_.ApsSchema -eq $currentSchema} | Select -ExpandProperty "SynapseSchema"

                                if (![String]::IsNullOrEmpty($newSchema))
                                {
                                    $expression -replace $matches[0].Groups[0].Value, "Source{[Schema=""$newSchema"""
                                    $partition.source.expression = $expression
                                }
                            }
                        }
                    }
                }

                Write-Host $expression
            }
            else
            {
                throw "Not supported source type"
            }
        }

    }

    if ($SaveFiles)
    {
        $content | ConvertTo-Json -depth 100 | Out-File $bimFile
    }
    
    Write-Progress -PercentComplete (++$i * 100.0 / $partitionFiles.Count) -Activity "Updating DSV tables"
}


$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
