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
# May 2021 
# Description: Generate COPY Into T-SQL Scripts to migrate date into Synapse 
#   Azure Storage Type: BLOB or DFS (Works with ADLS Blob Storage as well) 
#   File Format: CSV or Parquet (Preferred) 
#   Authorization: Account Key or Managed Identity (Preferred) 
#   Storage Type, File Format, and Authorization are all configurable 
# Example Configuration Files
#   (1) key_csv.json      for BLOB or ADLS and CSV File, Account Key Authorization 
#   (2) mi_csv.json       for Blob or ADLS and CSV File, Managed Identity Authorization 
#   (3) mi_parquet.json   for Blob or ADLS and Parquet File, Managed Identity Authorization 
#   (4) mi_orc.json       for Blob or ADLS and ORC File, Managed Identity Authorization 
#
# Job Aid: To set up managed identity in Azure, please refer to this doc
# https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/quickstart-bulk-load-copy-tsql-examples
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

Function CreateCopyIntoScripts(
    $StorageType="BLOB",
    $Credential="(IDENTITY= 'Managed Identity')",
    $AccountName="BlobAccountName",
    $Container="ContainerName",
    $FileType="CSV",
    $Compression="NONE",
    $FieldQuote = '"',
    $FieldTerminator="0x1F",
    $RowTerminator="0x1E",
    $Encoding="UTF8",
    $MaxErrors = "",
    $ErrorsFolder ="",
    $DateFormat = "",
    $FirstRow="2",
    $TruncateTable="No", 
    $StorageFolder ="",
    $SchemaName="dbo",
    $TableName ="TableName",
    $IdentityInsert ='OFF',
    $AsaDatabaseName = '',
    $AsaSchema = "AsaSchema",
    $SqlFilePath="C:\migratemaster\tsql\asa_objects\CopyInto",
    $SqlFileName="Test.sql")
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
        # Storage Types: BLOB or ADLS 
        #============================================================
    
        $Storage = $StorageType.toUpper()

        # Defulat Location sample 
        #$Location = "'https://accountname.dfs.core.windows.net/import/DimAccount/'" 

        $Location = "https://" + $AccountName + ".dfs.core.windows.net/" + $Container + "/" + $StorageFolder + "/" 

        if ($Storage.toUpper() -eq 'BLOB')
        {
            $storageString = ".blob.core.windows.net"
        }
        elseif ($Storage.toUpper() -eq 'ADLS') 
        {
            $storageString = ".dfs.core.windows.net" 
        }
        else {
            Write-Host "Unknown Storate Type" $Storage -ForegroundColor Red
            Write-Host "Accepted Values: BLOB or ADLS (case insensitive)" -ForegroundColor Red
         return -1 
        }  

        if (($FileType.toUpper() -eq 'CSV')  -or ($FileType.toUpper() -eq 'ORC') )  {
            $Location = "https://" + $AccountName + $storageString + "/" + $Container + "/" + $StorageFolder + "/"
        } elseif ($FileType.toUpper() -eq 'PARQUET') {
            $Location = "https://" + $AccountName + $storageString + "/" + $Container + "/" + $StorageFolder + "/" + "*.parquet"
        }
        else {
            Write-Host "Unexpected File Type Found: $FileType" -ForegroundColor Red
            return -1 
        }

        #============================================================
        # File Types: CSV or  PARQUET Or ORC 
        #============================================================
        $GenTime =(Get-Date)
    
        "------------------------------------------------" >> $SqlFileFullPath
        "-- Code Generated on $GenTime " >> $SqlFileFullPath
        "------------------------------------------------" >> $SqlFileFullPath

        if ( ($TruncateTable.ToUpper() -eq "YES") -or ($TruncateTable.ToUpper() -eq "Y") )
        {
            "TRUNCATE TABLE " + $AsaDatabaseName + "." + $AsaSchema + "."+ $TableName >> $SqlFileFullPath
            " " >> $SqlFileFullPath
        }

        if ($FileType.toUpper() -eq 'CSV')  {

            "COPY INTO " + $AsaDatabaseName + "." + $AsaSchema + "."+ $TableName >> $SqlFileFullPath
            "FROM " + "'" + $Location + "'" >> $SqlFileFullPath
            "WITH (" >> $SqlFileFullPath
            "  FILE_TYPE = " + "'" + $FileType + "'" +"," >> $SqlFileFullPath
            if ( !([string]::IsNullOrWhiteSpace($Compression)) )
            {
                "  COMPRESSION  = " + "'" + $Compression + "'" +"," >> $SqlFileFullPath
            }
            "  CREDENTIAL = " + $Credential +"," >> $SqlFileFullPath
            "  FIELDQUOTE = " + "'" + $FieldQuote + "'" +"," >> $SqlFileFullPath
            "  FIELDTERMINATOR = " + "'" + $FieldTerminator + "'" +"," >> $SqlFileFullPath
            "  ROWTERMINATOR = " + "'" + $RowTerminator + "'" +"," >> $SqlFileFullPath
            "  ENCODING = " + "'" + $Encoding + "'" +"," >> $SqlFileFullPath
            if ( !([string]::IsNullOrWhiteSpace($MaxErrors)) )
            {
                "  MAXERRORS  = " + "'" + $MaxErrors + "'" +"," >> $SqlFileFullPath
            } 
            else {
                "  MAXERRORS  = " + "'" + "0" + "'" +"," >> $SqlFileFullPath
            }
            if ( !([string]::IsNullOrWhiteSpace($ErrorsFolder)) )
            {
                "  ERRORFILE  = " + "'" + $ErrorsFolder + "'" +"," >> $SqlFileFullPath
            } 
            "  IDENTITY_INSERT =  " + "'" + $IdentityInsert + "'" +"," >> $SqlFileFullPath
            if ( !([string]::IsNullOrWhiteSpace($DateFormat)) )
            {
                "  DATEFORMAT  =  " + "'" + $DateFormat + "'" +"," >> $SqlFileFullPath
            }
            "  FIRSTROW = " + $FirstRow >> $SqlFileFullPath
            ") " >> $SqlFileFullPath
        } elseif (($FileType.toUpper() -eq 'PARQUET') -or ($FileType.toUpper() -eq 'ORC'))  {


            "COPY INTO " + $AsaDatabaseName + $AsaSchema + "."+ $TableName >> $SqlFileFullPath
            "FROM " + "'" + $Location + "'" >> $SqlFileFullPath
            "WITH (" >> $SqlFileFullPath
            "  FILE_TYPE = " + "'" + $FileType + "'" +"," >> $SqlFileFullPath
            "  FILE_FORMAT  = " + $FileFormat >> $SqlFileFullPath
            if ( !([string]::IsNullOrWhiteSpace($Compression)) )
            {
                "  COMPRESSION  = " + "'" + $Compression + "'" +"," >> $SqlFileFullPath
            }
            "  CREDENTIAL = " + $Credential >> $SqlFileFullPath
            if ( !([string]::IsNullOrWhiteSpace($MaxErrors)) )
            {
                "  MAXERRORS  = " + "'" + $MaxErrors + "'" +"," >> $SqlFileFullPath
            }
            "  IDENTITY_INSERT =  " + "'" + $IdentityInsert + "'" +"," >> $SqlFileFullPath
            ") " >> $SqlFileFullPath
        } else {
            Write-Host "Unknown File Type" $FileType -ForegroundColor Red
            Write-Host "Accepted Value: CSV or PARQUET or ORC " -ForegroundColor Red
            return -1 
        } 

        return '1'
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

