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
######################################################################################################################
######################################################################################################################
#
# Author: Gaiye "Gail" Zhou
# June 2021 
# Description: Generate Export Tables T-SQL Scripts to migrate tables data into Azure Storage
#   Azure Storage Type: adls or blob 
# Example Configuration Files
#   (1) export_tables_config.json  - this one has the parameters you defined in preparing for PolyBase Export. 
#   (2) ExportTablesConfit.csv   - this one has the table list 
#
# This powershell script will generate the right T-SQL script for each create external statement (for each table)
# https://docs.microsoft.com/en-us/sql/t-sql/statements/create-external-table-transact-sql?view=sql-server-ver15&tabs=dedicated
######################################################################################################################


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


Function GetPassword([SecureString] $securePassword) {
    $securePassword = Read-Host "Enter Password" -AsSecureString
    $P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    return $P
}

function CleanUp {
    param (
        [string]$FolderName = ""
    )
        
        Remove-Item -path $FolderName -Recurse -Force
        Write-Host "  $FolderName was successfully deleted." -ForegroundColor Magenta
}

function Get-TableColumns {
    param(
        [string] $ServerName = "",
        [string] $DatabaseName= "",
        [string] $SchemaName = '',
        [string] $TableName = '',
        [string] $IntegratedSecurity = "",
        [string] $UserName = "",
        [string] $Password = $securePassword,
        [string] $MetaDataFileFullPath = "",
        [string] $TempFilesFolder = ""
    )
        
    $sqlVariable = "TABLENAME=$TableName"
    $sqlMetaDataFileFullPath = $MetaDataFileFullPath 
       
    $tempSQLFileName = $DatabaseName + "." + $SchemaName + '.' + $TableName + '_t' + '.sql'
    $tempSQLFullPath = join-path $TempFilesFolder $tempSQLFileName
    $tempFileName = $DatabaseName +"." +  $SchemaName + '.' + $TableName + '.txt'
    $tempFileFullPath = join-path $TempFilesFolder $tempFileName

    if (!(test-path $tempSQLFullPath)) {
        New-Item -ItemType "file" -Force -Path $tempSQLFullPath | Out-Null
    }

    if (!(test-path $tempFileFullPath)) {
        New-Item -ItemType "file" -Force -Path $tempFileFullPath | Out-Null
    }


    if ($IntegratedSecurity -eq "YES")  # Assuming the calling function has processed the value and converted to the right one. 
    {
        (Invoke-Sqlcmd -InputFile $sqlMetaDataFileFullPath `
                -ServerInstance $ServerName -database $DatabaseName -Variable $sqlVariable -OutputAs DataTables -ErrorAction Stop) | 
        ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Set-Content $tempFileFullPath
    }
    else 
    {
        (Invoke-Sqlcmd -InputFile $sqlMetaDataFileFullPath `
        -ServerInstance $ServerName -database $DatabaseName -Username $UserName -Password $Password -Variable $sqlVariable -OutputAs DataTables -ErrorAction Stop) | 
    ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Set-Content $tempFileFullPath
    }       

    $output = Get-Content $tempFileFullPath

    $output | foreach { $_.replace('"|"', '|').TrimStart('"').TrimEnd('"') } | Out-File $tempSQLFullPath 

    return $tempSQLFullPath 

}

