#======================================================================================================================#
#                                                                                                                      #                                                                                                                      #
#  This utility was developed on a best effort basis                                                                   #
#  to aid effort to migrate into Azure Synapse and then Optimize the Design for best performance.                      #                                                       #
#  It is not an officially supported Microsoft application or tool.                                                    #
#                                                                                                                      #
#  The utility and any script outputs are provided on "AS IS" basis and                                                #
#  there are no warranties, express or implied, including, but not limited to implied warranties of merchantability    #
#  or fitness for a particular purpose.                                                                                #
#                                                                                                                      #                    
#  The utility is therefore not guaranteed to generate perfect code or output. The output needs carefully reviewed.    #
#                                                                                                                      #
#                                       USE AT YOUR OWN RISK.                                                          #
#  Author: Gaiye "Gail" Zhou                                                                                           #
#  Agust 2021                                                                                                      #
#                                                                                                                      #
#                                                                                                                      #
#======================================================================================================================#
#
#
#
#==========================================================================================================
# Functions Start here 
#==========================================================================================================
#
# Capture Time Difference and Format time parts into easy to read or display formats. 
Function GetDuration() {
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

    $DurationText = '' # initialize it! 

    if (($Hrs -eq 0) -and ($Mins -eq 0) -and ($Secs -eq 0)) {
        $DurationText = "$MSecs milliseconds." 
    }
    elseif (($Hrs -eq 0) -and ($Mins -eq 0)) {
        $DurationText = "$Secs seconds $MSecs milliseconds." 
    }
    elseif ( ($Hrs -eq 0) -and ($Mins -ne 0)) {
        $DurationText = "$Mins minutes $Secs seconds $MSecs milliseconds." 
    }
    else {
        $DurationText = "$Hrs hours $Mins minutes $Secs seconds $MSecs milliseconds."
    }

    $ReturnValues.add("Hours", $Hrs)
    $ReturnValues.add("Minutes", $Mins)
    $ReturnValues.add("Seconds", $Secs)
    $ReturnValues.add("Milliseconds", $MSecs)
    $ReturnValues.add("DurationText", $DurationText)

    return $ReturnValues 

}



######################################################################################
########### Main Program 
#######################################################################################

$ProgramStartTime = (Get-Date)

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location -Path $ScriptPath

$cfgFilePath = Read-Host -prompt "Enter the Config File Path or press 'Enter' to accept the default [$($ScriptPath)]"
if ([string]::IsNullOrEmpty($cfgFilePath)) {
    $cfgFilePath = $ScriptPath
}

$defaultCfgFile = "code_generation_config.json"

$cfgFile = Read-Host -prompt "Enter the .json Config File Name or press 'Enter' to accept the default [$($defaultCfgFile)]"
if ([string]::IsNullOrEmpty($cfgFile)) {
    $cfgFile = $defaultCfgFile
}
$CfgFileFullPath = join-path $cfgFilePath $cfgFile
if (!(test-path $CfgFileFullPath )) {
    Write-Host "Could not find Config File: $CfgFileFullPath " -ForegroundColor Red
    break 
}

# CSV Config File
$defaultTablesCfgFile = "table_list.csv"
$tablesCfgFile = Read-Host -prompt "Enter the List of Tables Config Name or press 'Enter' to accept the default [$($defaultTablesCfgFile)]"
if ([string]::IsNullOrEmpty($tablesCfgFile)) {
    $tablesCfgFile = $defaultTablesCfgFile
}
$tablesCfgFileFullPath = join-path $cfgFilePath $tablesCfgFile
if (!(test-path $tablesCfgFileFullPath )) {
    Write-Host "Could not find Config File: $tablesCfgFileFullPath " -ForegroundColor Red
    break 
}

# use the $tablesCfgFile as prefix for output file names. 
$Config_File_WO_Extension = [System.IO.Path]::GetFileNameWithoutExtension($tablesCfgFile)

# Get all the values from the .json config file 
$JsonConfig = Get-Content -Path $CfgFileFullPath | ConvertFrom-Json 

$CreateHeapTableFlag = $JsonConfig.CreateHeapTableFlag
$CreateDesiredTableFlag = $JsonConfig.CreateDesiredTableFlag
$BackupAndRenameTableFlag = $JsonConfig.BackupAndRenameTableFlag
$DropAndRenameTableFlag = $JsonConfig.DropAndRenameTableFlag
$CreateSisterTableFlag = $JsonConfig.CreateSisterTableFlag

$GenerateInsertIntoFromHeapFlag = $JsonConfig.GenerateInsertIntoFromHeapFlag
$GenerateInsertIntoFromStagingFlag = $JsonConfig.GenerateInsertIntoFromStagingFlag