$defaultTablesCfgFile = "TablesConfig.csv"
$tablesCfgFile = Read-Host -prompt "Enter the COPY INTO Tables Config Name or press 'Enter' to accept the default [$($defaultTablesCfgFile)]"
if([string]::IsNullOrEmpty($tablesCfgFile)) {
    $tablesCfgFile = $defaultTablesCfgFile
}
$tablesCfgFileFullPath = join-path $cfgFilePath $tablesCfgFile
if (!(test-path $tablesCfgFileFullPath )) {
    Write-Host "Could not find Config File: $tablesCfgFileFullPath " -ForegroundColor Red
    break 
}


$defaultCfgFile = "csv_mi.json"

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

$StorageType = $JsonConfig.StorateType
$Credential = $JsonConfig.Credential
$AccountName = $JsonConfig.AccountName
$Container = $JsonConfig.Container
$RootFolder = $JsonConfig.RootFolder
$FileType = $JsonConfig.FileType
$Compression = $JsonConfig.Compression 
$MaxErrors =  $JsonConfig.MaxErrors # This one must be an positive integer 
$ErrorsFolder =  $JsonConfig.ErrorsFolder # added 2021-05-26

if ([string]::IsNullOrWhiteSpace($FileType))
{
    Write-Host "File Type not defined. Check your Json Config File. " -ForegroundColor Red
    break 
}
elseif ($FileType.ToUpper() -eq "CSV") {
    $FieldQuote = $JsonConfig.FieldQuote
    $FieldTerminator = $JsonConfig.FieldTerminator
    $RowTerminator = $JsonConfig.RowTerminator
    $Encoding = $JsonConfig.Encoding
    $DateFormat =  $JsonConfig.DateFormat # added 2021-05-11
    $FirstRow = $JsonConfig.FirstRow
}
elseif ( ($FileType.ToUpper() -eq "PARQUET")  -or ($FileType.ToUpper() -eq "ORC")  )   {
    $FileFormat = $JsonConfig.FileFormat
}
else {

    Write-Host "$FileType File Type is not supported. Check your Json Config File. " -ForegroundColor Red
    break 
}

