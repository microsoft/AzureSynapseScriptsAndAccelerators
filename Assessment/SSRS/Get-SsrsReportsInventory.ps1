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
###################################################################################################################################
###################################################################################################################################
#
# Author: Andrey Mirskiy
# November 2021 
# Description: The script collects SSRS projects inventory and generates output CSV-files which can be used for further analysis.
#
#
###################################################################################################################################

#Requires -Version 5.1


param(
    [Parameter(Mandatory=$true, HelpMessage="Path to SSRS root folder")]
    [ValidateScript({
        if( -Not ($_ | Test-Path -PathType Container) ){
            throw "Folder $_ does not exist"
        }
        return $true
    })]
    [string] $InputFolder,

    [Parameter(Mandatory=$true, HelpMessage="Path to output folder")]
    [ValidateScript({
        if( -Not ($_ | Test-Path -PathType Container) ){
            throw "Folder $_ does not exist"
        }
        return $true
    })]
    [string] $OutputFolder
)


$startTime = Get-Date


function GetConnectionType($extension)
{
    $connectionType = switch ( $extension )
        {
            "OLEDB-MD.1"     { 'Azure Analysis Services' }
            "SQLAZURE.1"     { 'Azure SQL Data Warehouse'    }
            "SQLPDW"         { 'Microsoft Analytics Platform System'   }
            "SQLAZURE"       { 'Microsoft Azure SQL Database' }
            "SQL"            { 'Microsoft SQL Server'  }
            "OLEDB-MD"       { 'Microsoft SQL Server Analysis Services'    }
            "SHAREPOINTLIST" { 'Microsoft SharePoint list'  }
            "ODBC"           { 'ODBC' }
            "OLEDB"          { 'OLEDB'  }
            "ORACLE"         { 'Oracle Database'  }
            "ESSBASE"        { 'Oracle Essbase'  }
            "RS"             { 'Report Server Model'  }
            "SAPBW"          { 'SAP BW'  }
            "TERADATA"       { 'TERADATA'  }
            "XML"            { 'XML'  }
        }
    return $connectionType
}

function GetSharedDataSourceInfo($ProjectUID, $dataSourceFilePath)
{
    if ($ProjectUID -eq "") {
        return [PSCustomObject]@{
                    ProjectUID          = "";
                    SharedDataSourceUID = "";
                    SharedDataSourceID  = "";
                    Name                = "";
                    DataSourceFilePath  = "";
                    Extension           = "";
                    ConnectionType      = "";
                    ConnectionString    = "";
                }
    }

    if (-Not (Test-Path -Path $dataSourceFilePath)) {
        Write-Error "File $dataSourceFilePath is not found" -ErrorAction Continue
        return
    }

    [xml]$dataSourceXml = Get-Content $dataSourceFilePath

    $dataSourceInfo = [PSCustomObject]@{
        ProjectUID          = $projectUID;
        SharedDataSourceUID = [guid]::NewGuid();
        SharedDataSourceID  = $dataSourceXml.RptDataSource.DataSourceID;
        Name                = (Get-Item $dataSourceFilePath).Basename; 
        DataSourceFilePath  = Resolve-Path -Path $dataSourceFilePath -Relative
        Extension           = $dataSourceXml.RptDataSource.ConnectionProperties.Extension;
        ConnectionType      = GetConnectionType $dataSourceXml.RptDataSource.ConnectionProperties.Extension;
        ConnectionString    = $dataSourceXml.RptDataSource.ConnectionProperties.ConnectString;
    }

    return $dataSourceInfo
}