$GenerateInsertIntoSisterFlag = $JsonConfig.GenerateInsertIntoSisterFlag
$DropTableUtilityFlag = $JsonConfig.DropTableUtilityFlag

$CreateTableStatsFlag = $JsonConfig.CreateTableStatsFlag
$DropTableStatsFlag = $JsonConfig.DropTableStatsFlag

$UpdateTableStatsFullScanFlag = $JsonConfig.UpdateTableStatsFullScanFlag
$UpdateTableStatsCustomScanFlag = $JsonConfig.UpdateTableStatsCustomScanFlag

$RebuildTableIndexFlag = $JsonConfig.RebuildTableIndexFlag
$ReorganizeTableIndexFlag = $JsonConfig.ReorganizeTableIndexFlag
$DropTablesFlag = $JsonConfig.DropTablesFlag

$OutputFilePath = $ScriptPath + "\Output"


if ((test-path $OutputFilePath)) {
    Remove-Item -Recurse $OutputFilePath -Force | Out-Null 
    Write-Host "Previous Output Folder Removed "$OutputFilePath -ForegroundColor Yellow 
}

if (!(test-path $OutputFilePath)) {
    New-item "$OutputFilePath" -ItemType Dir | Out-Null
    Write-Host "Output files will be stored in "$OutputFilePath -ForegroundColor Magenta
}


#exit 

# 1. Create Heap Tables 
if ($CreateHeapTableFlag -eq '1') {
    $HeapTableFile = $Config_File_WO_Extension + "_1_Create_Heap_Tables.sql"
    $heapTableFileFullPath = join-path $OutputFilePath $HeapTableFile 
    if (test-path $heapTableFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $heapTableFileFullPath  -ForegroundColor Yellow
        Remove-Item $heapTableFileFullPath -Force
    }
    '/* 1. Create Heap Tables */' >> $heapTableFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $heapTableFileFullPath 
    ' ' >> $heapTableFileFullPath 
}

# 2. Create Desired Tables 
if ($CreateDesiredTableFlag -eq '1') {
    $CreateDesiredTableFile = $Config_File_WO_Extension + "_2_Create_Desired_Tables.sql"
    $CreateDesiredTableFileFullPath = join-path $OutputFilePath $CreateDesiredTableFile
    if (test-path $CreateDesiredTableFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $CreateDesiredTableFileFullPath -ForegroundColor Yellow
        Remove-Item $CreateDesiredTableFileFullPath -Force
    }
    '/* 2. Create Tables with Desired Distribution */' >> $CreateDesiredTableFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $CreateDesiredTableFileFullPath 
    ' ' >> $CreateDesiredTableFileFullPath  
    
}

# 3A. Backup and Rename Tables 
if ($BackupAndRenameTableFlag -eq '1') {
    $BackupAndRenameTableFile = $Config_File_WO_Extension + "_3A_Backup_And_Rename_Tables.sql"
    $BackupAndRenameTableFileFullPath = join-path $OutputFilePath $BackupAndRenameTableFile
    if (test-path $BackupAndRenameTableFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $BackupAndRenameTableFileFullPath -ForegroundColor Yellow
        Remove-Item $BackupAndRenameTableFileFullPath -Force
    }
    '/* 3A. Option A. Rename the Orginal Table to New Name by adding Suffix _Backup    */' >> $BackupAndRenameTableFileFullPath
    '/*     and then Rename Desired Table Name to Orginal Table Name */' >> $BackupAndRenameTableFileFullPath
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $BackupAndRenameTableFileFullPath
    ' ' >> $BackupAndRenameTableFileFullPath
}

# 3B. Drop and Rename Tables 
if ($DropAndRenameTableFlag -eq '1') {
    $DropAndRenameTableFile = $Config_File_WO_Extension + "_3B_Drop_And_Rename_Tables.sql"
    $DropAndRenameTableFileFullPath = join-path $OutputFilePath $DropAndRenameTableFile
    if (test-path $DropAndRenameTableFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $DropAndRenameTableFileFullPath -ForegroundColor Yellow
        Remove-Item $DropAndRenameTableFileFullPath -Force
    }
    '/* 3B. Option B. Drop Orginal Table and Rename Desired Table Name as Orginal Table Name. */' >> $DropAndRenameTableFileFullPath
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $DropAndRenameTableFileFullPath
    ' ' >> $DropAndRenameTableFileFullPath
}

# 4. Create Sister Table with adding _B in table name 
if ($CreateSisterTableFlag -eq '1') {
    $CreateSisterTableFile = $Config_File_WO_Extension + "_4_Create_Sister_Tables.sql"
    $CreateSisterTableFileFullPath = join-path $OutputFilePath $CreateSisterTableFile
    if (test-path $CreateSisterTableFileFullPath  ) {
        Write-Host "Previous File will be overwritten: " $CreateSisterTableFileFullPath  -ForegroundColor Yellow
        Remove-Item $CreateSisterTableFileFullPath  -Force
    }
    '/* 4. Create Sister Table with name appending _B */' >> $CreateSisterTableFileFullPath
    '/*    with the same distribution as _Desired Table */' >> $CreateSisterTableFileFullPath
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $CreateSisterTableFileFullPath
    ' ' >> $CreateSisterTableFileFullPath
}