$SqlFilePath = $JsonConfig.SqlFilePath
if (Test-Path $SqlFilePath) {
	Remove-Item $SqlFilePath -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Previous folder is removed and new one will be created: $SqlFilePath " -ForegroundColor Red
}

ForEach ($csvItem in $csvTablesCfgFile) {
    $Active = $csvItem.Active
    If ($Active.Trim() -eq "1") {
      $DatabaseName = $csvItem.DatabaseName
      $SchemaName = $csvItem.SchemaName
      $TableName = $csvItem.TableName
      $IdentityInsert = $csvItem.IdentityInsert.Trim().ToUpper()
      $TruncateTable = $csvItem.TruncateTable
      $AsaDatabaseName = $csvItem.AsaDatabaseName
      $AsaSchema = $csvItem.AsaSchema
      $SqlFileName =  "CopyInto_" + $AsaDatabaseName + "_" + $AsaSchema  + "_" + $TableName + ".sql"
      if ($IdentityInsert -ne 'ON') {
        $IdentityInsert = "OFF"
      }

      #if ( [string]::IsNullOrEmpty($RootFolder) ) 
      if ( [string]::IsNullOrWhiteSpace($RootFolder) ) 
      {
        $StorageFolder = $DatabaseName + "/" + $SchemaName + "_" + $TableName 
      }
      else 
      {
        $StorageFolder =   $RootFolder + "/" + $DatabaseName + "/" + $SchemaName + "_" + $TableName 
      }

      $returnValue = '0' 
     
      $returnValue = CreateCopyIntoScripts -StorageType $StorageType -Credential $Credential -AccountName $AccountName -Container $Container `
        -FileType $FileType -Compression $Compression `
        -FieldQuote $FieldQuote -FieldTerminator $FieldTerminator -RowTerminator $RowTerminator  -Encoding $Encoding -FirstRow $FirstRow `
        -MaxErrors $MaxErrors -ErrorsFolder $ErrorsFolder `
        -DateFormat $DateFormat `
        -FileFormat $FileFormat `
        -TruncateTable $TruncateTable -StorageFolder $StorageFolder -SchemaName $SchemaName -TableName $TableName -IdentityInsert $IdentityInsert `
        -AsaDatabaseName $AsaDatabaseName -AsaSchema $AsaSchema -SqlFilePath $SqlFilePath -SqlFileName $SqlFileName
      
      if ($returnValue.ToString() -ne '1') {
        Write-Host "Something went wrong. Please check program or input for DB $DatabaseName Schema $SchemaName Table $TableName" -ForegroundColor Red
      }

    }

  }

$ProgramFinishTime = (Get-Date)


$progDuration = GetDurations  -StartTime  $ProgramStartTime -FinishTime $ProgramFinishTime
$progDurationText = $progDuration.DurationText

Write-Host "  The work is done.Total time generating these SQL Files: $progDurationText " -ForegroundColor Magenta -BackgroundColor Black

Write-Host "  Check your output files in: $SqlFilePath " -ForegroundColor Magenta -BackgroundColor Black

Set-Location -Path $ScriptPath
