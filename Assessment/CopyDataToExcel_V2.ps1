# FileName: CopyDataToExcel.ps1 
# =================================================================================================================================================
# Scriptname: CopyDataToExcel.ps1 
# 
# Change log:
# Created: August, 2018
# Author(s): Andy Isley and Gaiye "Gail" Zhou
# Company: 
# =================================================================================================================================================
#
# =================================================================================================================================================
# SCRIPT BODY
# =================================================================================================================================================


function Display-ErrorMsg($ImportError, $ErrorMsg) {
  Write-Host $ImportError  -ForegroundColor Red
}

function Display-LogMsg($LogMsg) {
  if ($VerboseLogging -eq "True") { Write-Host  (Get-Date).ToString() $LogMsg -ForegroundColor Green }
}

$DeleteFile = 'N'
$VerboseLogging = "True"

#$defaultPreAssessmentOutputPath = "C:\APS2SQLDW\Output\0_Assessment\APS"
$defaultPreAssessmentOutputPath = "C:\SQLDW_Migration\Output\0_Assessment"
$PreAssessmentOutputPath = Read-Host -prompt "Enter the Path to the Pre-Assessment output files or Press 'Enter' to accept default: [$($defaultPreAssessmentOutputPath)]"
if($PreAssessmentOutputPath -eq "" -or $PreAssessmentOutputPath -eq $null) 
{
  $PreAssessmentOutputPath = $defaultPreAssessmentOutputPath
}

$defaultEstimationConfigPath = "C:\SQLDW_Migration\0_Assessment"
$EstimationConfigPath = Read-Host -prompt "Enter the Path where estimation framework files are stored or Press 'Enter' to accept default: [$($defaultEstimationConfigPath)]"
if($EstimationConfigPath -eq "" -or $EstimationConfigPath -eq $null) 
{
  $EstimationConfigPath = $defaultEstimationConfigPath
}


$defaultExcelFileName = "PreAssessment.xlsx"
$ExcelFileName = Read-Host -prompt "Enter the name of the PreAssessment Output file or Press 'Enter' to accept default: [$($defaultExcelFileName )]"
if($ExcelFileName -eq "" -or $ExcelFileName -eq $null)
{
  $ExcelFileName = $defaultExcelFileName  
}

# This is the estimation file that to be used to generate an initial estimation on a few items 
$defaultEstCodeAndDataFileName = $EstimationConfigPath + "\Estimation_Code_And_Data.xlsx"
$EstCodeAndDataFile = Read-Host -prompt "Enter the full path of the Estimation Template or press 'Enter' to accept default: [($defaultEstCodeAndDataFileName )]"
if($EstCodeAndDataFile -eq "" -or $EstCodeAndDataFile -eq $null)
{
  $EstCodeAndDataFile = $defaultEstCodeAndDataFileName  
}


# This is the estimation framework that to be used to generate an initial estimation for an migration project
$defaultFrameworkFileName = $EstimationConfigPath + "\Estimation_Framework.xlsx"
$FrameworkFile = Read-Host -prompt "Enter the full path of the Estimation Framework or press 'Enter' to accept default: [($defaultFrameworkFileName )]"
if($FrameworkFile -eq "" -or $FrameworkFile -eq $null)
{
  $FrameworkFile = $defaultFrameworkFileName  
}



$PreAssessment_ExcelFile =  $PreAssessmentOutputPath + '\' + $ExcelFileName
# Will produce these two files 'quietly' without asking file names from user 

$TableDataFile = $PreAssessmentOutputPath + '\' + "TableDataFile.csv" 
$EstimationDataFile = $PreAssessmentOutputPath + '\' + "EstimationDataFile.xlsx"


$dir = $PreAssessmentOutputPath
$latest = Get-ChildItem -Path $dir -File 'ObjectCount*' | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$ObjectCount_File = $latest.name

$latest = Get-ChildItem -Path $dir -File 'ShowSpaceUsed*' | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$ShowSpaceUsed_File = $latest.name

$latest = Get-ChildItem -Path $dir -File 'TableMetaData*' | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$TableMetadata_File = $latest.name