function GetSharedDataSetInfo($ProjectUID, $dataSetFilePath)
{
    if ($ProjectUID -eq "") {
        return [PSCustomObject]@{
                    ProjectUID            = "";
                    SharedDataSetUID      = "";
                    Name                  = ""; 
                    DataSetFilePath       = "";
                    DataSourceReference   = "";
                    CommandType           = "";
                    CommandText           = "";
                    ParametersCount       = "";
                    FieldsCount           = "";
                    QueryFieldsCount      = "";
                    CalculatedFieldsCount = "";
                    FiltersCount          = "";
                }
    }

    if (-Not (Test-Path -Path $dataSetFilePath)) {
        Write-Error "File $dataSetFilePath is not found" -ErrorAction Continue
        return
    }

    [xml]$dataSetXml = Get-Content $dataSetFilePath
    $ns = @{ns = $dataSetXml.SharedDataSet.xmlns}

    $dataSetInfo = [PSCustomObject]@{
        ProjectUID            = $projectUID;
        SharedDataSetUID      = [guid]::NewGuid();
        Name                  = if ($dataSetXml.SharedDataSet.DataSet.Name) { $dataSetXml.SharedDataSet.DataSet.Name } else { (Get-Item $dataSetFilePath).Basename }; 
        DataSetFilePath       = Resolve-Path -Path $dataSetFilePath -Relative
        DataSourceReference   = $dataSetXml.SharedDataSet.DataSet.Query.DataSourceReference;
        CommandType           = if ($dataSetXml.SharedDataSet.DataSet.Query.CommandType) { $dataSetXml.SharedDataSet.DataSet.Query.CommandType } else { "Query" };
        CommandText           = if ($dataSetXml.SharedDataSet.DataSet.Query.CommandText) {$dataSetXml.SharedDataSet.DataSet.Query.CommandText.Replace("`n"," ").Replace("`r"," ")} else {""};
        ParametersCount       = $dataSetXml.SharedDataSet.DataSet.Query.DataSetParameters.ChildNodes.Count;
        FieldsCount           = $dataSetXml.SharedDataSet.DataSet.Fields.ChildNodes.Count;
        QueryFieldsCount      = Select-Xml -Xml $dataSetXml -Namespace $ns -XPath "//ns:Fields//ns:Field//ns:DataField" | Measure-Object | % { $_.Count };
        CalculatedFieldsCount = Select-Xml -Xml $dataSetXml -Namespace $ns -XPath "//ns:Fields//ns:Field//ns:Value" | Measure-Object | % { $_.Count };
        FiltersCount          = $dataSetXml.SharedDataSet.DataSet.Filters.ChildNodes.Count;
    }

    return $dataSetInfo
}


