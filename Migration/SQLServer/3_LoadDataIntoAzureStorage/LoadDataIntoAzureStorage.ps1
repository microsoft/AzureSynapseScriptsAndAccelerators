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
# ======================================================================================================================
# Description:
#       USE this to load files from local machine to Azure Storage
#       Parameters driven configuration file is the input of this powershell scripts 
# =======================================================================================================================
# =======================================================================================================================
# 
# Authors: Faisal Malik and Gaiye "Gail" Zhou
# May 2021
# Use this to set permissions 
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\migratemaster\modules\3_LoadDataIntoAzureStorage\LoadDataIntoAzureStorage.ps1
# Install-Module -Name Az -AllowClobber


Function GetDurations() {
    [CmdletBinding()] 
    param( 
        [Parameter(Position = 1, Mandatory = $true)] [datetime]$StartTime, 
        [Parameter(Position = 1, Mandatory = $true)] [datetime]$FinishTime
    ) 

    $ReturnValues = @{ }
    $Timespan = (New-TimeSpan -Start $StartTime -End $FinishTime)

    $Days = [math]::floor($Timespan.Days)
    $Hrs = [math]::floor($Timespan.Hours) 
    $Mins = [math]::floor($Timespan.Minutes)
    $Secs = [math]::floor($Timespan.Seconds)
    $MSecs = [math]::floor($Timespan.Milliseconds)

    if ($Days -ne 0) {

        $Hrs = $Days * 24 + $Hrs 
    }

   
    $durationText = '' # initialize it! 

    if (($Hrs -eq 0) -and ($Mins -eq 0) -and ($Secs -eq 0)) {
        $durationText = "$MSecs milliseconds." 
    }
    elseif (($Hrs -eq 0) -and ($Mins -eq 0)) {
        $durationText = "$Secs seconds $MSecs milliseconds." 
    }
    elseif ( ($Hrs -eq 0) -and ($Mins -ne 0)) {
        $durationText = "$Mins minutes $Secs seconds $MSecs milliseconds." 
    }
    else {
        $durationText = "$Hrs hours $Mins minutes $Secs seconds $MSecs milliseconds."
    }

    $ReturnValues.add("DurationText",  $durationText)

    $ReturnValues.add("Hours", $Hrs)
    $ReturnValues.add("Minutes", $Mins)
    $ReturnValues.add("Seconds", $Secs)
    $ReturnValues.add("Milliseconds", $MSecs)

    return $ReturnValues

}

function UploadFiles {
    param(
        [string] $AzCopyLocation = "",
        [string[]] $localFolders = "",
        [string] $storageAccountName = "",
        [string] $storageContainerName = "",
        [string] $containerSASURI = ""
    )

    
    ForEach ($folder in $localFolders)
    {
        Write-Host "uploading file from localFolder: $folder"
        [System.Environment]::SetEnvironmentVariable('PATH',$Env:PATH+';' + $AzCopyLocation +'')

        $StartTime = (Get-Date)

        # Upload File using AzCopy
        $ReturnOutput = AzCopy cp $folder $containerSASURI --recursive=true 

        $FinishTime = (Get-Date)
    
        $durations = GetDurations -StartTime $StartTime -FinishTime $FinishTime 
        $runDurationText = $durations.DurationText

        if ($ReturnOutput -match "error")
        {
            #$DisplayMessage = "  Error Uploading Files From : " + $localFolderPath + ". Error: " + $ReturnOutput 
            $DisplayMessage = "  Error Uploading Files From : " + $folder + ". Error: " + $ReturnOutput 
            Write-Host $DisplayMessage -ForegroundColor Red -BackgroundColor Black
        } else {
            $ReturnOutput | ForEach-Object {
                if ($_ -NotMatch "INFO") {
                Write-Host $_ -ForegroundColor Green -BackgroundColor Black 
                }
            }
        #$DisplayMessage = "  Complete Uploading Files From: " + $localFolderPath + "  Duration: $runDurationText "
        $DisplayMessage = "  Complete Uploading Files From: " + $folder + "  Duration: $runDurationText "
        Write-Host $DisplayMessage -ForegroundColor Green -BackgroundColor Black

        }
    }

}


function Get-SasKey {
    Param(
            [string]$subscriptionId = "",
            [string]$storageAccountRG = "",
            [string]$storageAccountName = "",
            [string]$storageContainerName = "",
            [int32]$keyExpirationTimeInMins = 0

    )

    $KeyExpirationTimeInSecs = $keyExpirationTimeInMins * 60


#  Connect to Azure
# Connect-AzAccount
# List Azure Subscriptions
#Get-AzSubscription

Connect-AzAccount  -SubscriptionId $subscriptionId 

# Select right Azure Subscription
# Select-AzSubscription -SubscriptionId $SubscriptionId
 
# Get Storage Account Key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccountRG -AccountName $storageAccountName).Value[0]
 
# Set AzStorageContext
$destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

$StartTime = (Get-Date)
# Generate SAS URI
$containerSASURI = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds($KeyExpirationTimeInSecs) -FullUri -Name $storageContainerName -Permission rw

$FinishTime = (Get-Date)

$durations = GetDurations -StartTime $StartTime -FinishTime $FinishTime
$runDurationText = $durations.DurationText

if (-not([string]::IsNullOrWhiteSpace($containerSASURI))) {
    $DisplayMessage = "  Successfully Generated SAS Key for Container: " + $storageContainerName + "  Duration: $runDurationText "
    Write-Host $DisplayMessage -ForegroundColor Green -BackgroundColor Black
}
else {
    $DisplayMessage = "  Error Generating SAS Key for Container: " + $storageContainerName 
    Write-Host $DisplayMessage -ForegroundColor Red -BackgroundColor Black
}
#Load-DataFileToBlob -containerSASURI $containerSASURI
return "$containerSASURI"
} 