# 5. Generate Insert Into Statements From Heap 
if ($GenerateInsertIntoFromHeapFlag -eq '1') {
    $InsertIntoStmtFromHeapFile = $Config_File_WO_Extension + "_5_Insert_Into_Stmts_From_Heap.sql"
    $InsertIntoStmtFromHeapFileFullPath = join-path $OutputFilePath $InsertIntoStmtFromHeapFile
    if (test-path  $InsertIntoStmtFromHeapFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $InsertIntoStmtFromHeapFileFullPath  -ForegroundColor Yellow
        Remove-Item $InsertIntoStmtFromHeapFileFullPath   -Force
    }
    '/* 5. Insert Into Statements From Heap Tables */' >> $InsertIntoStmtFromHeapFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $InsertIntoStmtFromHeapFileFullPath 
    ' ' >> $InsertIntoStmtFromHeapFileFullPath 
}

# 5A. Generate Insert Into Statements From Heap 
if ($GenerateInsertIntoFromStagingFlag -eq '1') {
    $InsertIntoStmtFromStagingFile = $Config_File_WO_Extension + "_5A_Insert_Into_Stmts_From_Staging.sql"
    $InsertIntoStmtFromStagingFullPath = join-path $OutputFilePath $InsertIntoStmtFromStagingFile
    if (test-path  $InsertIntoStmtFromStagingFullPath ) {
        Write-Host "Previous File will be overwritten: " $InsertIntoStmtFromStagingFullPath  -ForegroundColor Yellow
        Remove-Item $InsertIntoStmtFromStagingFullPath   -Force
    }
    '/* 5A. Insert Into Statements From Staging Tables */' >> $InsertIntoStmtFromStagingFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $InsertIntoStmtFromStagingFullPath 
    ' ' >> $InsertIntoStmtFromStagingFullPath 
}


# 6. Generate Insert Into Statements From Sister Table 
if ($GenerateInsertIntoSisterFlag -eq '1') {
    $InsertIntoStmtFromSisterFile = $Config_File_WO_Extension + "_6_Insert_Into_Stmts_From_Sistar_Table.sql"
    $InsertIntoStmtFromSisterFileFullPath = join-path $OutputFilePath $InsertIntoStmtFromSisterFile
    if (test-path  $InsertIntoStmtFromSisterFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $InsertIntoStmtFromSisterFileFullPath  -ForegroundColor Yellow
        Remove-Item $InsertIntoStmtFromSisterFileFullPath   -Force
    }
    '/* 6. Insert Into Statements From Sister Tables */' >> $InsertIntoStmtFromSisterFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $InsertIntoStmtFromSisterFileFullPath
    ' ' >> $InsertIntoStmtFromSisterFileFullPath
}

# 7. Drop Table Utilities (Drop Backup Tables)
if ($DropTableUtilityFlag -ne '0') {
    $DropTableUtilityFile = $Config_File_WO_Extension + "_7_Drop_Backup_Table_Scripts.sql"
    $DropTableUtilityFileFullPath = join-path $OutputFilePath $DropTableUtilityFile
    if (test-path  $DropTableUtilityFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $DropTableUtilityFileFullPath  -ForegroundColor Yellow
        Remove-Item $DropTableUtilityFileFullPath   -Force
    }
    '/* 7. Drop Backup Tables. Dont do this if you dont know what you are doing! */' >> $DropTableUtilityFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $DropTableUtilityFileFullPath 
    ' ' >> $DropTableUtilityFileFullPath 
}

# 8. Create Table Stats 
if ($CreateTableStatsFlag -ne '0') {
    $CreateTableStatsFile = $Config_File_WO_Extension + "_8_Create_Table_Stats.sql"
    $CreateTableStatsFileFullPath = join-path $OutputFilePath $CreateTableStatsFile
    if (test-path  $CreateTableStatsFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $CreateTableStatsFileFullPath  -ForegroundColor Yellow
        Remove-Item $CreateTableStatsFileFullPath   -Force
    }
    '/* 8. Create Table Statistics */' >> $CreateTableStatsFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $CreateTableStatsFileFullPath 
    ' ' >> $CreateTableStatsFileFullPath 
}