function GetReportInfo($ProjectUID, $reportFilePath)
{
    if ($ProjectUID -eq "") {
        $reportInfo = [PSCustomObject]@{
            ProjectUID            = "";
            ReportUID             = "";
            ReportID              = "";
            ReportFilePath        = "";
            Name                  = "";
            Language              = "";
            UnitType              = "";
            CodeModules           = "";
            CodeLines             = "";
            EmbeddedImagesCount   = "";
            ParametersCount       = "";
            DataSetsCount         = "";
            SubreportsCount       = "";
            HyperlinksCount       = "";
            DrillthroughCount     = "";
            BookmarkLinksCount    = "";
            BookmarksCount        = "";
            DocumentMapLabelCount = "";        
            TextBoxCount          = "";
            RectangleCount        = "";
            ImageCount            = "";
            LineCount             = "";
            TablixCount           = "";
            MapCount              = "";
            SparkLineCount        = "";
            DataBarCount          = "";
            ChartCount            = "";
            GaugePanelCount       = "";
            RadialGaugesCount     = "";
            LinearGaugesCount     = "";
            IndicatorsCount       = "";
            GaugeLabelsCount      = "";
            UserIdVariableCount   = "";
            ExecutionTimeVariableCount   = "";
        }
        $dataSourceInfo = [PSCustomObject]@{
            ProjectUID            = "";
            ReportUID             = "";
            ReportID              = "";
            DataSourceUID         = "";
            DataSourceID          = "";
            Name                  = "";
            Extension             = "";
            ConnectionType        = "";
            ConnectionString      = "";
            SharedDataSourceUID   = "";
        }
        $dataSetInfo = [PSCustomObject]@{
            ProjectUID            = "";
            ReportUID             = "";
            ReportID              = "";
            DataSetUID            = "";
            Name                  = "";
            DataSourceReference   = "";
            CommandType           = "";
            CommandText           = "";
            ParametersCount       = "";
            FieldsCount           = "";
            QueryFieldsCount      = "";
            CalculatedFieldsCount = "";
            FiltersCount          = "";
            SharedDataSetUID      = "";
        }
        return $reportInfo, $dataSourceInfo, $dataSetInfo
    }

    if (-Not (Test-Path -Path $reportFilePath)) {
        Write-Error "File $reportFilePath is not found" -ErrorAction Continue
        return
    }

    $reportUID = [guid]::NewGuid()

    [xml]$reportXml = Get-Content $reportFilePath
    $ns = @{ns = $reportXml.Report.xmlns; rd = $reportXml.Report.rd}

    $reportInfo = [PSCustomObject]@{
        ProjectUID            = $projectUID;
        ReportUID             = $reportUID;
        ReportID              = $reportXml.Report.ReportID;
        ReportFilePath        = Resolve-Path -Path $reportFilePath -Relative
        Name                  = (Get-Item $reportFilePath).Basename; 
        Language              = $reportXml.Report.Language;
        UnitType              = $reportXml.Report.ReportUnitType;
        CodeModules           = $reportXml.Report.CodeModules.ChildNodes.Count;
        CodeLines             = $reportXml.Report.Code | Measure-Object -Line | % { $_.Lines };
        EmbeddedImagesCount   = $reportXml.Report.EmbeddedImages.ChildNodes.Count;
        ParametersCount       = $reportXml.Report.ReportParameters.ChildNodes.Count;
        DataSetsCount         = $reportXml.Report.DataSets.ChildNodes.Count;
        SubreportsCount       = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Subreport" | Measure-Object | % { $_.Count };
        HyperlinksCount       = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Action/ns:Hyperlink" | Measure-Object | % { $_.Count };
        DrillthroughCount     = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Action/ns:Drillthrough" | Measure-Object | % { $_.Count };
        BookmarkLinksCount    = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Action/ns:BookmarkLink" | Measure-Object | % { $_.Count };        
        BookmarksCount        = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Bookmark" | Measure-Object | % { $_.Count };
        DocumentMapLabelCount = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:DocumentMapLabel" | Measure-Object | % { $_.Count };        
        TextboxCount          = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Textbox" | Measure-Object | % { $_.Count };
        RectangleCount        = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Rectangle" | Measure-Object | % { $_.Count };
        ImageCount            = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Image" | Measure-Object | % { $_.Count };
        LineCount             = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Line" | Measure-Object | % { $_.Count };
        TablixCount           = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Tablix" | Measure-Object | % { $_.Count };
        MapCount              = Select-Xml -Xml $reportXml -Namespace $ns -XPath "//ns:Map" | Measure-Object | % { $_.Count };
        SparkLineCount        = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//ns:Chart[./rd:DesignerMode[text()="Sparkline"]]' | Measure-Object | % { $_.Count };
        DataBarCount          = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//ns:Chart[./rd:DesignerMode[text()="DataBar"]]' | Measure-Object | % { $_.Count };
        ChartCount            = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//ns:Chart[not(./rd:DesignerMode)]' | Measure-Object | % { $_.Count };
        GaugePanelCount       = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//ns:GaugePanel' | Measure-Object | % { $_.Count };
        RadialGaugesCount     = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//ns:RadialGauge' | Measure-Object | % { $_.Count };
        LinearGaugesCount     = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//ns:LinearGauge' | Measure-Object | % { $_.Count };
        IndicatorsCount       = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//ns:StateIndicator' | Measure-Object | % { $_.Count };
        GaugeLabelsCount      = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//ns:GaugeLabel' | Measure-Object | % { $_.Count };
        UserIdVariableCount   = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//*[contains(text(),"User!UserID")]' | Measure-Object | % { $_.Count };
        ExecutionTimeVariableCount   = Select-Xml -Xml $reportXml -Namespace $ns -XPath '//*[contains(text(),"Globals!ExecutionTime")]' | Measure-Object | % { $_.Count };
    }

    $dataSourcesArray = @()
    foreach ($dataSource in $reportXml.Report.DataSources.DataSource) {
        $dataSourceInfo = [PSCustomObject]@{
            ProjectUID       = $projectUID;
            ReportUID        = $reportUID;
            ReportID         = $reportXml.Report.ReportID;
            DataSourceUID    = [guid]::NewGuid();
            DataSourceID     = $dataSource.DataSourceID;
            Name             = $dataSource.Name; 
            Extension        = $dataSource.ConnectionProperties.DataProvider;
            ConnectionType   = GetConnectionType $dataSource.ConnectionProperties.DataProvider
            ConnectionString = $dataSource.ConnectionProperties.ConnectString;
            SharedDataSourceUID = $sharedDataSourcesArray | Where-Object {$_.ProjectUID -eq $projectUID -and $_.Name -eq $dataSource.DataSourceReference} | Select-Object -Property SharedDataSourceUID -ExpandProperty SharedDataSourceUID;
        }
        # if Shared Data Source is not found, set a dummy value
        if ($dataSourceInfo.SharedDataSourceUID -eq $null -and $dataSource.DataSourceReference -ne $null) {
            $dataSourceInfo.SharedDataSourceUID = $dataSource.DataSourceReference
        }
        $dataSourcesArray += $dataSourceInfo
    }

    $dataSetsArray = @()
    foreach ($dataSet in $reportXml.Report.DataSets.DataSet) {
        $dataSetInfo = [PSCustomObject]@{
            ProjectUID            = $projectUID;
            ReportUID             = $reportUID;
            ReportID              = $reportXml.Report.ReportID;
            DataSetUID            = [guid]::NewGuid();
            Name                  = $dataSet.Name
            DataSourceReference   = $dataSet.Query.DataSourceName;
            CommandType           = if ($dataSet.Query.CommandType) { $dataSet.Query.CommandType } else { "Query" }
            CommandText           = ""; #$dataSet.Query.CommandText;
            ParametersCount       = $dataSet.Query.QueryParameters.ChildNodes.Count;
            FieldsCount           = $dataSet.Fields.ChildNodes.Count;
            QueryFieldsCount      = Select-Xml -Xml $dataSet -Namespace $ns -XPath "//ns:DataSets//ns:DataSet[@Name='$($dataSet.Name)']//ns:Fields//ns:Field//ns:DataField" | Measure-Object | % { $_.Count };
            CalculatedFieldsCount = Select-Xml -Xml $dataSet -Namespace $ns -XPath "//ns:DataSets//ns:DataSet[@Name='$($dataSet.Name)']//ns:Fields//ns:Field//ns:Value" | Measure-Object | % { $_.Count };
            FiltersCount          = $dataSet.Filters.ChildNodes.Count;
            SharedDataSetUID      = $sharedDatasetsArray | Where-Object {$_.ProjectUID -eq $projectUID -and $_.Name -eq $dataSet.SharedDataSet.SharedDataSetReference} | Select-Object -Property SharedDataSetUID -ExpandProperty SharedDataSetUID;
        }
        # if Shared Dataset is not found, set a dummy value
        if ($dataSetInfo.SharedDataSetUID -eq $null -and $dataSet.SharedDataSet.SharedDataSetReference -ne $null) {
            $dataSetInfo.SharedDataSetUID = $dataSet.SharedDataSet.SharedDataSetReference
        }
        $dataSetsArray += $dataSetInfo
    }

    return $reportInfo, $dataSourcesArray, $dataSetsArray
}