########################################################################################
# Main Program Starts here
########################################################################################


$ProgramStartTime = (Get-Date)

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location -Path $ScriptPath  


# Get Json File Input 
$defaultJsonCfgFile = "upload_config.json"

$jconCfgFile = Read-Host -prompt "Enter the Config File Name or press 'Enter' to accept the default [$($defaultJsonCfgFile)]"
if([string]::IsNullOrWhiteSpace($jconCfgFile)) {
        $jconCfgFile = $defaultJsonCfgFile
    }

$JsonCfgFileFullPath = join-path $ScriptPath  $jconCfgFile
if (!(test-path $JsonCfgFileFullPath )) {
        Write-Host "Could not find Translate Config File: $JsonCfgFileFullPath " -ForegroundColor Red
        break 
    }
    
$JsonConfig = Get-Content -Path $JsonCfgFileFullPath | ConvertFrom-Json 
    

$AzCopyFullPath = $JsonConfig.AzCopyPath
$AzureSubscriptionID = $JsonConfig.AzureSubscriptionID
$AzureResourceGroup = $JsonConfig.AzureResourceGroup
$StorageAccountName = $JsonConfig.StorageAccountName
$GenerateSASKey = $JsonConfig.GenerateSASKey
$SASKey = $JsonConfig.SASKey
$KeyExpirationTimeInHours = $JsonConfig.KeyExpirationTimeInHours
$ContainerName = $JsonConfig.ContainerName
$LocalFolders = $JsonConfig.FoldersToUpload

#### Checking all the parameters received from configuration file. If anything is bad, we exit early to avoid addtiinoal work. 
if ([string]::IsNullOrWhiteSpace($AzCopyFullPath))
{
    Write-Host "AzCopyPath was not specified. Check your JSON config file." -ForegroundColor red 
    break 
}
# Check the path exists or not 
if (-not (Test-Path -Path $AzCopyFullPath))
{
    Write-Host "AzCopyPath you specified ($AzCopyFullPath) does not exist. Please download AzCopy and specify the location of the azcopy.exe in the .json config file or Check your JSON config file." -ForegroundColor red 
    break 
}

if ([string]::IsNullOrWhiteSpace($AzureSubscriptionID))
{
    Write-Host "AzureSubscriptionID was not specified. Check your JSON config file. " -ForegroundColor red 
    break 
}
if ([string]::IsNullOrWhiteSpace($AzureResourceGroup))
{
    Write-Host "AzureResourceGroup was not specified. Check your JSON config file. " -ForegroundColor red 
    break 
}
if ([string]::IsNullOrWhiteSpace($StorageAccountName))
{
    Write-Host "StorageAccountName was not specified. Check your JSON config file. " -ForegroundColor red 
    break 
}
if ([string]::IsNullOrWhiteSpace($GenerateSASKey))
{
    Write-Host "GenerateSASKey was not specified. Check your JSON config file. " -ForegroundColor red 
    break 
}
if (($GenerateSASKey.toUpper() -eq "YES") -or ($GenerateSASKey.toUpper() -eq "Y"))
{
    Write-Host "Based on the configuration file you provided, you wish to generate a SAS key. Will do this once you logged into Azure. " -ForegroundColor Green 
    if ([string]::IsNullOrWhiteSpace($KeyExpirationTimeInHours))
    {
        Write-Host "KeyExpirationTimeInHours was not specified. Check your JSON config file. " -ForegroundColor red 
        break 
    }
}
else {
    Write-Host "Based on the configuraiton file you provided, you wish to provide your own SAS Key." -ForegroundColor Green
    if ([string]::IsNullOrWhiteSpace($SASKey))
    {
        Write-Host "You wished to provide you own SAS key. But the SASKey field is empty. Check your JSON config file. " -ForegroundColor red 
        break 
    }
}
if ([string]::IsNullOrWhiteSpace($ContainerName))
{
    Write-Host "Container Name was not specified. Check your JSON config file. " -ForegroundColor red 
    break 
}

# 
$KeyExpirationTimeInMins = ([int]$KeyExpirationTimeInHours)*60 

try {
    if ( ($GenerateSASKey.toUpper() -eq 'YES') -or ($GenerateSASKey.toUpper() -eq 'Y') )
    {

        Write-Host "You need to log into your Azure Account. Please be on the lookout for a popup login window "  -ForegroundColor Magenta -BackgroundColor Black
        $SASKey = (Get-SasKey -subscriptionId $AzureSubscriptionID `
        -storageAccountRG $AzureResourceGroup `
        -storageAccountName $StorageAccountName `
        -storageContainerName $ContainerName `
        -keyExpirationTimeInMins $keyExpirationTimeInMins `
        $containerSASURI)[-1]

      Write-Output "SAS Key generated:$SASKey"
    }
    UploadFiles -AzCopyLocation $AzCopyFullPath `
    -localFolders $LocalFolders `
    -storageAccountName $StorageAccountName `
    -storageContainerName $StorageContainerName `
    -containerSASURI $SASKey

}
catch [Exception] {
    Write-Warning $_.Exception.Message
}

$ProgramFinishTime = (Get-Date)

$durations = GetDurations  -StartTime  $ProgramStartTime -FinishTime $ProgramFinishTime

$durationText = $durations.DurationText

Write-Host "  Total elapsed time of script execution: $durationText " -ForegroundColor Magenta -BackgroundColor Black

Write-Host "  Started at: $ProgramStartTime " -ForegroundColor Magenta -BackgroundColor Black
Write-Host "  Completed at: $ProgramFinishTime " -ForegroundColor Magenta -BackgroundColor Black

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location -Path $ScriptPath