# 9. DropTable Stats 
if ($DropTableStatsFlag -ne '0') {
    $DropTableStatsFile = $Config_File_WO_Extension + "_9_Drop_Table_Stats.sql"
    $DropTableStatsFileFullPath = join-path $OutputFilePath $DropTableStatsFile
    if (test-path  $DropTableStatsFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $DropTableStatsFileFullPath  -ForegroundColor Yellow
        Remove-Item $DropTableStatsFileFullPath   -Force
    }
    '/* 9. Drop Table Statistics */' >> $DropTableStatsFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $DropTableStatsFileFullPath 
    ' ' >> $DropTableStatsFileFullPath 
}


# 10A. Update Statistics for Tables with Full Scan 
if ($UpdateTableStatsFullScanFlag -ne '0') {
    $UpdateTableStatsFullScanFile = $Config_File_WO_Extension + "_10A_Update_Table_Stats_FullScans.sql"
    $UpdateTableStatsFullScanFileFullPath = join-path $OutputFilePath $UpdateTableStatsFullScanFile
    if (test-path  $UpdateTableStatsFullScanFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $UpdateTableStatsFullScanFileFullPath  -ForegroundColor Yellow
        Remove-Item $UpdateTableStatsFullScanFileFullPath   -Force
    }
    '/* 10A. Update Table Stats With Full Scan */' >> $UpdateTableStatsFullScanFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $UpdateTableStatsFullScanFileFullPath 
    ' ' >> $UpdateTableStatsFullScanFileFullPath 
}

# 10B. Update Statistics for Tables with Custom Scan 
if ($UpdateTableStatsCustomScanFlag -ne '0') {
    $UpdateTableStatsCustomScanFile = $Config_File_WO_Extension + "_10B_Update_Table_Stats_CustomScans.sql"
    $UpdateTableStatsCustomScanFileFullPath = join-path $OutputFilePath $UpdateTableStatsCustomScanFile
    if (test-path  $UpdateTableStatsCustomScanFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $UpdateTableStatsCustomScanFileFullPath  -ForegroundColor Yellow
        Remove-Item $UpdateTableStatsCustomScanFileFullPath   -Force
    }
    '/* 10B. Update Table Stats With Custom Scan Rage  */' >> $UpdateTableStatsCustomScanFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $UpdateTableStatsCustomScanFileFullPath 
    ' ' >> $UpdateTableStatsCustomScanFileFullPath 
}

# 11. Rebuld Table Index 
if ($RebuildTableIndexFlag -ne '0') {
    $RedbuildTableIndexFile = $Config_File_WO_Extension + "_11_Rebuild_Table_Index.sql"
    $RedbuildTableIndexFileFullPath = join-path $OutputFilePath $RedbuildTableIndexFile
    if (test-path  $RedbuildTableIndexFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $RedbuildTableIndexFileFullPath  -ForegroundColor Yellow
        Remove-Item $RedbuildTableIndexFileFullPath   -Force
    }
    '/* 11. Rebuild Table Index */' >> $RedbuildTableIndexFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $RedbuildTableIndexFileFullPath 
    ' ' >> $RedbuildTableIndexFileFullPath 
}

# 12. Reorganize Table Index 
if ($ReorganizeTableIndexFlag -ne '0') {
    $ReorganizeTableIndexFile = $Config_File_WO_Extension + "_12_Reorganize_Table_Index.sql"
    $ReorganizeTableIndexFileFullPath = join-path $OutputFilePath $ReorganizeTableIndexFile
    if (test-path  $ReorganizeTableIndexFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $ReorganizeTableIndexFileFullPath  -ForegroundColor Yellow
        Remove-Item $ReorganizeTableIndexFileFullPath   -Force
    }
    '/* 12. Reorganize Table Index */' >> $ReorganizeTableIndexFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $ReorganizeTableIndexFileFullPath 
    ' ' >> $ReorganizeTableIndexFileFullPath 
}

# 13. Drop Tables - This should be rarely used  
if ($DropTablesFlag -ne '0') {
    $DropTablesFile = $Config_File_WO_Extension + "_13_DropTables.sql"
    $DropTablesFileFullPath = join-path $OutputFilePath $DropTablesFile
    if (test-path  $DropTablesFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $DropTablesFileFullPath  -ForegroundColor Yellow
        Remove-Item $DropTablesFileFullPath   -Force
    }
    '/* 13. Drop Tables */' >> $DropTablesFileFullPath 
    '/*  !!! This should be rarely used! Use this only if you really want to wipe out (drop) all the tables in one script!!! */' >> $DropTablesFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $DropTablesFileFullPath 
    ' ' >> $DropTablesFileFullPath 
}

#==============================================================================
# Now processing each line of the .csv file. Looping through! 
#==============================================================================
Write-Host "  I am working on the tasks! Will report to you once done. " -ForegroundColor Cyan