function ProcessSharedDataSource ($projectUID, $projectFileDirectory, $dataSourceFile)
{
    $dataSourceFilePath = Join-Path -Path $projectFileDirectory -ChildPath $dataSourceFile
    Write-Host "Processing Shared Data Source file: ", $dataSourceFilePath -ForegroundColor Yellow

    $dataSourceInfo = GetSharedDataSourceInfo $projectUID $dataSourceFilePath
    return $dataSourceInfo
}


function ProcessSharedDataSet ($projectUID, $projectFileDirectory, $dataSetFile)
{
    $dataSetFilePath = Join-Path -Path $projectFileDirectory -ChildPath $dataSetFile
    Write-Host "Processing Shared DataSet file: ", $dataSetFilePath -ForegroundColor Yellow

    $dataSetInfo = GetSharedDataSetInfo $projectUID $dataSetFilePath
    return $dataSetInfo 
}


function ProcessReport ($projectUID, $projectFileDirectory, $reportFile)
{
    $reportFilePath = Join-Path -Path $projectFileDirectory -ChildPath $reportFile
    Write-Host "Processing Report file: ", $reportFilePath -ForegroundColor Yellow

    $reportInfo, $reportDataSources, $reportDataSets = GetReportInfo $projectUID $reportFilePath
    return $reportInfo, $reportDataSources, $reportDataSets
}


