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
#======================================================================================================================#
#======================================================================================================================#
#
# Author: Gaiye "Gail" Zhou
# 
# Description: It will run SQL Scripts stored in .sql files in specified folder. 
# The program will promot users for one JSON config file name that is placed in the 
# same location as this script. 
# Two Sample Json Files below: 
# Sample 1: working with local SQL Server
<#
	"ServerName":".\\YourLocalServerName",
	"DatebaseName":"AdventureWorksDW2017",
	"IntegratedSecurity":"Yes",
	"SqlFilesFolder":"C:\\Z_Scripts\\SQLScripts"
}
#>
# Sample 2: working with Azure Synaspe SQL Pool 
<#
{
	"ServerName":"yoursqlsvr.database.windows.net",
	"DatebaseName":"yourdatabaseame",
	"IntegratedSecurity":"No",
	"SqlFilesFolder":"C:\\migratemaster\\output\\1_TranslateMetaData\\AdventureWorksDW2017\\Tables\\Target"
}
#>
#  
#======================================================================================================================#
#======================================================================================================================#
#

Function GetPassword([SecureString] $securePassword) {
    $securePassword = Read-Host "Enter Password" -AsSecureString
    $P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    return $P
}


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

Function ExecuteSqlScriptFile { 
    [CmdletBinding()] 
    param( 
        [Parameter(Position = 1, Mandatory = $false)] [string]$ConnectionString, 
        [Parameter(Position = 2, Mandatory = $false)] [string]$InputFile, 
        [Parameter(Position = 3, Mandatory = $false)] [Int32]$QueryTimeout = 300
    ) 

    $myReturnValues = @{ }
    $myReturnValues.add('Status', ' ')
    $myReturnValues.add('Msg', ' ')
    $myReturnValues.Clear()

    try {
      
        Invoke-Sqlcmd -ConnectionString $ConnectionString -InputFile $InputFile -ErrorAction 'Stop'

        $myReturnValues.add('Status', 'Success')
        $myReturnValues.add('Msg', ' ')

    }
    Catch [System.Data.SqlClient.SqlException] {
        $Err = $_ 
        if ([string]::IsNullOrEmpty($Err))
        {
            $myReturnValues.add('Status', 'Error')
            $myReturnValues.add('Msg', ' ')
        }
        else {
            $myReturnValues.add('Status', 'Error')
            $myReturnValues.add('Msg', $Err)
        } 
    } 
    Catch {
        $Err = $_ 
        if ([string]::IsNullOrEmpty($Err))
        {
            $myReturnValues.add('Status', 'Error')
            $myReturnValues.add('Msg', ' ')
        }
        else {
            $myReturnValues.add('Status', 'Error')
            $myReturnValues.add('Msg', $Err)
        }
    } 
    
    return $myReturnValues
	 
} 


######################################################################################
########### Main Program 
#######################################################################################

$ProgramStartTime = (Get-Date)

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location -Path $ScriptPath


#===========================================
# Config File, SQL Server, and DB here
#===========================================


#$defaultCfgFile = "sql_scripts.json"
$defaultCfgFile = "sql_synapse.json"

$cfgFile = Read-Host -prompt "Enter the Config File Name or press 'Enter' to accept the default [$($defaultCfgFile)]"
if([string]::IsNullOrEmpty($cfgFile)) {
    $cfgFile = $defaultCfgFile
}
$CfgFileFullPath = join-path $ScriptPath  $cfgFile
if (!(test-path $CfgFileFullPath )) {
    Write-Host "Could not find Config File: $CfgFileFullPath " -ForegroundColor Red
    break 
}

$JsonConfig = Get-Content -Path $CfgFileFullPath | ConvertFrom-Json 

$server = $JsonConfig.ServerName
$database  = $JsonConfig.DatebaseName
$Integrated = $JsonConfig.IntegratedSecurity
$SqlScriptFilePath  = $JsonConfig.SqlFilesFolder