$csvTablesCfgFile = Import-Csv $tablesCfgFileFullPath
ForEach ($csvItem in $csvTablesCfgFile) {
    $Active = $csvItem.Active
    If ($Active -eq "1") {
        $DatabaseName = $csvItem.DatabaseName
        $SchemaName = $csvItem.SchemaName
        $StagingSchemaName = $csvItem.StagingSchemaName
        $TableName = $csvItem.TableName
        $CurrentDistributionType = $csvItem.CurrentDistributionType
        $CurrentDisColumn = $csvItem.DistColumn
        #$ObjectName = $csvItem.ObjectName
        $DesiredDistributionType = $csvItem.DesiredDistributionType
        $HashKeys = $csvItem.DistributionKeysIfHash
        $StatsColumns = $csvItem.StatsColumns
        $StatsScanRate = $csvItem.StatsScanRate

       
        if ([String]::IsNullOrWhiteSpace($DesiredDistributionType) -or [String]::IsNullOrEmpty($DesiredDistributionType) )
        {
            $DesiredDistributionType = '-1'
        }

        $ThisTableStatsFlag = 'YES'
        if ([String]::IsNullOrWhiteSpace($StatsColumns) -or [String]::IsNullOrEmpty($StatsColumns) )
        {
            if ([String]::IsNullOrWhiteSpace($CurrentDisColumn) -or [String]::IsNullOrEmpty($CurrentDisColumn) )
            {
                $ThisTableStatsFlag = 'NO'
            }
            else {

                $StatsColumns = $CurrentDisColumn
            }    

        }


        if ([String]::IsNullOrWhiteSpace($StatsScanRate) -or [String]::IsNullOrEmpty($StatsScanRate) )
        {
            $StatsScanRate = '100'
        }



        # 1. Create Heap Tables 
        if ($CreateHeapTableFlag -eq '1') {
            "CREATE TABLE " + $DatabaseName + "." + $SchemaName + "." + $TableName + "_Heap" >> $heapTableFileFullPath 
            " WITH ( DISTRIBUTION = ROUND_ROBIN, HEAP )" >> $heapTableFileFullPath 
            " AS SELECT * FROM " + $DatabaseName + "." + $SchemaName + "." + $TableName >> $heapTableFileFullPath 
            "GO; " >> $heapTableFileFullPath 
            " " >> $heapTableFileFullPath 

        }
      
        # 2. Create Desired Tables 
        if (($CreateDesiredTableFlag -eq '1') -and ( $DesiredDistributionType -ne '-1' )) {
            "CREATE TABLE " + $DatabaseName + "." + $SchemaName + "." + $TableName + "_Desired " >> $CreateDesiredTableFileFullPath 
            if ($DesiredDistributionType.toUpper() -eq "REPLICATE") {
                " WITH ( DISTRIBUTION = REPLICATE ) " >> $CreateDesiredTableFileFullPath 
            }
            elseif ($DesiredDistributionType.toUpper() -eq "ROUND_ROBIN") {
                " WITH ( DISTRIBUTION = ROUND_ROBIN ) " >> $CreateDesiredTableFileFullPath 
            }
            elseif ($DesiredDistributionType.toUpper() -eq "HASH") {
                if ( [string]::IsNullOrEmpty($HashKeys) ) {
              
                    Write-Host "Creating Desired Table. Missing DistributionKeysIfHash Field! Check this table configuratrion: " $SchemaName"."$TableName -ForegroundColor red
                    " WITH ( DISTRIBUTION = HASH( Missing Hash Keys!!!! ) " + " -- Please Check This Table Configurations! " >> $CreateDesiredTableFileFullPath 
                }
                else {
                    $splitvars = $HashKeys.Split("|")
                    [int] $len = [int] $splitvars.count 
                    [int] $i = [int] 0 
                    $hasyKeysCombined = ''
                    ForEach ($var in $splitvars) {
                        $i = $i + 1 
                        If ($i -lt $len) {
                            $hasyKeysCombined = $var + "," 
                        }
                        else {
                            $hasyKeysCombined = $hasyKeysCombined + $var 
                        }
                    }
                    " WITH ( DISTRIBUTION = HASH(" + $hasyKeysCombined + ")  )" >> $CreateDesiredTableFileFullPath 
                }

            }
            else {
                Write-Host "Creating Desired Table. Incorrect or Missing Desired DISTRIBUTION Type for " $SchemaName"."$TableName -ForegroundColor red
                " WITH ( DISTRIBUTION = " + $DesiredDistributionType  + " ) -- Please Check This Table Configurations! "  >> $CreateDesiredTableFileFullPath 
            }
        
            " AS SELECT * FROM " + $DatabaseName + "." + $SchemaName + "." + $TableName >> $CreateDesiredTableFileFullPath 
            "GO; " >> $CreateDesiredTableFileFullPath 
            " " >> $CreateDesiredTableFileFullPath 
        }

        # 3A Back Up and Rename Tables 
        if (($BackupAndRenameTableFlag -eq '1')  -and ( $DesiredDistributionType -ne '-1' ))  {
            "RENAME OBJECT " + $SchemaName + "." + $TableName + " to " + $TableName + "_Backup">> $BackupAndRenameTableFileFullPath
            "RENAME OBJECT " + $SchemaName + "." + $TableName    + "_Desired to " + $TableName >> $BackupAndRenameTableFileFullPath
            "GO " >>  $BackupAndRenameTableFileFullPath 
            " " >> $BackupAndRenameTableFileFullPath
        }

       
        # 3B. Drop and Rename Tables 
        if (($DropAndRenameTableFlag -eq '1') -and  ($DesiredDistributionType -ne '-1' ))  {
            "IF (OBJECT_ID('" + $DatabaseName + "." + $SchemaName + "." + $TableName + "','U') IS NOT NULL)" + " DROP TABLE " + $DatabaseName + "." + $SchemaName + "." + $TableName >>  $DropAndRenameTableFileFullPath
            "RENAME OBJECT " +  $SchemaName + "." + $TableName  + "_Desired to " + $TableName >> $DropAndRenameTableFileFullPath
            "GO " >>  $DropAndRenameTableFileFullPath 
            " " >> $DropAndRenameTableFileFullPath
        }

        # 4. Create Sister Tables 
        if ( ($CreateSisterTableFlag -eq '1')  -and  ($DesiredDistributionType -ne '-1' ) ) {
            "CREATE TABLE " + $DatabaseName + "." + $SchemaName + "." + $TableName + "_B " >> $CreateSisterTableFileFullPath 
            if ($DesiredDistributionType.toUpper() -eq "REPLICATE") {
                " WITH ( DISTRIBUTION = REPLICATE ) " >> $CreateSisterTableFileFullPath 
            }
            elseif ($DesiredDistributionType.toUpper() -eq "ROUND_ROBIN") {
                " WITH ( DISTRIBUTION = ROUND_ROBIN ) " >> $CreateSisterTableFileFullPath 
            }
            elseif ($DesiredDistributionType.toUpper() -eq "HASH") {
                if ( [string]::IsNullOrEmpty($HashKeys) ) {
                    Write-Host "Creating Sister Table. Missing DistributionKeysIfHash Field! Check this table configuratrion: " $SchemaName"."$TableName -ForegroundColor red
                    " WITH ( DISTRIBUTION = HASH( Missing Hash Keys!!!! ) " + " -- Please Check This Table Configurations! " >> $CreateSisterTableFileFullPath 
                }
                else 
                {
                    $splitvars = $HashKeys.Split("|")
                    [int] $len = [int] $splitvars.count 
                    [int] $i = [int] 0 
                    $hasyKeysCombined = ''
                    ForEach ($var in $splitvars) {
                        $i = $i + 1 
                        If ($i -lt $len) {
                            $hasyKeysCombined = $var + "," 
                        }
                        else {
                            $hasyKeysCombined = $hasyKeysCombined + $var 
                        }
    
                    }
                    " WITH ( DISTRIBUTION = HASH(" + $hasyKeysCombined + ")  )" >> $CreateSisterTableFileFullPath 
                }
            }
            else {
                Write-Host "Creating Sister Table. Incorrect or Missing Desired DISTRIBUTION Type for " + $DatabaseName"."$SchemaName"."$TableName -ForegroundColor red
                " WITH ( DISTRIBUTION = " + $DesiredDistributionType  + " ) -- Please Check This Table Configurations! "  >> $CreateSisterTableFileFullPath 
            }
    
            " AS SELECT * FROM " + $DatabaseName + "." + $SchemaName + "." + $TableName >> $CreateSisterTableFileFullPath 
            "GO; " >> $CreateSisterTableFileFullPath 
            " " >> $CreateSisterTableFileFullPath 
        }
      
        # 5. Generate Insert Into Statements From Heap
        if  ($GenerateInsertIntoFromHeapFlag -eq '1') {
            "INSERT INTO " + $DatabaseName + "." + $SchemaName + "." + $TableName  >>  $InsertIntoStmtFromHeapFileFullPath 
            "SELECT * FROM  " + $DatabaseName + "." + $SchemaName + "." + $TableName + "_Heap" >>  $InsertIntoStmtFromHeapFileFullPath 
            "GO " >>   $InsertIntoStmtFromHeapFileFullPath 
            " " >>  $InsertIntoStmtFromHeapFileFullPath 
        }

        # 5A. Generate Insert Into Statements From Staging Tables
         if  ($GenerateInsertIntoFromStagingFlag -eq '1') {
            "INSERT INTO " + $DatabaseName + "." + $SchemaName + "." + $TableName  >>  $InsertIntoStmtFromStagingFullPath 
            "SELECT * FROM  " + $DatabaseName + "." + $StagingSchemaName + "." + $TableName >>  $InsertIntoStmtFromStagingFullPath 
            "GO " >>   $InsertIntoStmtFromStagingFullPath 
            " " >>  $InsertIntoStmtFromStagingFullPath 
        }

        # 6. Generate Insert Into Statements From Sister Table 
        if ( ($GenerateInsertIntoSisterFlag -eq '1') -and  ($DesiredDistributionType -ne '-1' )) {
            "INSERT INTO " + $DatabaseName + "." + $SchemaName + "." + $TableName  >>  $InsertIntoStmtFromSisterFileFullPath 
            "SELECT * FROM  " + $DatabaseName + "." + $SchemaName + "." + $TableName + "_B" >>  $InsertIntoStmtFromSisterFileFullPath 
            "GO " >>   $InsertIntoStmtFromSisterFileFullPath 
            " " >>  $InsertIntoStmtFromSisterFileFullPath 
        }

        # 7. Utility - Drop Backup Table Scripts 
        if ($DropTableUtilityFlag -ne '0') {
            $splitvars = $DropTableUtilityFlag.Split("|")
            ForEach ($var in $splitvars) {
                "IF (OBJECT_ID('" + $DatabaseName + "." + $SchemaName + "." + $TableName + $var + "','U') IS NOT NULL)" + " DROP TABLE " + $DatabaseName + "." + $SchemaName + "." + $TableName + $var >>  $DropTableUtilityFileFullPath 
                "GO " >>  $DropTableUtilityFileFullPath 
            }
            " " >>  $DropTableUtilityFileFullPath

        }
        
        # 8. Create Table Stats 
        if (($CreateTableStatsFlag -eq '1') -and ($ThisTableStatsFlag.ToUpper() -ne 'NO') ) {
            if ( [string]::IsNullOrEmpty($StatsColumns) ) {
                # Will not create statistics 
                Write-Host " Skipped Stats Creation for this table since [StatsColumns] field was empty: " $DatabaseName"."$SchemaName"."$TableName -ForegroundColor Yellow
            }
            else {
                # Below cast is critical to get the correct results! 
                $StatsScanRateInt = [int] $StatsScanRate 
                if (($StatsScanRateInt -lt 0) -or ($StatsScanRateInt -gt 100)) {
                    "-- Did not get expected specifications for this table. StatsScanRate was set " + $StatsScanRate >>  $CreateTableStatsFileFullPath 
                    "-- Set to create Stats with Full Scan. " >>  $CreateTableStatsFileFullPath 
                    "-- Check your config file and re-run Powershell Code Generation program if needed. " >>  $CreateTableStatsFileFullPath 
                    $StatsScanRate = 100
                }

                $splitvars = $StatsColumns.Split("|")
                [int] $len = [int] $splitvars.count 
                [int] $i = [int] 0 
                $hasyKeysCombined = ''
                ForEach ($var in $splitvars) {
                    $i = $i + 1 
                    If ($i -lt $len) {
                        $hasyKeysCombined = $var + "," 
                    }
                    else {
                        $hasyKeysCombined = $hasyKeysCombined + $var 
                    }
                }
                "CREATE STATISTICS " + "STATS_" + $DatabaseName + "_" + $SchemaName + "_" + $TableName  >>  $CreateTableStatsFileFullPath 
                " ON " + $DatabaseName + "." + $SchemaName + "." + $TableName >>  $CreateTableStatsFileFullPath 
                " (" + $hasyKeysCombined + ")">>  $CreateTableStatsFileFullPath 
                if ($StatsScanRate -eq '100') {
                    "WITH FULLSCAN" >>  $CreateTableStatsFileFullPath

                }
                else {
                    " WITH SAMPLE " + $StatsScanRate + " PERCENT; " >> $CreateTableStatsFileFullPath
                }
                "GO " >>  $CreateTableStatsFileFullPath 
                " " >>  $CreateTableStatsFileFullPath 
            }
        }


        # 9. Drop Table Statistics 
        if ( ($DropTableStatsFlag -eq '1') -and ($ThisTableStatsFlag.ToUpper() -ne 'NO'))  {

            if ( [string]::IsNullOrEmpty($StatsColumns) ) {
                # Do nothing for this task 
            }
            else {
                $StatsName = $SchemaName + "." + $TableName + "." + "STATS_" + $DatabaseName + "_"+ $SchemaName + "_" + $TableName

                "DROP STATISTICS " + $StatsName >>  $DropTableStatsFileFullPath 
                "GO " >>  $DropTableStatsFileFullPath 
                " " >>  $DropTableStatsFileFullPath 
            }

           
        }

        # 10A. Update Table Stats With Full Scan 
        if ( ($UpdateTableStatsFullScanFlag -eq '1') -and ($ThisTableStatsFlag.ToUpper() -ne 'NO')) {
            if ( [string]::IsNullOrEmpty($StatsColumns) ) {
                Write-Host " Update Stats with Full Scan. Skipped this table as stats was not created for it: " $DatabaseName"."$SchemaName"."$TableName -ForegroundColor Yellow 
                "--Skipped this table as stats was not created for it: " + $SchemaName + "." + $TableName >>  $UpdateTableStatsFullScanFileFullPath
                " " >>  $UpdateTableStatsFullScanFileFullPath 
            }
            else {
                "UPDATE STATISTICS " + $DatabaseName + "." + $SchemaName + "." + $TableName + " WITH FULLSCAN; ">>  $UpdateTableStatsFullScanFileFullPath 
                "GO " >>   $UpdateTableStatsFullScanFileFullPath 
                " " >>  $UpdateTableStatsFullScanFileFullPath 
            }
           
        }

        # 10B. Update Table Stats With Custom Scan 
        if ( ($UpdateTableStatsCustomScanFlag -eq '1') -and ($ThisTableStatsFlag.ToUpper() -ne 'NO') )  {
            if ( [string]::IsNullOrEmpty($StatsColumns) ) {
                Write-Host " Update Stats with Custom Scan. Skipped this table as stats was not created for it: " $DatabaseName"."$SchemaName"."$TableName -ForegroundColor Yellow 
                "--Skipped this table as stats was not created for it: " + $DatabaseName + "." + $SchemaName + "." + $TableName >>  $UpdateTableStatsCustomScanFileFullPath 
                " " >>  $UpdateTableStatsCustomScanFileFullPath 
            }
            else {
                # Below cast is critical to get the correct results! 
                $StatsScanRateInt = [int] $StatsScanRate 
                if (($StatsScanRateInt -lt 0) -or ($StatsScanRateInt -gt 100)) {
                    "-- Did not get expected specifications for this table. " >>  $UpdateTableStatsCustomScanFileFullPath 
                    "-- StatsScanRate was set " + $StatsScanRate >>  $UpdateTableStatsCustomScanFileFullPath
                    "-- Set to create Stats with Full Scan. " >>  $UpdateTableStatsCustomScanFileFullPath 
                    "-- Check your config file and re-run Powershell Code Generation program if needed. " >>  $UpdateTableStatsCustomScanFileFullPath 
                    $StatsScanRate = 100
                }

                "UPDATE STATISTICS " + $DatabaseName + "." + $SchemaName + "." + $TableName + " WITH SAMPLE " + $StatsScanRate + " PERCENT;">>  $UpdateTableStatsCustomScanFileFullPath 
                "GO " >>   $UpdateTableStatsCustomScanFileFullPath
                " " >>  $UpdateTableStatsCustomScanFileFullPath
            }
          
        }


        # 11. Rebuild Table Index 
        if ($RebuildTableIndexFlag -eq '1') {
            "ALTER INDEX ALL ON " + $DatabaseName + "." + $SchemaName + "." + $TableName + " REBUILD; ">>  $RedbuildTableIndexFileFullPath 
            "GO " >>   $RedbuildTableIndexFileFullPath 
            " " >>  $RedbuildTableIndexFileFullPath 
 
        }

        # 12. Reorganize Table Index 
        if ($ReorganizeTableIndexFlag -eq '1') {
            "ALTER INDEX ALL ON " + $DatabaseName + "." + $SchemaName + "." + $TableName + " REORGANIZE; ">>  $ReorganizeTableIndexFileFullPath 
            "GO " >>  $ReorganizeTableIndexFileFullPath 
            " " >>  $ReorganizeTableIndexFileFullPath 
 
        }

        
         # 13. Drop Table
         if ($DropTablesFlag -eq '1')  {
            "IF (OBJECT_ID('" + $DatabaseName + "." + $SchemaName + "." + $TableName + "','U') IS NOT NULL)" + " DROP TABLE " + $DatabaseName + "." + $SchemaName + "." + $TableName >>  $DropTablesFileFullPath
            "GO " >>  $DropTablesFileFullPath 
            " " >> $DropTablesFileFullPath
        }

    }

}


$ProgramFinishTime = (Get-Date)

$ProgDuration = GetDuration  -StartTime  $ProgramStartTime -FinishTime $ProgramFinishTime

Write-Host "Total time runing this program: " $ProgDuration.DurationText 
Write-Host $ProgDuration.Hours" Hours " 
Write-Host $ProgDuration.Minutes" Minutes " 
Write-Host $ProgDuration.Seconds " Seconds " 
Write-Host $ProgDuration.Milliseconds " Milliseconds " 

Write-Host "Generated Code is stored in $OutputFilePath "  -ForegroundColor Green

Write-Host "  Done! Have a great day!" -ForegroundColor Cyan