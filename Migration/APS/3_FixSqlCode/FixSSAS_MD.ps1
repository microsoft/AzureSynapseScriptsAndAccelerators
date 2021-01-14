#
# FixSSAS_MD.ps1
#
# FileName: FixSSAS_MD.ps1
# =================================================================================================================================================
# 
# Change log:
# Created:    Nov 30, 2020
# Author:     Andrey Mirskiy
# Company:    Microsoft
# 
# =================================================================================================================================================
# Description:
#       Updates object names in SSAS MD project according to schema mappings (APS-->SQLDW)
#
# =================================================================================================================================================

param(
    [Parameter(Mandatory=$false, HelpMessage="Path to SSAS MD project folder.")]
    [string]
    $ProjectFolder = "C:\Users\amirskiy\source\repos\AdventureWorksDW\SSAS_MD",

    [Parameter(Mandatory=$false, HelpMessage="Path to schema mapping file.")]
    [string] 
    $schemasFilePath = "C:\APS2SQLDW\3_FixSqlCode\schemas.csv",

    [Parameter(Mandatory=$false, HelpMessage="Default schema which will be used if schema name is omitted.")] 
    [string]
    $defaultSchema = "dbo",

    [Parameter(Mandatory=$false, HelpMessage="Save changes to data source files.")] 
    [bool]
    $UpdateDataSources = $true,

    [Parameter(Mandatory=$false)] 
    [string]
    $AzureSqlServerName = "sqldwsqlserver.database.windows.net",
    
    [Parameter(Mandatory=$false)] 
    [string]
    $SynapseName = "sqldw",

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
        $newConnectionString = "Provider=MSOLEDBSQL.1;Data Source=$AzureSqlServerName;Persist Security Info=True;Password=;User ID=$userId;Initial Catalog=$SynapseName"        
        $content.DataSource.ConnectionString = $newConnectionString

        $content.Save($dsFile)
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

        if (($tableType -eq "Table") -or ($tableType -eq "View" -and ![String]::IsNullOrEmpty($schemaName)))
        {
            # This is Table / View

            if ($tableType -eq "Table" -and [String]::IsNullOrEmpty($schemaName))
            {
                $schemaName = $defaultSchema
            }

            $newSchemaName = $schemaCsvFile | Where {$_.ApsDbName -eq $currentDatabaseName -and $_.ApsSchema -eq $schemaName} | Select-Object -ExpandProperty SQLDWSchema
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