Function CreateExportTablesScripts(
    $Location="",
    $DataSourceName="DataSourceName",
    $FileFormatName="FileFormatName",
    $ServerName = "",
    $IntegratedSecurity ="",
    $TableColumns = "YES",
    $UserName = "",
    $Password = "",
    $MetaDataFileFullPath = "",
    $DatabaseName="DatabaseName", 
    $SchemaName="dbo",
    $TableName ="TableName",
    $ExternalSchemaName="ext_dbo",
    $DropExternalTable ='YES',
    $SqlFilePath="C:\migratemaster\tsql\asa_objects\CopyInto",
    $SqlFileName="Test.sql",
    $TempFilesFolder = "")
    {
	    if (!(test-path $SqlFilePath)) {
            New-item "$SqlFilePath" -ItemType Dir | Out-Null
            #New-item "$SqlFilePath" -ItemType File | Out-Null
        }

        $SqlFileFullPath = join-path $SqlFilePath $SqlFileName

	    if ((test-path $SqlFileFullPath)) {
            Write-Host "Replace output file: "$SqlFileFullPath -ForegroundColor Yellow
            Remove-Item $SqlFileFullPath -Force
        }

        #============================================================
        # Generate Export Code and Write it to .sql File 
        #============================================================
        $GenTime =(Get-Date)
    
        "------------------------------------------------" >> $SqlFileFullPath
        "-- Code Generated on $GenTime " >> $SqlFileFullPath
        "------------------------------------------------" >> $SqlFileFullPath

        if ( ($DropExternalTable.ToUpper() -eq "YES") -or ($DropExternalTable.ToUpper() -eq "Y") )
        {
            "IF OBJECT_ID(N" + "'" + "["+$DatabaseName + "].[" + $ExternalSchemaName + "].["+ $TableName + "]" + "'" + ") IS NOT NULL" >> $SqlFileFullPath
            "  DROP EXTERNAL TABLE " + "["+$DatabaseName + "].[" + $ExternalSchemaName + "].["+ $TableName + "];" >> $SqlFileFullPath
            "GO" >> $SqlFileFullPath
            " " >> $SqlFileFullPath
        }

        "CREATE EXTERNAL TABLE " + "["+$DatabaseName + "].[" + $ExternalSchemaName + "].[" + $TableName + "]" >> $SqlFileFullPath

    

        if ( ($TableColumns.toUpper() -eq "YES") -or  ($TableColumns.toUpper() -eq "Y") ) 
        {
            $tempSQLFullPath  = Get-TableColumns  -ServerName $ServerName -DatabaseName $DatabaseName -SchemaName $SchemaName -TableName $TableName `
            -IntegratedSecurity $IntegratedSecurity -UserName $UserName -Password $Password `
            -MetaDataFileFullPath $MetaDataFileFullPath `
            -TempFilesFolder $TempFilesFolder
            "(" >> $SqlFileFullPath
            foreach ($line in Get-Content -Path $tempSQLFullPath )
            {
                if ([String]::IsNullOrWhiteSpace($line) -or [String]::IsNullOrEmpty($line) )
                {
                    # Do nothing, skip the empty line 
                }
                else {
                   "    " + $line >> $SqlFileFullPath
                }
            }
    
            ")" >> $SqlFileFullPath
        }
        "WITH " >> $SqlFileFullPath
        "( " >> $SqlFileFullPath
        "       LOCATION = " + "'" + $Location + "'"  + ",">> $SqlFileFullPath
        "       DATA_SOURCE = " + $DataSourceName +  "," >> $SqlFileFullPath
        "       FILE_FORMAT = " + $FileFormatName >> $SqlFileFullPath
        ");" >> $SqlFileFullPath
        "GO" >> $SqlFileFullPath
        " " >> $SqlFileFullPath
        
        if ($TableColumns.toUpper() -ne "YES")
        {
            "AS " >> $SqlFileFullPath
            "SELECT * FROM " + $DatabaseName + "." + $SchemaName + "." + $TableName >> $SqlFileFullPath
        }
        else {

            "INSERT INTO " + "["+$DatabaseName +"].["+$ExternalSchemaName +"].["+ $TableName +"]">> $SqlFileFullPath
            "  SELECT * FROM " + "["+$DatabaseName + "].["+$SchemaName+"].["+$TableName+"]" >> $SqlFileFullPath
            "GO " >> $SqlFileFullPath
        }

        # "OPTION (LABEL = " + "'" + "Export_" + $DatabaseName + "_" + $SchemaName + "_" + $TableName + "'"+ ")" >> $SqlFileFullPath  # This line caused execution error in SQL Server 2016

        return "1"
    }

  
#==========================================================================================================
# Main Program Starts here 
# Generate COPY Into T-SQL Scripts to migrate date into Synapse 
#==========================================================================================================

$ProgramStartTime = (Get-Date)

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location -Path $ScriptPath

$cfgFilePath = Read-Host -prompt "Enter the Config File Path or press 'Enter' to accept the default [$($ScriptPath)]"
if([string]::IsNullOrEmpty($cfgFilePath)) {
    $cfgFilePath = $ScriptPath
}


# CSV File

$defaultTablesCfgFile = "ExportTablesConfig.csv"
$tablesCfgFile = Read-Host -prompt "Enter the Export Tables Config Name or press 'Enter' to accept the default [$($defaultTablesCfgFile)]"
if([string]::IsNullOrEmpty($tablesCfgFile)) {
    $tablesCfgFile = $defaultTablesCfgFile
}
$tablesCfgFileFullPath = join-path $cfgFilePath $tablesCfgFile
if (!(test-path $tablesCfgFileFullPath )) {
    Write-Host "Could not find Config File: $tablesCfgFileFullPath " -ForegroundColor Red
    break 
}


$defaultCfgFile = "export_tables_config.json"
$cfgFile = Read-Host -prompt "Enter the Config File Name or press 'Enter' to accept the default [$($defaultCfgFile)]"
if([string]::IsNullOrEmpty($cfgFile)) {
    $cfgFile = $defaultCfgFile
}

$CfgFileFullPath = join-path $cfgFilePath $cfgFile
if (!(test-path $CfgFileFullPath )) {
    Write-Host "Could not find Config File: $CfgFileFullPath " -ForegroundColor Red
    break 
}

$csvTablesCfgFile = Import-Csv $tablesCfgFileFullPath

$JsonConfig = Get-Content -Path $CfgFileFullPath | ConvertFrom-Json 
#Write-Host $JsonConfig
$SqlServerName = $JsonConfig.ServerName
$IntegratedSecurity =  $JsonConfig.IntegratedSecurity
$TableColumns = $JsonConfig.TableColumns
$RootFolder = $JsonConfig.RootFolder
$DataSourceName = $JsonConfig.DataSourceName
$FileFormatName = $JsonConfig.FileFormatName




if ( ($IntegratedSecurity.toUpper() -eq "YES") -or  ($IntegratedSecurity.toUpper() -eq "Y") ) 
{
    Write-Host "IntegratedSecurity is set to $IntegratedSecurity" -ForegroundColor Yellow
    $IntegratedSecurity = "YES"
} 
else {
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

$SqlFilePath = $JsonConfig.SqlFilePath
if (Test-Path $SqlFilePath) {
	Remove-Item $SqlFilePath -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Previous folder is removed and new one will be created: $SqlFilePath " -ForegroundColor Red
}
$MetaDataFileName = "GetTableMetaData.sql" 
$MetaDataFileFullPath = Join-Path $ScriptPath $MetaDataFileName 

$TempFilesFolder = $ScriptPath + "\Temp"
if (!(test-path $TempFilesFolder)) {
    Write-Host "  $TempFilesFolder was created to store temporary working files." -ForegroundColor Magenta
    New-Item -ItemType Directory -Force -Path $TempFilesFolder | Out-Null
}

ForEach ($csvItem in $csvTablesCfgFile) {
    $Active = $csvItem.Active
    If ($Active.Trim() -eq "1") {
      $DatabaseName = $csvItem.DatabaseName
      $SchemaName = $csvItem.SchemaName
      $TableName = $csvItem.TableName
      $DropExternalTable = $csvItem.DropExternalTable
      $ExternalSchemaName = $csvItem.ExternalSchemaName
      $SqlFileName =  "Export_" + $DatabaseName + "_" + $SchemaName + "_" + $TableName + ".sql"

      #if ( [string]::IsNullOrEmpty($RootFolder) ) 
      if ( [string]::IsNullOrWhiteSpace($RootFolder) ) 
      {
        $Location = "/" +  $DatabaseName + "/" + $SchemaName + "_" + $TableName 
      }
      else 
      {
        $Location =  "/" + $RootFolder + "/" + $DatabaseName + "/" + $SchemaName + "_" + $TableName 
      }

      $returnValue = '0' 
     
      $returnValue = CreateExportTablesScripts -Location $Location `
      -DataSourceName $DataSourceName -FileFormatName $FileFormatName `
      -ServerName $SqlServerName -IntegratedSecurity $IntegratedSecurity -TableColumns $TableColumns `
      -UserName $UserName -Password $Password -MetaDataFileFullPath $MetaDataFileFullPath `
      -DatabaseName $DatabaseName -SchemaName $SchemaName -TableName $TableName -DropExternalTable $DropExternalTable -ExternalSchemaName $ExternalSchemaName `
      -SqlFilePath $SqlFilePath -SqlFileName $SqlFileName `
      -TempFilesFolder $TempFilesFolder

      if ($returnValue.ToString() -ne '1') {
        Write-Host "Something went wrong. Please check program or input for DB $DatabaseName Schema $SchemaName Table $TableName" -ForegroundColor Red
      }

    }

  }

# Clean up temp files 
CleanUp -FolderName $TempFilesFolder

$ProgramFinishTime = (Get-Date)#

$progDuration = GetDurations  -StartTime  $ProgramStartTime -FinishTime $ProgramFinishTime
$progDurationText = $progDuration.DurationText

Write-Host "  The work is done. Total time generating these SQL Files: $progDurationText " -ForegroundColor Magenta -BackgroundColor Black

Write-Host "  Check your output files in: $SqlFilePath " -ForegroundColor Magenta -BackgroundColor Black

Set-Location -Path $ScriptPath
