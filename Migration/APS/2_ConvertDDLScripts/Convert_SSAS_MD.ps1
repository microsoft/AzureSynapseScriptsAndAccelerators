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
#       Updates object names in SSAS MultiDimensional project according to schema mappings (APS-->Synapse)
#        
# =================================================================================================================================================
# 
# Authors: Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\2_ConvertDDLScripts\Convert_SSAS_MD.ps1


param(
    [Parameter(Mandatory=$false, HelpMessage="Path to SSAS MD project folder.")]
    [string]
    $ProjectFolder = "C:\temp\SSAS_MD",

    [Parameter(Mandatory=$false, HelpMessage="Path to schema mapping file.")]
    [string] 
    $schemasFilePath = "C:\AzureSynapseScriptsAndAccelerators\Migration\APS\3_ConvertDDLScripts\schemas.csv",

    [Parameter(Mandatory=$false, HelpMessage="Default schema which will be used if schema name is omitted.")] 
    [string]
    $defaultSchema = "dbo",

    [Parameter(Mandatory=$false, HelpMessage="Save changes to data source files.")] 
    [bool]
    $UpdateDataSources = $true,

    [Parameter(Mandatory=$false)] 
    [string]
    $AzureSqlServerName = "servername.sql.azuresynapse.net",
    
    [Parameter(Mandatory=$false)] 
    [string]
    $SynapseName = "EDW",

    [Parameter(Mandatory=$false, HelpMessage="Save changes to SSAS MD source code.")] 
    [bool]
    $SaveFiles = $true
)


Import-Module $PSScriptRoot\FixSchemas.ps1 -Force


$startTime = Get-Date

$schemaCsvFile = Import-Csv $schemasFilePath
$dsFiles = Get-Item -Path $projectFolder\*.ds
$dsvFiles = Get-Item -Path $projectFolder\*.dsv 
$partitionFiles = Get-Item -Path $projectFolder\*.partitions
$projectFiles = Get-Item -Path $projectFolder\*.dwproj


$dataSources = @{}
foreach ($dsFile in $dsFiles)
{
    Write-Host "Processing data source file - $dsFile" -ForegroundColor Yellow

    $content = [xml](Get-Content $dsFile)
    $ID = $content.DataSource.ID
    $connectionString = $content.DataSource.ConnectionString

    # If it's not APS connection
    if (!$connectionString.Contains(",17001")) {
        continue
    }           

    $builder = New-Object -TypeName System.Data.OleDb.OleDbConnectionStringBuilder -ArgumentList $connectionString
    $databaseName = $builder["initial catalog"]
    $userId = $builder["User ID"]
    $dataSources.Add($ID, $databaseName)

    if ($UpdateDataSources -eq $true)
    {
        $newConnectionString = "Provider=SQLNCLI11.1;Data Source=$AzureSqlServerName;Persist Security Info=True;Password=;User ID=$userId;Initial Catalog=$SynapseName"        
        $content.DataSource.ConnectionString = $newConnectionString
        $content.Save($dsFile)

        foreach ($projectFile in $projectFiles)
        {
            $projectFileContent = [xml](Get-Content $projectFile)
            $projectFileContent.Project.Configurations
            if ($projectFileContent.Project.Configurations.Configuration.Options.ConnectionMappings.ConfigurationSetting.Id -eq $ID)
            {
                $projectFileContent.Project.Configurations.Configuration.Options.ConnectionMappings.ConfigurationSetting.Value.'#text' = $newConnectionString
                $projectFileContent.Save($projectFile)
            }
        }
    }
}


$i = 0
foreach ($dsvFile in $dsvFiles)
{
    Write-Host "Processing data source view file - $dsvFile" -ForegroundColor Yellow

    $content = [xml](Get-Content $dsvFile)

    $ID = $content.DataSourceView.ID
    $name = $content.DataSourceView.Name
    $dataSourceID = $content.DataSourceView.DataSourceID
    
    $currentDatabaseName = $dataSources[$dataSourceID]
   
    $tables = $content.DataSourceView.Schema.schema.element.complexType.choice.element
    
    foreach ($table in $tables)
    {
        $schemaName = $table.DbSchemaName         #$node.Node.Attributes["msprop:DbSchemaName"].Value
        $tableName = $table.DbTableName           #$node.Node.Attributes["msprop:DbTableName"].Value
        $tableType = $table.TableType             #$node.Node.Attributes["msprop:TableType"].Value
        $queryDefinition = $table.QueryDefinition #$node.Node.Attributes["msprop:QueryDefinition"].Value

        if ($tableType -in ("Table", "View") -and [String]::IsNullOrEmpty($queryDefinition))
        {
            # This is Table / View

            if ($tableType -in ("Table", "View") -and [String]::IsNullOrEmpty($schemaName))
            {
                $schemaName = $defaultSchema
            }

            $newSchemaName = $schemaCsvFile | Where {$_.ApsDbName -eq $currentDatabaseName -and $_.ApsSchema -eq $schemaName} | Select-Object -ExpandProperty SynapseSchema
            if (![String]::IsNullOrEmpty($newSchemaName))
            {
                $table.DbSchemaName = $newSchemaName.ToString()
            }
        }
        else
        {
            # This is Named Query
            $queryDefinition = AddMissingSchemas -query $queryDefinition -defaultSchema $defaultSchema
            $queryDefinition = ChangeSchemas -DatabaseName $currentDatabaseName -SchemaMappings $schemaCsvFile -query $queryDefinition -defaultSchema $defaultSchema
            $table.QueryDefinition = $queryDefinition
        }
    }

    if ($SaveFiles)
    {
        $content.Save($dsvFile)
    }
    
    Write-Progress -PercentComplete (++$i * 100.0 / $dsvFiles.Count) -Activity "Updating DSV tables"
}


$i = 0
foreach ($partitionFile in $partitionFiles)
{
    Write-Host "Processing partition file - $partitionFile" -ForegroundColor Yellow
    
    $content = [xml](Get-Content $partitionFile)

    #$content.Save($partitionFileFile)
    $measureGroups = $content.Cube.MeasureGroups.MeasureGroup
    foreach ($measureGroup in $measureGroups)
    {
        $partitions = $measureGroup.Partitions.Partition
        foreach ($partition in $partitions)
        {
            if ($partition.Source.type -eq "QueryBinding")
            {
                $dataSourceID = $partition.Source.DataSourceID
                $queryDefinition = $partition.Source.QueryDefinition
                $currentDatabaseName = $dataSources[$dataSourceID]

                $queryDefinition = AddMissingSchemas -query $queryDefinition -defaultSchema $defaultSchema
                $queryDefinition = ChangeSchemas -DatabaseName $currentDatabaseName -SchemaMappings $schemaCsvFile -query $queryDefinition -defaultSchema $defaultSchema
                $partition.Source.QueryDefinition = $queryDefinition
            }
        }
    }

    if ($SaveFiles)
    {
        $content.Save($partitionFile)
    }

    Write-Progress -PercentComplete (++$i * 100.0 / $partitionFiles.Count) -Activity "Updating partition files"
}


$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