try {
    $originalLocation = Get-Location
    Set-Location $InputFolder

    $projectFiles = Get-ChildItem -Path $InputFolder -Recurse -Filter *.rptproj

    $projectsArray = @()
    $reportsArray = @()
    $sharedDataSourcesArray = @()
    $dataSourcesArray = @()
    $sharedDatasetsArray = @()
    $dataSetsArray = @()


    # create dummy objects to avoid PowerBI import errors
    $projectInfo = [PSCustomObject]@{
        ProjectUID="";
        ProjectPath="";
        Name=""; 
        TargetServerVersion=""; 
        TargetServerUrl=""; 
        OverwriteDataSources=""; 
        OverwriteDatasets=""; 
        ConfigurationsCount="";
        ReportsCount="";
        SharedDataSourcesCount="";
        SharedDatasetsCount="";
    }
    $projectsArray += $projectInfo
    $sharedDataSourcesArray += GetSharedDataSourceInfo "", ""
    $sharedDatasetsArray += GetSharedDataSetInfo "", ""
    $reportInfo, $dataSourceInfo, $dataSetInfo = GetReportInfo "", ""
    $reportsArray += $reportInfo
    $dataSourcesArray += $dataSourceInfo
    $dataSetsArray += $dataSetInfo


    foreach ($projectFile in $projectFiles) {
        Write-Host "Processing project file: ", ($projectFile.FullName) -ForegroundColor Cyan

        [xml]$projectXml = Get-Content $projectFile.FullName

        # Use new unique ID to avoid duplicate IDS which frequently happen
        $projectUID = [guid]::NewGuid()

        # Use either Debug or Release configuration, whichever is found first
        if ($projectXml.Project.Configurations) {
            $configurationsCount = $projectXml.Project.Configurations.Configuration.Length
    
            $configuration = $projectXml.Project.Configurations.Configuration | Where {$_.Name -eq "Debug" -or $_.Name -eq "Release"} | Select-Object -First 1
            $targetServerVersion = if ($configuration.Options) { $configuration.Options.TargetServerVersion } else { "" }
            $targetServerUrl = if ($configuration.Options) { $configuration.Options.TargetServerURL } else { "" }
            $overwriteDataSources = if ($configuration.Options) { $configuration.Options.OverwriteDataSources } else { "" }
            $overwriteDatasets = if ($configuration.Options) { $configuration.Options.OverwriteDatasets } else { "" }
        } else {
            $configurationsCount = $projectXml.Project.PropertyGroup | Where {$_.FullPath -ne $null} | Measure-Object | % {$_.Count}

            $configuration = $projectXml.Project.PropertyGroup | Where {$_.FullPath -eq "Debug" -or $_.FullPath -eq "Release"} | Select-Object -First 1
            $targetServerVersion = $configuration.TargetServerVersion
            $targetServerUrl = $configuration.TargetServerURL
            $overwriteDataSources = $configuration.OverwriteDataSources
            $overwriteDatasets = $configuration.OverwriteDatasets
        }

        # NEW project file format
        foreach ($itemGroup in $projectXml.Project.ItemGroup) {
            foreach ($dataSource in $itemGroup.DataSource) { 
                $dataSourceInfo = ProcessSharedDataSource $projectUID $projectFile.Directory $dataSource.Include
                if ($dataSourceInfo) {
                    $sharedDataSourcesArray += $dataSourceInfo
                }
            }

            foreach ($dataSet in $itemGroup.DataSet) { 
                $dataSetInfo = ProcessSharedDataSet $projectUID $projectFile.Directory $dataSet.Include
                if ($dataSetInfo) {
                    $sharedDatasetsArray += $dataSetInfo
                }
            }
        
            foreach ($report in $itemGroup.Report) { 
                $reportInfo, $reportDataSources, $reportDataSets = ProcessReport $projectUID $projectFile.Directory $report.Include
                if ($reportInfo) {
                    $reportsArray += $reportInfo
                    $dataSourcesArray += $reportDataSources
                    $dataSetsArray += $reportDataSets
                }
            }
        }

        # OLD project file format
        foreach ($dataSource in $projectXml.Project.DataSources.ProjectItem) { 
            $dataSourceInfo = ProcessSharedDataSource $projectUID $projectFile.Directory $dataSource.FullPath
            if ($dataSourceInfo) {
                $sharedDataSourcesArray += $dataSourceInfo
            }
        }

        foreach ($dataSet in $projectXml.Project.DataSets.ProjectItem) { 
            $dataSetInfo = ProcessSharedDataSet $projectUID $projectFile.Directory $dataSet.FullPath
            if ($dataSetInfo) {
                $sharedDatasetsArray += $dataSetInfo
            }
        }
        
        foreach ($report in $projectXml.Project.Reports.ProjectItem) { 
            $reportInfo, $reportDataSources, $reportDataSets = ProcessReport $projectUID $projectFile.Directory $report.FullPath
            if ($reportInfo) {
                $reportsArray += $reportInfo
                $dataSourcesArray += $reportDataSources
                $dataSetsArray += $reportDataSets
            }
        }


        $projectInfo = [PSCustomObject]@{
                ProjectUID=$projectUID;
                ProjectPath= Resolve-Path -Path $projectFile.FullName -Relative
                Name=$projectFile.Name; 
                TargetServerVersion=$targetServerVersion; 
                TargetServerUrl=$targetServerUrl; 
                OverwriteDataSources=$overwriteDataSources; 
                OverwriteDatasets=$overwriteDatasets; 
                ConfigurationsCount=$configurationsCount;
                ReportsCount=0;
                SharedDataSourcesCount=$sharedDataSourcesArray.Count;
                SharedDatasetsCount=$sharedDataSetsArray.Count;
            }
        $projectsArray += $projectInfo
    }


    $FileTimestamp = Get-Date -Format yyyyMMddHHmmss

    $projectsArray | Export-Csv -Path "$OutputFolder\Projects_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
    $reportsArray | Export-Csv -Path "$OutputFolder\Reports_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
    $dataSourcesArray | Export-Csv -Path "$OutputFolder\DataSources_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
    $dataSetsArray | Export-Csv -Path "$OutputFolder\DataSets_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
    $sharedDataSourcesArray | Export-Csv -Path "$OutputFolder\SharedDataSources_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
    $sharedDatasetsArray | Export-Csv -Path "$OutputFolder\SharedDataSets_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
} 
finally {
    Set-Location $originalLocation

}

$finishTime = Get-Date

Write-Host "Total Projects analyzed:             ", $projectsArray.Count -ForegroundColor Magenta
Write-Host "Total Shared Data Sources analyzed:  ", $sharedDataSourcesArray.Count -ForegroundColor Magenta
Write-Host "Total Shared DataSets analyzed:      ", $sharedDatasetsArray.Count -ForegroundColor Magenta
Write-Host "Total Reports analyzed:              ", $reportsArray.Count -ForegroundColor Magenta

Write-Host "Program Start Time:                  ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:                 ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time:                ", ($finishTime-$startTime) -ForegroundColor Green