# Check to see if there are any .sql files in the specified folder 
$fileCount = [System.IO.Directory]::GetFiles($SqlScriptFilePath, "*.sql")
if ([String]::IsNullOrEmpty($fileCount) -or [String]::IsNullOrWhiteSpace($fileCount)) {

    Write-Host "Did not find .sql files in this folder: $SqlScriptFilePath " -ForegroundColor Magenta
    break 
}

$ProcessedFilesPath = $SqlScriptFilePath + "\Processed"
if (!(test-path $ProcessedFilesPath)) {
    Write-Host "  $ProcessedFilesPath was created to store processed SQL Files." -ForegroundColor Magenta
    New-item "$ProcessedFilesPath" -ItemType Dir | Out-Null
}


$MyLogFileWoExt = [System.IO.Path]::GetFileNameWithoutExtension($cfgFile )
$LogDir = $ScriptPath + "\Log"

if (!(test-path $LogDir)) {
    Write-Host "  $LogDir was created to store log files." -ForegroundColor Magenta
    New-item "$LogDir" -ItemType Dir | Out-Null
}

$DateTimeNow = Get-Date -UFormat "%Y_%m_%d_%H_%M_%S"
$LogFileFullPath = $LogDir + "\" + $MyLogFileWoExt + "_log_" + $DateTimeNow + ".csv"
if ((test-path $LogFileFullPath)) {
    Write-Host "Replace previous log file: "$LogFileFullPath -ForegroundColor Magenta
    Remove-Item $LogFileFullPath -Force
}

#===========================================
# SQL Server Connection 
#===========================================

if ($Integrated.toUpper() -eq "NO") {
    Write-Host "Please Enter SQLAUTH Login Information..." -ForegroundColor Yellow
    $UserName = Read-Host -prompt "Enter the User Name "
    if ([string]::IsNullOrEmpty($UserName)) {
        Write-Host "A user name must be entered" -ForegroundColor Red
        break
    }
    $Password = GetPassword
    if ([string]::IsNullOrEmpty($Password)) {
        Write-Host "A password must be entered." -ForegroundColor Red
        break
    }

}

$connectionTimeOut = 60 # in seconds 
$MyConnectionString = "Data Source=$server;Integrated Security=SSPI;Initial Catalog=$database;Connect Timeout=$connectionTimeOut"

if ($Integrated.toUpper() -eq 'NO') {
    $MyConnectionString = "Data Source=$server;Integrated Security=false;Initial Catalog=$database;User ID=$UserName;Password=$Password;Connect Timeout=$connectionTimeOut"
}

#$MySqlConnection = New-Object System.Data.SqlClient.SqlConnection($MyConnectionString)
#$MySqlConnection.open()


#===========================================
# Processing SQL Files 
#===========================================

$headerRow = New-Object PSObject

$headerRow | Add-Member -MemberType NoteProperty -Name "SqlScriptFile" -Value "SqlScriptFile" -force
$headerRow | Add-Member -MemberType NoteProperty -Name "DurationText" -Value "DurationText" -force
$headerRow | Add-Member -MemberType NoteProperty -Name "DurationHours" -Value "DurationHours" -force
$headerRow | Add-Member -MemberType NoteProperty -Name "DurationMinutes" -Value "DurationMinutes" -force
$headerRow | Add-Member -MemberType NoteProperty -Name "DurationSeconds" -Value "DurationSeconds"  -force
$headerRow | Add-Member -MemberType NoteProperty -Name "DurationMilliseconds" -Value "DurationMilliseconds" -force
$headerRow | Add-Member -MemberType NoteProperty -Name "Status" -Value "Status" -force
$headerRow | Add-Member -MemberType NoteProperty -Name "Message" -Value  "Message" -force

Export-Csv -InputObject $headerRow -Path $LogFileFullPath -NoTypeInformation -Append -Force 