$latest = Get-ChildItem -Path $dir -File 'Version*' | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$APSVersion_File = $latest.name

$latest = Get-ChildItem -Path $dir -File 'Distributions*' | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$APSDistributions_File = $latest.name

#####################################################################################################
# Added TablesToScript ViewsToScript, and SPsToScript, by Gail Zhou November 28, 2018

$latest = Get-ChildItem -Path $dir -File 'TablesToScript*' | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$TablesToScript_File = $latest.name

$latest = Get-ChildItem -Path $dir -File 'ViewsToScript*' | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$ViewsToScript_File = $latest.name

$latest = Get-ChildItem -Path $dir -File 'SPsToScript*' | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$SPsToScript_File = $latest.name
######################################################################################################

if (!(test-path $PreAssessmentOutputPath))
{
	New-item "$PreAssessmentOutputPath\" -ItemType Dir | Out-Null
}

If (Test-Path $PreAssessment_ExcelFile)
{
  $DeleteFile = Read-Host -prompt "Would you like to overwrite the existing excel File $PreAssessment_ExcelFile (Y/N)?"
  if($DeleteFile.ToUpper() -eq "Y") 
  {
    Remove-Item $PreAssessment_ExcelFile -ErrorAction Ignore
  }
  else 
  {
    Display-LogMsg ("Please rename or make a copy of the file, and then try again.")
    exit
  }
}

# Remove old table data file
If (Test-Path $TableDataFile)
{
  Remove-Item $TableDataFile -ErrorAction Ignore
}
# Remove old estimation data file
If (Test-Path $EstimationDataFile)
{
  Remove-Item $EstimationDataFile -ErrorAction Ignore
}

$ShowSpaceUsed_File = $PreAssessmentOutputPath + '\' + $ShowSpaceUsed_File 
$ObjectCount_File = $PreAssessmentOutputPath + '\' + $ObjectCount_File
$TableMetadata_File = $PreAssessmentOutputPath + '\' + $TableMetadata_File
$APSVersion_File = $PreAssessmentOutputPath + '\' + $APSVersion_File
$APSDistributions_File = $PreAssessmentOutputPath + '\' + $APSDistributions_File
##########################################################################################
# Added by Gail Zhou
$TablesToScript_File = $PreAssessmentOutputPath + '\' + $TablesToScript_File
$ViewsToScript_File = $PreAssessmentOutputPath + '\' + $ViewsToScript_File
$SPsToScript_File = $PreAssessmentOutputPath + '\' + $SPsToScript_File

#Create the excel files
$excelFile = Export-Excel $PreAssessment_ExcelFile -PassThru
$estExcelFile = Export-Excel $EstimationDataFile -PassThru



#Import ObjectCount to its own sheet
Display-LogMsg ("Importing ObjectCount to its own sheet")
$csvFile = Import-Csv $ObjectCount_File
$excelFile = $csvFile | Export-Excel -ExcelPackage $excelFile -WorkSheetname 'ObjectCount' -TableStyle Medium16 -TableName 'ObjectCount' -ClearSheet -AutoSize -PassThru #-Show $false

#Import TableMetadata to its own sheet
Display-LogMsg ('Importing TableMetadata to its own sheet')
$csvFile = Import-Csv $TableMetadata_File
$excelFile = $csvFile | Export-Excel -ExcelPackage $excelFile -WorkSheetname  'TableMetaData' -TableStyle Medium16 -TableName 'TableMetaData' -ClearSheet -AutoSize -PassThru #-Show

#Importing ShowSpaceUsed to its own sheet
Display-LogMsg ('Importing ShowSpaceUsed to its own sheet')
$ShowSpaceUsed = Import-Csv $ShowSpaceUsed_File
$excelFile = $ShowSpaceUsed | Export-Excel -ExcelPackage $excelFile -WorkSheetname  'ShowSpaceUsed' -TableStyle Medium16 -TableName 'ShowSpaceUsed' -ClearSheet -AutoSize -PassThru  #-Show

#Importing Version to its own sheet
Display-LogMsg ('Importing Version to its own sheet')
$csvFile = Import-Csv $APSVersion_File
$excelFile = $csvFile | Export-Excel -ExcelPackage $excelFile -WorkSheetname  'Version' -TableStyle Medium16 -TableName 'Version' -ClearSheet -PassThru -AutoSize

