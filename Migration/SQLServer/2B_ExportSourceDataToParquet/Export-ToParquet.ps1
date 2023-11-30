#======================================================================================================================#
#                                                                                                                      #
#  AzureSynapseScriptsAndAccelerators - PowerShell and T-SQL Utilities                                                 #
#                                                                                                                      #
#  This utility was developed to aid SMP/MPP migrations to Azure Synapse Analytics.                                    #
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
# January 2022
# Description: The script extracts data from SQL Server or APS databases to Parquet files for further import into Azure Synapse Analytics.
#   The script uses one of these libraries to generate Parquet-files.
#   ParquetSharp NuGet package - https://www.nuget.org/packages/ParquetSharp
#   Parquet.Net NuGet package - https://www.nuget.org/packages/Parquet.Net
#
# Contributor: Yoni Sade
# November 2023
# Description: 	Added support for Windows Authentication / Trusted Connection when user skips "-Password" argument
#
###################################################################################################################################

#Requires -Version 7.0

param(
    [Parameter(Mandatory=$false, HelpMessage="Configuration file path")]
    [ValidateScript({
        if( -Not ($_ | Test-Path -PathType Leaf) ) { throw "File $_ does not exist" }
        return $true
    })]
    [string] $ConfigFile = $("$PSScriptRoot\ConfigFile.csv"),

    [Parameter(Mandatory=$true, HelpMessage="The name of SQL Server / APS / PDW instance")]
    [string] $ServerName,

    [Parameter(Mandatory=$true, HelpMessage="User name")]
    [string] $UserName,

    [Parameter(Mandatory=$false, HelpMessage="Password")]
    [SecureString] $Password,

    [Parameter(Mandatory=$false, HelpMessage="Connection timeout")]
    [int] $ConnectionTimeout = 10,

    [Parameter(Mandatory=$false, HelpMessage="Command timeout")]
    [int] $CommandTimeout = 30,

    [Parameter(Mandatory=$false, HelpMessage="Maximum number of rows per rowgroup")]
    [int] $RowsPerRowGroup = 10000000 ,

    [Parameter(Mandatory=$false, HelpMessage="Maximum number of simultaneous jobs")]
    [int] $MaxJobsCount = 4,

    [Parameter(Mandatory=$false, HelpMessage="Use Parquet.NET library or ParquetSharp (default)")]
    [switch] $UseParquetNet 
)

Function Get-AbsolutePath
{
    [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$Path
    ) 

    if ([System.IO.Path]::IsPathRooted($Path) -eq $false) {
        if ($PSScriptRoot) {
            return [IO.Path]::GetFullPath( (Join-Path -Path $PSScriptRoot -ChildPath $Path) )
        } else {
            return [IO.Path]::GetFullPath( (Join-Path -Path $(Get-Location) -ChildPath $Path) )
        }
    } else {
        return $Path
    }
}


function Download-ParquetSharp 
{
    if (-not(Test-Path "$PSScriptRoot\parquetsharp.5.0.0.nupkg\lib\netstandard2.1\ParquetSharp.dll")) {
        $zipFile = "$PSScriptRoot\parquetsharp.5.0.0.nupkg.zip"
        if (-not(Test-Path "$PSScriptRoot\parquetsharp.5.0.0.nupkg.zip")) {
            $url = "https://www.nuget.org/api/v2/package/ParquetSharp/4.0.0"
            Invoke-WebRequest -Uri $url -OutFile $zipFile 
        }
        Expand-Archive -Path $zipFile -DestinationPath "$PSScriptRoot\parquetsharp.5.0.0.nupkg" -Force
    }

#    if (-not(Test-Path "$PSScriptRoot\parquetsharp.6.0.1-beta1.nupkg\lib\netstandard2.1\ParquetSharp.dll")) {
#        $zipFile = "$PSScriptRoot\parquetsharp.6.0.1-beta1.nupkg.zip"
#        if (-not(Test-Path "$PSScriptRoot\parquetsharp.6.0.1-beta1.nupkg.zip")) {
#            $url = "https://www.nuget.org/api/v2/package/ParquetSharp/6.0.1-beta1"
#            Invoke-WebRequest -Uri $url -OutFile $zipFile 
#        }
#        Expand-Archive -Path $zipFile -DestinationPath "$PSScriptRoot\parquetsharp.6.0.1-beta1.nupkg" -Force
#    }
}

