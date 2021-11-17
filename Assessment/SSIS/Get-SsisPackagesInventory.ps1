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
# Description: The script assesses SSIS projects source code and generates output CSV-files which can be used for further analysis.
#   The script requires x86 PowerShell and SSIS components 2012 or higher. 
#
###################################################################################################################################

#Requires -Version 5.1


param(
    [Parameter(Mandatory=$false, HelpMessage="Path to SSIS root folder")]
    [string]
    $RootFolder = "C:\temp",

    [Parameter(Mandatory=$false, HelpMessage="Path to output folder")]
    [string]
    $OutputFolder = "C:\temp"
)


function Load-SsisAssemblies {
    param (
        [ValidateSet(11,12,13,14,15)]
        [int]$SsisVersion
    )
    try {
        #Add-Type -Path 'C:\WINDOWS\Microsoft.Net\assembly\GAC_MSIL\Microsoft.SqlServer.ManagedDTS\v4.0_13.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.ManagedDTS.dll'
        #Add-Type -Path 'C:\WINDOWS\Microsoft.Net\assembly\GAC_MSIL\Microsoft.SqlServer.DTSPipelineWrap\v4.0_13.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.DTSPipelineWrap.dll'
        #Add-Type -Path 'C:\WINDOWS\Microsoft.Net\assembly\GAC_32\Microsoft.SqlServer.DTSRuntimeWrap\v4.0_13.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.DTSRuntimeWrap.dll'

        Add-Type -AssemblyName "Microsoft.SqlServer.ManagedDTS, Version=$SsisVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction SilentlyContinue
        Add-Type -AssemblyName "Microsoft.SqlServer.DTSPipelineWrap, Version=$SsisVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction SilentlyContinue
        Add-Type -AssemblyName "Microsoft.SqlServer.DTSRuntimeWrap, Version=$SsisVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}


if ([Environment]::Is64BitProcess) {
    Write-Error -Message "This script must be executed using PowerShell 32-bit" -Category InvalidOperation -ErrorAction Stop
    #exit(1)
}

$startTime = Get-Date

$ssisLoaded = $false
if (!$ssisLoaded) { $ssisLoaded = Load-SsisAssemblies 15 } 
if (!$ssisLoaded) { $ssisLoaded = Load-SsisAssemblies 14 } 
if (!$ssisLoaded) { $ssisLoaded = Load-SsisAssemblies 13 } 
if (!$ssisLoaded) { $ssisLoaded = Load-SsisAssemblies 12 } 
if (!$ssisLoaded) { $ssisLoaded = Load-SsisAssemblies 11 } 

if (!$ssisLoaded) {
    Write-Error -Message "This script could not load SSIS assemblies" -Category InvalidOperation -ErrorAction Stop
    #exit(1)
}



$pkg = New-Object Microsoft.SqlServer.Dts.Runtime.Package
$app = New-Object Microsoft.SqlServer.Dts.Runtime.Application


function GetContainerExecutables($ProjectUID, $PackageUID, $Package, $Container)
{
    $containerExecutables = @()
    $containerDataFlows = @()
    $containerDataFlowComponents = @()
    $containerEventHandlers = @()

    foreach ($executable in $Container.Executables) {
        if ($executable.CreationName.StartsWith("SSIS.Pipeline")) {
            $taskHost = [Microsoft.SqlServer.Dts.Runtime.TaskHost]$executable
            $dataFlowTask = [System.Runtime.InteropServices.Marshal]::CreateWrapperOfType($taskHost.InnerObject, [Microsoft.SQLServer.DTS.pipeline.Wrapper.MainPipeClass])
            $dataFlowUID = [guid]::NewGuid()
            $dataFlow = [PSCustomObject]@{
                ProjectUID=$ProjectUID;
                PackageName=$Package.Name;
                PackageID=$Package.ID;
                PackageUID=$PackageUID;
                Name=$executable.Name;
                ID=$executable.ID;
                UID=$dataFlowUID;
                ParentID=$Container.ID;
                ObjectType=$executable.ObjectType;
                AutoAdjustBufferSize=$dataFlowTask.AutoAdjustBufferSize;
                BLOBTempStoragePath=$dataFlowTask.BLOBTempStoragePath;
                DefaultBufferMaxRows=$dataFlowTask.DefaultBufferMaxRows;
                DefaultBufferSize=$dataFlowTask.DefaultBufferSize
            }
            $containerDataFlows += $dataFlow
            
            foreach ($component in $dataFlowTask.ComponentMetadataCollection) {     
                # Identify component type either by ComponentClassID (built-in components) or Description (.NET components)
                $componentType = $app.PipelineComponentInfos `
                        | Where { $_.ID -eq $component.ComponentClassID -or ($_.Description -eq $component.Description -and $_.Description -ne "") } `
                        | Select -Property Name -ExpandProperty Name
                if ($componentType -eq $null) {
                    # Identify 3rd party component type by UserComponentTypeName (e.g. PDW Destination Adapter)
                    $componentType = $app.PipelineComponentInfos | Where { $_.ID -like $component.CustomPropertyCollection["UserComponentTypeName"].Value } | Select -Property Name -ExpandProperty Name
                }
                $dataFlowComponent = [PSCustomObject]@{
                    ProjectUID=$ProjectUID;
                    PackageName=$Package.Name;
                    PackageID=$Package.ID;
                    PackageUID=$PackageUID;
                    DataFlowName=$executable.Name;
                    ID=$component.ID;
                    ParentID=$executable.ID;
                    ParentUID=$dataFlowUID;
                    ObjectType=$component.ObjectType;
                    ConnectionManagerID=$(if ($component.RuntimeConnectionCollection.Count -gt 0) {$component.RuntimeConnectionCollection[0].ConnectionManagerID} else {$null});
                    ComponentClassID=$component.ComponentClassID;
                    Name=$component.Name;
                    ContactInfo=$component.ContactInfo;
                    ComponentType=$componentType #$app.PipelineComponentInfos[$component.ComponentClassID].Name;
                }
                $containerDataFlowComponents += $dataFlowComponent
            }
        }

        $executableInfo = [PSCustomObject]@{
                ProjectUID=$ProjectUID;
                PackageName=$Package.Name;
                PackageID=$Package.ID;
                PackageUID=$PackageUID;
                ID=$executable.ID; 
                UID=[guid]::NewGuid();
                Name=$executable.Name; 
                #Type=$executable.CreationName;
                Type=$(if ($app.TaskInfos[$executable.CreationName]) {$app.TaskInfos[$executable.CreationName].Name} else {$executable.CreationName});
                HasExpressions=$executable.HasExpressions; 
                NestedExecutables=$executable.Executables.Count;
                EventHandlers=$executable.EventHandlers.Count;
                Variables= $executable.Variables | Where-Object { $_.Namespace -eq 'User' -and $_.Parent.ID -eq $executable.ID } | measure | % {$_.Count};
                ParentID=$executable.Parent.ID;
                PackagePath=$executable.GetPackagePath();
                SqlStatementSourceType=$executable.InnerObject.SqlStatementSourceType;
                IsStoredProcedure=$executable.InnerObject.IsStoredProcedure;
                ScriptLanguage=$executable.InnerObject.ScriptLanguage;
            }
        $containerExecutables += $executableInfo

        # Event Handlers
        foreach ($eventHandler in $executable.EventHandlers) {
            $eventHandlerInfo = [PSCustomObject]@{
                    ProjectUID=$ProjectUID;
                    PackageID=$Package.ID;
                    PackageUID=$PackageUID;
                    PackageName=$Package.Name;
                    ParentID=$executable.ID;
                    ParentName=$executable.Name;
                    ID=$eventHandler.ID; 
                    UID=[guid]::NewGuid();
                    Name=$eventHandler.Name; 
                    Type=$eventHandler.CreationName;
                    ExecutablesCount=$eventHandler.Executables.Count;
                }
            $containerEventHandlers += $eventHandlerInfo
        }


        if (($executable.Executables -ne $null) -and ($executable.Executables.Count -gt 0)) {
            $nestedExecutables, $nestedDataFlows, $nestedDataFlowComponents, $nestedEventHandlers = GetContainerExecutables -ProjectUID $ProjectUID -PackageUID $PackageUID -Package $Package -Container $executable
            $containerExecutables += $nestedExecutables
            $containerDataFlows += $nestedDataFlows
            $containerDataFlowComponents += $nestedDataFlowComponents
            $containerEventHandlers += $nestedEventHandlers
        }
    }

    return $containerExecutables, $containerDataFlows, $containerDataFlowComponents, $containerEventHandlers
}



function GetPackageInfo($ProjectUID, $PackageUID, $PackageFilePath)
{
    $pkg = $app.LoadPackage($packageFilePath, $null)
    
    $packageConnections = @()
    $packageExecutables = @()
    $eventHandlers = @()
    $packageDataFlows = @()
    $packageDataFlowComponents = @()

    # Package connection managers
    foreach ($connection in $pkg.Connections)
    {

        try {
            $connectionData = @{}
            $connectionString = $connection.connectionString

            if ($connectionString.Contains("\")) {
                $connectionData = $connectionString.Replace("\","\\") -replace ';',"`r`n" | ConvertFrom-StringData
            } else {
                $connectionData = $connectionString -replace ';',"`r`n" | ConvertFrom-StringData
            }
        } catch {}

        $connManagerInfo = [PSCustomObject]@{
                ProjectUID=$ProjectUID;
                PackageID=$pkg.ID;
                PackageUID=$PackageUID;
                PackageName=$pkg.Name;
                ID=$connection.ID; 
                Name=$connection.Name; 
                ConnectionType=$connection.CreationName;
                ProtectionLevel=$connection.ProtectionLevel;
                HasExpressions=$connection.HasExpressions;
                ConnectionString=$connectionString;
                Provider=$connectionData["Provider"];
                DataSource=$connectionData["Data Source"];
                InitialCatalog=$connectionData["Initial Catalog"];
            }
        $packageConnections += $connManagerInfo
    }

    # Event Handlers
    foreach ($eventHandler in $pkg.EventHandlers) {
        $eventHandlerInfo = [PSCustomObject]@{
                ProjectUID=$ProjectUID;
                PackageID=$pkg.ID;
                PackageUID=$PackageUID;
                PackageName=$pkg.Name;
                ParentID=$null;
                ParentName=$null;
                ID=$eventHandler.ID; 
                UID=[guid]::NewGuid();
                Name=$eventHandler.Name; 
                Type=$eventHandler.CreationName;
                ExecutablesCount=$eventHandler.Executables.Count;
            }
        $eventHandlers += $eventHandlerInfo
    }

    # Executables
    $containerExecutables, $containerDataFlows, $containerDataFlowComponents, $containerEventHandlers = GetContainerExecutables -ProjectUID $ProjectUID -PackageUID $PackageUID -Package $pkg -Container $pkg
    $packageExecutables += $containerExecutables
    $packageDataFlows += $containerDataFlows
    $packageDataFlowComponents += $containerDataFlowComponents
    $eventHandlers += $containerEventHandlers

    # Package Info
    $userVariables = $pkg.Variables | Where-Object { $_.Namespace -eq 'User' }
    $packageInfo = [PSCustomObject]@{
        ID = $pkg.ID;
        UID = $PackageUID;
        Name = $pkg.Name;
        ProjectUID = $ProjectUID;
        ProjectID = $ProjectID;
        Variables = $userVariables.Count;
        HasExpressions = $pkg.HasExpressions;
        LocaleID = $pkg.LocaleID;
        ProtectionLevel = $pkg.ProtectionLevel;
        PackageFilePath=$packageFilePath;
    }

    return $packageInfo, $packageConnections, $packageExecutables, $packageDataFlows, $packageDataFlowComponents, $eventHandlers
}


$childFolders = Get-ChildItem -Path $RootFolder -Recurse -Directory

$projectFiles = Get-ChildItem -Path $RootFolder -Recurse -Filter *.dtproj
$connFiles = Get-ChildItem -Path $RootFolder -Recurse -Filter *.conmgr

$totalProjects = $projectFiles.Count
$totalPackages = 0

$projectsInfo = @()
$projectParamsInfo = @()
$connectionManagersInfo = @()
$packagesInfo = @()
$packageConnectionsInfo = @()
$packageExecutablesInfo = @()
$packageDataFlowsInfo = @()
$packageDataFlowComponentsInfo = @()
$eventHandlersInfo = @()

$pipelineComponentInfos = $app.PipelineComponentInfos

foreach ($projectFile in $projectFiles) {
    Write-Host "Processing project file: ", ($projectFile.FullName) -ForegroundColor Cyan

    [xml]$projectFileXml = Get-Content $projectFile.FullName
    $deploymentModel = $projectFileXml.Project.DeploymentModel

    $projectUID = [guid]::NewGuid()

    if ($deploymentModel -eq "Package") {
        $projectID = ""
        $protectionLevel = ""
        $projectName = $projectFile.BaseName
        $packagesCount = $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.DTSPackages.ChildNodes.Count
        $connectionManagersCount = $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.Project.ConnectionManagers.ChildNodes.Count
        $projectConfiguration = $projectFileXml.Project.Configurations.Configuration | Where-Object {$_.Name -eq "Development"}
        if ($projectConfiguration -eq $null) {
            $projectConfiguration = $projectFileXml.Project.Configurations.Configuration[0]
        }
        $targetServerVersion = $projectConfiguration.Options.TargetServerVersion

        foreach ($packageNode in $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.DTSPackages.ChildNodes) {
            $packageFullPath = Join-Path -Path $projectFile.Directory -ChildPath $packageNode.FullPath
            Write-Host "Processing package file: ", $packageFullPath -ForegroundColor Yellow

            if (($packagesInfo | Where-Object {$_.PackageFilePath -eq $packageFullPath}) -ne $null) {
                # Duplicate package, possible in rare cases
                continue
            }

            $packageUID = [guid]::NewGuid()
            $packageInfo, $packageConnections, $packageExecutables, $packageDataFlows, $packageDataFlowComponents, $eventHandlers = GetPackageInfo -ProjectUID $projectUID -PackageUID $packageUID -PackageFilePath $packageFullPath
            $packagesInfo += $packageInfo
            $packageConnectionsInfo += $packageConnections
            $packageExecutablesInfo += $packageExecutables
            $packageDataFlowsInfo += $packageDataFlows
            $packageDataFlowComponentsInfo += $packageDataFlowComponents
            $eventHandlersInfo += $eventHandlers
            $totalPackages += 1
        }
    } else {
        $idNode = $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.Project.Properties.ChildNodes | Where-Object { $_.Name -eq 'ID' }
        $projectID = $idNode.'#text'
        $nameNode = $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.Project.Properties.ChildNodes | Where-Object { $_.Name -eq 'Name' }
        $projectName = $nameNode.'#text'
        $protectionLevel = $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.Project.ProtectionLevel
        $packagesCount = $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.Project.Packages.ChildNodes.Count
        $connectionManagersCount = $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.Project.ConnectionManagers.ChildNodes.Count
        $projectConfiguration = $projectFileXml.Project.Configurations.Configuration | Where-Object {$_.Name -eq "Development"}
        if ($projectConfiguration -eq $null) {
            $projectConfiguration = $projectFileXml.Project.Configurations.Configuration[0]
        }
        $targetServerVersion = $projectConfiguration.Options.TargetServerVersion


        foreach ($connManagerNode in $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.Project.ConnectionManagers.ChildNodes) {
            $connManagerName = $connManagerNode.Name
            $connManagerFullPath = Join-Path -Path $projectFile.Directory -ChildPath $connManagerNode.Name
            $projectFullPath = $projectFile.FullName
            
            [xml]$connManagerFileXml = Get-Content $connManagerFullPath
            $connManagerID = $connManagerFileXml.ConnectionManager.DTSID
            $connManagerType = $connManagerFileXml.ConnectionManager.CreationName

            try {
                $connectionData = @{}
                if ($connManagerType -eq "SMTP") {
                    $connectionString = $connManagerFileXml.ConnectionManager.ObjectData.SmtpConnectionManager.ConnectionString
                } else {
                    $connectionString = $connManagerFileXml.ConnectionManager.ObjectData.ConnectionManager.ConnectionString
                }
                if ($connectionString.Contains("\")) {
                    $connectionData = $connectionString.Replace("\","\\") -replace ';',"`r`n" | ConvertFrom-StringData
                } else {
                    $connectionData = $connectionString -replace ';',"`r`n" | ConvertFrom-StringData
                }
            } catch {}

            $connManagerInfo = [PSCustomObject]@{
                    ProjectID=$projectID;
                    ProjectUID=$projectUID;
                    ID=$connManagerID; 
                    Type=$connManagerType; 
                    Name=$connManagerName; 
                    ProjectName=$projectName; 
                    ConnManagerFilePath=$connManagerFullPath; 
                    ProjectFilePath=$projectFullPath
                    ConnectionString=$connectionString;
                    Provider=$connectionData["Provider"];
                    DataSource=$connectionData["Data Source"];
                    InitialCatalog=$connectionData["Initial Catalog"];
                }
            $connectionManagersInfo += $connManagerInfo
        }

        foreach ($packageNode in $projectFileXml.Project.DeploymentModelSpecificContent.Manifest.Project.Packages.ChildNodes) {
            $packageFullPath = Join-Path -Path $projectFile.Directory -ChildPath $packageNode.Name
            Write-Host "Processing package file: ", $packageFullPath -ForegroundColor Yellow

            $packageUID = [guid]::NewGuid()
            $packageInfo, $packageConnections, $packageExecutables, $packageDataFlows, $packageDataFlowComponents, $eventHandlers = GetPackageInfo -ProjectUID $projectUID -PackageUID $packageUID -PackageFilePath $packageFullPath
            $packagesInfo += $packageInfo
            $packageConnectionsInfo += $packageConnections
            $packageExecutablesInfo += $packageExecutables
            $packageDataFlowsInfo += $packageDataFlows
            $packageDataFlowComponentsInfo += $packageDataFlowComponents
            $eventHandlersInfo += $eventHandlers
            $totalPackages += 1
        }
    }

    $projectInfo = [PSCustomObject]@{
            UID=$projectUID;
            ID=$projectID; 
            Name=$projectName; 
            DeploymentModel=$deploymentModel; 
            TargetServerVersion=$targetServerVersion; 
            ProtectionLevel=$protectionLevel; 
            Packages=$packagesCount; 
            ConnectionManagers=$connectionManagersCount;
            ProjectFilePath=$projectFile.FullName;
        }
    $projectsInfo += $projectInfo

    $paramsFilePath = Join-Path -Path $projectFile.Directory -ChildPath "Project.params"
    if (Test-Path -Path $paramsFilePath) {
        [xml]$paramsFileXml = Get-Content $paramsFilePath
        foreach ($parameter in $paramsFileXml.Parameters.Parameter) {
            $idNode = $parameter.Properties.ChildNodes | Where-Object { $_.Name -eq 'ID' }
            $requiredNode = $parameter.Properties.ChildNodes | Where-Object { $_.Name -eq 'Required' }
            $sensitiveNode = $parameter.Properties.ChildNodes | Where-Object { $_.Name -eq 'Sensitive' }
            $valueNode = $parameter.Properties.ChildNodes | Where-Object { $_.Name -eq 'Value' }
            $dataTypeNode = $parameter.Properties.ChildNodes | Where-Object { $_.Name -eq 'DataType' }
            if ($idNode -ne $null) {
                $paramInfo = [PSCustomObject]@{
                        ID=$idNode.'#text'; 
                        Name=$parameter.Name; 
                        ProjectUID=$projectUID;
                        ProjectID=$projectID;
                        Required=$requiredNode.'#text'; 
                        Sensitive=$sensitiveNode.'#text'; 
                        Value=$valueNode.'#text'; 
                        DataType=$dataTypeNode.'#text'; 
                        ParamsFilePath=$paramsFilePath;
                    }
                $projectParamsInfo += $paramInfo
            }
        }
    }
}

# If no Project Parameters found - add dummy item to avoid errors when loading data in PowerBI 
if ($projectParamsInfo.Length -eq 0) {
    $projectParamsInfo += [PSCustomObject]@{ 
            ID=""; 
            Name=""; 
            ProjectUID=""; 
            ProjectID=""; 
            Required="";  
            Sensitive=""; 
            Value=""; 
            DataType=""; 
            ParamsFilePath=""; }
}

# If no Connection Managers found - add dummy item to avoid errors when loading data in PowerBI 
if ($connectionManagersInfo.Length -eq 0) {
    $connectionManagersInfo += [PSCustomObject]@{ 
            ProjectID=""; 
            ProjectUID=""; 
            ID=""; 
            Type=""; 
            Name=""; 
            ProjectName=""; 
            ConnManagerFilePath=""; 
            ProjectFilePath="";
            ConnectionString="";
            Provider="";
            DataSource="";
            InitialCatalog="";
        }
}

# If no Event Handlers found - add dummy item to avoid errors when loading data in PowerBI 
if ($eventHandlerInfo.Length -eq 0) {
    $eventHandlerInfo += [PSCustomObject]@{
            ProjectUID="";
            PackageID="";
            PackageUID="";
            PackageName="";
            ParentID="";
            ParentName="";
            ID=""; 
            UID="";
            Name=""; 
            Type="";
            ExecutablesCount="";
        }
}


$FileTimestamp = Get-Date -Format yyyyMMddHHmmss

$projectsInfo | Export-Csv -Path "$OutputFolder\ProjectsSummary_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
$projectParamsInfo | Export-Csv -Path "$OutputFolder\ProjectParams_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
$connectionManagersInfo | Export-Csv -Path "$OutputFolder\ConnectionManagers_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
$packagesInfo | Export-Csv -Path "$OutputFolder\PackagesSummary_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
$packageConnectionsInfo | Export-Csv -Path "$OutputFolder\PackageConnections_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
$packageExecutablesInfo | Export-Csv -Path "$OutputFolder\Executables_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
$packageDataFlowsInfo | Export-Csv -Path "$OutputFolder\DataFlows_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
$packageDataFlowComponentsInfo | Export-Csv -Path "$OutputFolder\DataFlowComponents_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 
$eventHandlersInfo | Export-Csv -Path "$OutputFolder\EventHandlers_$FileTimestamp.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation -Force 


$finishTime = Get-Date

Write-Host "Total Projects analyzed: ", $totalProjects -ForegroundColor Magenta
Write-Host "Total Packages analyzed: ", $totalPackages -ForegroundColor Magenta

Write-Host "Program Start Time:      ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:     ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time:    ", ($finishTime-$startTime) -ForegroundColor Green