#Importing Distributions to its own sheet
Display-LogMsg ('Importing Distributions to its own sheet')
$csvFile = Import-Csv $APSDistributions_File
$excelFile = $csvFile | Export-Excel -ExcelPackage $excelFile -WorkSheetname  'Distributions' -TableStyle Medium16 -TableName 'Distributions' -ClearSheet -PassThru -AutoSize

# Added November 28, 2018, Gail Zhou
Display-LogMsg ('Importing TablesToScript to its own sheet')
$TablesToScript = Import-Csv $TablesToScript_File
$excelFile = $TablesToScript | Export-Excel -ExcelPackage $excelFile -WorkSheetname  'TablesToScript' -TableStyle Medium16 -TableName 'TablesToScript' -ClearSheet -PassThru -AutoSize

# Added November 28, 2018
#Importing ViewsToScript to its own sheet
Display-LogMsg ('Importing ViewsToScript to its own sheet')
$ViewsToScript = Import-Csv $ViewsToScript_File
$excelFile = $ViewsToScript | Export-Excel -ExcelPackage $excelFile -WorkSheetname  'ViewsToScript' -TableStyle Medium16 -TableName 'ViewsToScript' -ClearSheet -PassThru -AutoSize

# Added November 28, 2018
#Importing SPsToScript to its own sheet
Display-LogMsg ('Importing SPsToScript to its own sheet')
$SPsToScript = Import-Csv $SPsToScript_File
$excelFile = $SPsToScript | Export-Excel -ExcelPackage $excelFile -WorkSheetname  'SPsToScript' -TableStyle Medium16 -TableName 'SPsToScript' -ClearSheet -PassThru -AutoSize


# Building Pivot Tables 
Display-LogMsg ('Building Pivot Tables')

$pt=[ordered]@{}

$pt.ObjectCntPvt=@{
  SourceWorkSheet='ObjectCount'
  PivotRows = "DBName"
  PivotData= @{'ObjectCount'='sum'}
  #IncludePivotChart=$false
  PivotColumns= 'type_desc'
  #Worksheetname= 'ObjectCountPivot'
  }
  
  
$pt.TableSummaryPvt=@{
  SourceWorkSheet='TableMetaData'
  PivotRows = "IsPartitioned"
  PivotData= @{'TableName'='count'}
  PivotColumns= 'distribution_policy_desc'
  PivotFilter= 'DBName','SchemaName'
  }
  
$pt.ShowSpaceSummaryPvt=@{
  SourceWorkSheet='ShowSpaceUsed'
  PivotRows = 'DataBase', 'SchemaName', 'TableName'
  #PivotColumns = 'Rows', 'Data_Space_MB', 'Data_Space_GB', 'Data_Space_TB'
  PivotData= @{'Rows'='Sum'}#;'Data_Space_MB'='Sum';'Data_Space_GB'='Sum';'Data_Space_TB'='Sum'}
  }
  
$excelFile = Export-Excel -ExcelPackage $excelFile -PivotTableDefinition $pt -PassThru -Numberformat "#,##0.0"
  
  
$sheet1 = $excelFile.Workbook.Worksheets["ShowSpaceSummaryPvt"]
Set-Format -Address $sheet1.Cells["B:B"] -NumberFormat "#,##0.0"
  
$excelFile.Save()
$excelFile.Dispose()

Display-LogMsg ('Pivot Tables have been built')

Write-Output("  Output file has been produced: " +  $PreAssessment_ExcelFile ) 

###############################################################################################
# Begin - Processing Data to prepare Estiamtion File 
# Added on November 29, 2018, Gail Zhou
################################################################################################

Display-LogMsg("Processing information about Tables...") 