function Download-ParquetNet 
{
    if (-not(Test-Path "$PSScriptRoot\parquet.net.3.9.1.nupkg\lib\net5.0\Parquet.dll")) {
        $zipFile = "$PSScriptRoot\parquet.net.3.9.1.nupkg.zip"
        if (-not(Test-Path "$PSScriptRoot\parquet.net.3.9.1.nupkg.zip")) {
            $url = "https://www.nuget.org/api/v2/package/Parquet.Net/3.9.1"
            Invoke-WebRequest -Uri $url -OutFile $zipFile 
        }
        Expand-Archive -Path $zipFile -DestinationPath "$PSScriptRoot\parquet.net.3.9.1.nupkg" -Force
    }

    if (-not(Test-Path "$PSScriptRoot\ironsnappy.1.3.0.nupkg\lib\netstandard2.1\IronSnappy.dll")) {
        $zipFile = "$PSScriptRoot\ironsnappy.1.3.0.nupkg.zip"
        if (-not(Test-Path "$PSScriptRoot\ironsnappy.1.3.0.nupkg.zip")) {
            $url = "https://www.nuget.org/api/v2/package/IronSnappy/1.3.0"
            Invoke-WebRequest -Uri $url -OutFile $zipFile 
        }
        Expand-Archive -Path $zipFile -DestinationPath "$PSScriptRoot\ironsnappy.1.3.0.nupkg" -Force
    }
}


###############################################################################################
# Main logic here
###############################################################################################

if (-not $password) {
    Write-Output "User did not provide password - using Windows based authentication"
} else {
    Write-Output "User did provided password - using SQL Server based authentication"
}

# Download Parquet libraries
if ($UseParquetNet) {
    Download-ParquetNet
} else {
    Download-ParquetSharp 
}

$startTime = Get-Date

$ConfigFile =  Get-AbsolutePath $ConfigFile
$configData = Import-Csv -Path $ConfigFile

$jobs = @( )

foreach ($record in ($configData | Where-Object {$_.Enabled -eq 1})) {
    $database = $record.Database
    $jobName = $record.JobName
    $query = $record.Query
    $filePath = Get-AbsolutePath $record.FilePath
    #Export-Table -Database $database -Table $table -Query $query -FilePath $filePath

    # create export folder in parent script to avoid conflicts when executing simultaneous jobs
    $exportFolderPath = Split-Path -Path $filePath -Parent
    if (-not (Test-Path -Path $exportFolderPath)) {
        New-Item -Path $exportFolderPath -ItemType Directory | Out-Null
    }

    $jobCreated = $false
    while (!$jobCreated) {
        $runningJobs = Get-Job -State Running

        if ($runningJobs.Count -lt $MaxJobsCount) { 
            if ($UseParquetNet) {
                $jobs += Start-Job -Name $jobName `
                    -File $PSScriptRoot\Export-ParquetNet.ps1 `
                    -WorkingDirectory $PSScriptRoot `
                    -ArgumentList $ServerName,$database,$UserName,$Password,$jobName,$query,$filePath,$ConnectionTimeout,$CommandTimeout,$RowsPerRowGroup
            } else {				
                $jobs += Start-Job -Name $jobName `
                    -File $PSScriptRoot\Export-ParquetSharp.ps1 `
                    -WorkingDirectory $PSScriptRoot `
                    -ArgumentList $ServerName,$database,$UserName,$Password,$jobName,$query,$filePath,$ConnectionTimeout,$CommandTimeout,$RowsPerRowGroup
				
            }
            $jobCreated = $true
        } else {
            Start-Sleep -Milliseconds $(Get-Random -Min 50 -Max 200)
        }

        # Print all new output
        Get-Job | Where-Object {$_.HasMoreData} | Receive-Job
$Jobs.ChildJobs.Output | Out-File output.log -Append
        #Get-Job -State Running | Receive-Job
        # Print out all completed jobs
        #Get-Job -State Completed | Receive-Job
        # Remove completed jobs
        #Get-Job -State Completed | Remove-Job
    }
}

# Print output of all remaining jobs
while ($jobsWithOutput = Get-Job | Where-Object {$_.HasMoreData}) {
    $jobsWithOutput | Receive-Job

    Start-Sleep -Milliseconds $(Get-Random -Min 50 -Max 200)
}

# Remove completed jobs. Use $jobs variable to inspect all jobs.
Get-Job -State Completed | Remove-Job

# Forcefully remove jobs
#Get-Job | Remove-Job -Force

# Print all jobs
$jobs

$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