$myQueryTimeOut = 300
foreach ($f in Get-ChildItem -path $SqlScriptFilePath  -Filter *.sql) {
    #Write-Host "File Name: " $f.FullName.ToString()	
    $ReturnValues = @{}
    $ReturnValues.Clear()

    $SqlScriptFileName = $f.FullName.ToString()	

    # Run the Script in $SqlScriptFilename 
    $StartTime = (Get-Date)

    $ReturnValues = ExecuteSqlScriptFile -ConnectionString $MyConnectionString -InputFile $SqlScriptFileName -QueryTimeout $myQueryTimeOut 

    $FinishTime = (Get-Date)
    

    $Status = $ReturnValues.Status.ToString()
    $Message = $ReturnValues.Msg.ToString()
   
    if ($Status -eq 'Success') {
        $DisplayMessage = "  Process Completed for File: " + $SqlScriptFileName + "  Duration: $runDurationText "
        Write-Host $DisplayMessage -ForegroundColor Green -BackgroundColor Black
        # Move the file into Processed Folder 
        Move-Item  $SqlScriptFileName  -Destination $ProcessedFilesPath -Force
    }
    elseif ($Status -eq 'Error') {
        $Message = "Error: " + $Message
        $Message = $Message.Replace("`r`n", "")
        $Message = '"' + $Message.Replace("`n", "") + '"'
        $DisplayMessage = "  Error Processing File: " + $SqlScriptFileName + ". Error: " + $Message 
        Write-Host $DisplayMessage -ForegroundColor Red -BackgroundColor Black
    }
    else {
        if ([string]::IsNullOrEmpty($Message))
        {
            $Message = ' '
            $Status = ' '
        }
        else 
        {  
            $Message = "Unknown Output: " + $Message
            $Message = $Message.Replace("`r`n", "")
            $Message = '"' + $Message.Replace("`n", "") + '"'
            $DisplayMessage = "  Error Processing File: " + $SqlScriptFileName + ". Error: " + $Message 
            Write-Host $DisplayMessage -ForegroundColor Red -BackgroundColor Black
            $Status = 'Unknown'
        }
    }


    $runDurationInfo = GetDurations -StartTime $StartTime -FinishTime $FinishTime
    $runHours = $runDurationInfo.Hours
    $runMinutes = $runDurationInfo.Minutes
    $runSeconds = $runDurationInfo.Seconds
    $runMilliSeconds = $runDurationInfo.Milliseconds 
    $runDurationText = $runDurationInfo.DurationText

    <#
    $dataRow = $SqlScriptFileName, $runDurationText, $runHours, $runMinutes, $runSeconds, $runMilliSeconds, $Status, $Message
    $dataRow -join ","  >> $LogFileFullPath
    #>
    $row = New-Object PSObject

    $row | Add-Member -MemberType NoteProperty -Name "SqlScriptFile" -Value $SqlScriptFileName -force
    $row | Add-Member -MemberType NoteProperty -Name "DurationText" -Value $runDurationText -force
    $row | Add-Member -MemberType NoteProperty -Name "DurationHours" -Value $runHours -force
    $row | Add-Member -MemberType NoteProperty -Name "DurationMinutes" -Value $runMinutes -force
    $row | Add-Member -MemberType NoteProperty -Name "DurationSeconds" -Value $runSeconds -force
    $row | Add-Member -MemberType NoteProperty -Name "DurationMilliseconds" -Value $runMilliSeconds -force
    $row | Add-Member -MemberType NoteProperty -Name "Status" -Value $Status -force
    $row | Add-Member -MemberType NoteProperty -Name "Message" -Value  $Message -force

    Export-Csv -InputObject $row -Path $LogFileFullPath -NoTypeInformation -Append -Force 

}

#$MySqlConnection.close()



$ProgramFinishTime = (Get-Date)


$progDuration = GetDurations  -StartTime  $ProgramStartTime -FinishTime $ProgramFinishTime
$progDurationText = $progDuration.DurationText

Write-Host "  The work is done.Total time generating these SQL Files: $progDurationText " -ForegroundColor Magenta -BackgroundColor Black

Write-Host "  Processed Files are moved into: $ProcessedFilesPath" -ForegroundColor Magenta -BackgroundColor Black

Write-Host "  Processed results are written into this log file: $LogFileFullPath" -ForegroundColor Magenta -BackgroundColor Black

Set-Location -Path $ScriptPath