$rows = New-Object PSObject 
$GrandDataSpaceGB = 0; 
$GrandReservedSpaceGB = 0;
$Table_ROWS = "" 
$Write_Table_ROWS = ""  
ForEach ($item in $TablesToScript ) 
{

    $dbName = $item.DatabaseName
    $schemaName = $item.SchemaName
    $objectName = $item.ObjectName  # was schema.table 
    $tableName = $objectName.split(".")[1]   # just get the table name 
 
    $rows | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $dbName -force
    $rows | Add-Member -MemberType NoteProperty -Name "SchemaName" -Value $schemaName -force
    $rows | Add-Member -MemberType NoteProperty -Name "TableName" -Value $tableName -force

    $matchFound = $false
    $RESERVED_SPACE_GB_Total =  0
    $DATA_SPACE_GB_Total = 0
    $INDEX_SPACE_GB_Total = 0
    $RESERVED_SPACE_GB_Total = 0
    $UNUSED_SPACE_GB_Total = 0
    $Table_ROWS = ""	 
    ForEach ($spaceItem in $ShowSpaceUsed)
    {
      $spaceDbName = $spaceItem.DataBase
      $spaceSchemaName = $spaceItem.SchemaName
      $spaceTableName = $spaceItem.TableName
      $Table_ROWS = $spaceItem.Rows.ToString()
      #$Table_ROWS = $spaceItem.RowsInTable.ToString()
      $RESERVED_SPACE_GB = $spaceItem.RESERVED_SPACE_GB
      $DATA_SPACE_GB = $spaceItem.DATA_SPACE_GB
      $INDEX_SPACE_GB = $spaceItem.INDEX_SPACE_GB
      $UNUSED_SPACE_GB = $spaceItem.UNUSED_SPACE_GB


      if ( ($spaceDbName.Trim().ToUpper() -eq $dbName.Trim().ToUpper()) -and ($spaceSchemaName.trim().ToUpper() -eq $schemaName.trim().ToUpper() ) -and ($spaceTableName.trim().ToUpper() -eq $tableName.trim().ToUpper()) )
      {

        $Write_Table_ROWS = $Table_ROWS
        $RESERVED_SPACE_GB_Total =  $RESERVED_SPACE_GB_Total + $RESERVED_SPACE_GB
        $DATA_SPACE_GB_Total = $DATA_SPACE_GB_Total + $DATA_SPACE_GB
        $INDEX_SPACE_GB_Total = $INDEX_SPACE_GB_Total + $INDEX_SPACE_GB 
        $UNUSED_SPACE_GB_Total = $UNUSED_SPACE_GB_Total + $UNUSED_SPACE_GB

        $GrandDataSpaceGB = $GrandDataSpaceGB + $DATA_SPACE_GB
        $GrandReservedSpaceGB = $GrandReservedSpaceGB + $RESERVED_SPACE_GB
        
        $matchFound  = $true
      }
    }

    if ($matchFound -eq $true) 
    {
      $rows | Add-Member -MemberType NoteProperty -Name "Rows" -Value $Write_Table_ROWS -force
      $rows | Add-Member -MemberType NoteProperty -Name "RESERVED_SPACE_GB" -Value $RESERVED_SPACE_GB_Total -force
      $rows | Add-Member -MemberType NoteProperty -Name "DATA_SPACE_GB" -Value $DATA_SPACE_GB_Total -force   
      $rows | Add-Member -MemberType NoteProperty -Name "INDEX_SPACE_GB" -Value $INDEX_SPACE_GB_Total -force  
      $rows | Add-Member -MemberType NoteProperty -Name "UNUSED_SPACE_GB" -Value $UNUSED_SPACE_GB_Total -force 
      $rows | Export-Csv -Path "$TableDataFile" -Append -Delimiter "," -NoTypeInformation
    }
    elseif ($matchFound -eq $false) 
    {
      $rows | Add-Member -MemberType NoteProperty -Name "Rows" -Value "" -force
      $rows | Add-Member -MemberType NoteProperty -Name "RESERVED_SPACE_GB" -Value ""  -force
      $rows | Add-Member -MemberType NoteProperty -Name "DATA_SPACE_GB" -Value ""  -force   
      $rows | Add-Member -MemberType NoteProperty -Name "INDEX_SPACE_GB" -Value "" -force  
      $rows | Add-Member -MemberType NoteProperty -Name "UNUSED_SPACE_GB" -Value ""  -force 
      $rows | Export-Csv -Path "$TableDataFile" -Append -Delimiter "," -NoTypeInformation
    }
    else {
      Write-Output "Bug, where am I here?"
    }
    
}

Write-Output("  Output file has been produced: " + $TableDataFile ) 

Display-LogMsg(" Generating summary information to aid migration effort estimation...") 
#$SPsList = $SPsToScript | Select-Object DatabaseName, SchemaName, ObjectName.split(".")[1]
$SPsList = $SPsToScript | Select-Object DatabaseName, SchemaName, ObjectName
$ViewsList = $ViewsToScript | Select-Object DatabaseName, SchemaName, ObjectName

#Importing Distributions to its own sheet
Display-LogMsg ('Importing Table Data to its own sheet')
$csvFile = Import-Csv $TableDataFile 
$estExcelFile = $csvFile | Export-Excel -ExcelPackage $estExcelFile -WorkSheetname  'TableData' -TableStyle Medium16 -TableName 'TableData' -ClearSheet -PassThru -AutoSize

Display-LogMsg  ('Importing List of the Stored Procedures to its own sheet')
$estExcelFile = $SPsList | Export-Excel -ExcelPackage $estExcelFile -WorkSheetname  'Stored_Procedures' -TableStyle Medium16 -TableName 'Stored_Procedures' -ClearSheet -PassThru -AutoSize

Display-LogMsg ('Importing List of the Views to its own sheet')
$estExcelFile = $ViewsList | Export-Excel -ExcelPackage $estExcelFile -WorkSheetname  'Views' -TableStyle Medium16 -TableName 'Views' -ClearSheet -PassThru -AutoSize


$rows = New-Object PSObject 
$rows | Add-Member -MemberType NoteProperty -Name "Table_Counts" -Value $TablesToScript.Count -force
$rows | Add-Member -MemberType NoteProperty -Name "SP_Counts" -Value $SPsToScript.Count -force
$rows | Add-Member -MemberType NoteProperty -Name "View_Counts" -Value $ViewsToScript.Count -force
$rows | Add-Member -MemberType NoteProperty -Name "Data_Space_GB" -Value $GrandDataSpaceGB -force
$rows | Add-Member -MemberType NoteProperty -Name "Reserved_Space_GB" -Value $GrandReservedSpaceGB -force

Display-LogMsg ('Importing Summary data to its own sheet')
$estExcelFile = $rows | Export-Excel -ExcelPackage $estExcelFile -WorkSheetname  'Summary' -TableStyle Medium16 -TableName 'Summary' -ClearSheet -PassThru -AutoSize


# Remove old table data file
If ( !(Test-Path $EstCodeAndDataFile))
{
  Display-ErrorMsg("Information! ", "Did not found file " + $EstCodeAndDataFile)
  $estExcelFile.Save()
  $estExcelFile.Dispose()
  exit
}

Display-LogMsg ("Importing  " + $EstCodeAndDataFile + "to its own sheet")
$estTemplate = Import-Excel $EstCodeAndDataFile
$estExcelFile = $estTemplate | Export-Excel -ExcelPackage $estExcelFile -WorkSheetname  'Est_Code_And_Data' -TableStyle Medium16 -TableName 'Est_Code_And_Data' -ClearSheet -PassThru -AutoSize

If ( !(Test-Path $FrameworkFile))
{
  Display-ErrorMsg("Information! ", "Did not found file " + $FrameworkFile)
  $estExcelFile.Save()
  $estExcelFile.Dispose()
  exit
}

Display-LogMsg ("Importing  " + $FrameworkFile + "to its own sheet")

$estFramework = Import-Excel $FrameworkFile
$estExcelFile = $estFramework | Export-Excel -ExcelPackage $estExcelFile -WorkSheetname  'Estimation_Framework' -TableStyle Medium16 -TableName 'Estimation_Framework' -ClearSheet -PassThru -AutoSize

$estExcelFile.Save()
$estExcelFile.Dispose()

Write-Output("  Output file has been produced: " +  $EstimationDataFile ) 



###############################################################################################
# End - Processing Data to prepare Estiamtion File 
################################################################################################
