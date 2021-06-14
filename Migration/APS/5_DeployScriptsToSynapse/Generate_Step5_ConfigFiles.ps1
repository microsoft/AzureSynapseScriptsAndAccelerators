############################################################################################################
############################################################################################################
#
# Author: Gail Zhou
# August, 2018
# 
############################################################################################################
# Description:
#       Generate Configuration File for APS-to-Synapse migration process 
# It takes input from the the scripts generated in step 3, and 4. 
#
############################################################################################################


# Get config file driver file name 
$defaultDriverFileName = "$PSScriptRoot\ConfigFileDriver_Step5.csv"
$ConfigFileDriverFileName = Read-Host -prompt "Enter the name of the config file driver file or press the 'Enter' key to accept the default [$($defaultDriverFileName)]"
if($ConfigFileDriverFileName -eq "" -or $ConfigFileDriverFileName -eq $null)
{$ConfigFileDriverFileName = $defaultDriverFileName}


Write-Output (" Config Driver File: " + $ConfigFileDriverFileName)

# Import CSV to get contents 
$ConfigFileDriverFile = Import-Csv $ConfigFileDriverFileName 
# The Config File Driver CSV file contains 'Name-Value' pairs. 
ForEach ($csvItem in $ConfigFileDriverFile ) 
{
	$name = $csvItem.Name.Trim()
	$value = $csvItem.Value.Trim() 

	if ($name -eq 'OneConfigFile') { $OneConfigFile = $value.ToUpper() } # YES or No 
	elseif ($name -eq 'GeneratedConfigFileFolder') { $GeneratedConfigFileFolder = $value } 
	elseif ($name -eq 'OneApsExportConfigFileName') { $OneApsExportConfigFileName = $value } 
	elseif ($name -eq 'OneSynapseObjectsConfigFileName') { $OneSynapseObjectsConfigFileName = $value }
	elseif ($name -eq 'OneSynapseImportConfigFileName') { $OneSynapseImportConfigFileName = $value }
	elseif ($name -eq 'OneSynapseExtTablesConfigFileName') { $OneSynapseExtTablesConfigFileName = $value }
	elseif ($name -eq 'ActiveFlag') { $ActiveFlag = $value }
	elseif ($name -eq 'ApsServerName') { $ApsServerName = $value }
	elseif ($name -eq 'SynapseServerName') { $SynapseServerName = $value }  
	elseif ($name -eq 'SynapseDatabaseName') { $SynapseDatabaseName = $value }  
	elseif ($name -eq 'CreateSchemaFlag') { $CreateSchemaFlag = $value }  
	elseif ($name -eq 'SchemaAuth') { $SchemaAuth = $value }  
	elseif ($name -eq 'DropTruncateIfExistsFlag') { $DropTruncateIfExistsFlag = $value }  
	elseif ($name -eq 'Variables') { $Variables = $value }  
	elseif ($name -eq 'SchemaFileFullPath') { $SchemaFileFullPath = $value }  
	elseif ($name -eq 'OutputObjectsFolder') { $OutputObjectsFolder = $value }  # there is really no objects to be produced in step 6
	elseif ($name -eq 'ApsExportScriptsFolder') 
	{ 
		$ApsExportScriptsFolder = $value 
		if (!(Test-Path -Path $ApsExportScriptsFolder))
		{	
			Write-Host "Input File Folder " $ApsExportScriptsFolder " does not exits." -ForegroundColor Red
			#exit (0)
		}
	} 
	elseif ($name -eq 'SynapseImportScriptsFolder') 
	{ 
		$SynapseImportScriptsFolder = $value 
		if (!(Test-Path -Path $SynapseImportScriptsFolder))
		{	
			Write-Host "Input File Folder " $SynapseImportScriptsFolder " does not exits." -ForegroundColor Red
			#exit (0)
		}
	}
	elseif ($name -eq 'SynapseExternalTablesFolder') 
	{ 
		$SynapseExternalTablesFolder = $value 
		if (!(Test-Path -Path $SynapseExternalTablesFolder))
		{	
			Write-Host "Input File Folder " $SynapseExternalTablesFolder " does not exits." -ForegroundColor Red
			#exit (0)
		}
	}
	elseif ($name -eq 'SynapseObjectScriptsFolder') 
	{ 
		$SynapseObjectScriptsFolder = $value 
		if (!(Test-Path -Path $SynapseObjectScriptsFolder))
		{	
			Write-Host "Input File Folder " $SynapseObjectScriptsFolder " does not exits." -ForegroundColor Red
			#exit (0)
		}
	}
	else {
		Write-Host "Encountered unknown configuration item: " + $name + " with Value: " + $value -ForegroundColor Yellow
	}
	Write-Output ("name: " + $name + " value: " + $value) 
}


# Get Schema Mapping File into hashtable - same matrix in python file (step 3)
$smHT = @{}
$schemaMappingFile = Import-Csv $SchemaFileFullPath
$htCounter = 0 
foreach ($item in $schemaMappingFile)
{
	$htCounter++
	$smHT.add($htCounter,  @($item.ApsDbName, $item.ApsSchema, $item.synapseSchema))
}
# Get Synapse Schema based on the schema mapping matrix 
function Get-TargetSchema($dbName, $apsSchema, $hT)
{
	foreach ($key in $hT.keys)
	{	
		$myValues = $hT[$key]
		if (($myValues[0] -eq $dbName) -and $myValues[1] -eq $apsSchema) 
		{
			return $myValues[2] 
		}
	}
}

function Get-ApsSchema($dbName, $synapseSchema, $hT)
{
	foreach ($key in $hT.keys)
	{	
		$myValues = $hT[$key]
		if (($myValues[0] -eq $dbName) -and $myValues[2] -eq $ynapseSchema) 
		{
			return $myValues[1] 
		}
	}
}

Function GetObjectNames ($query, $type)
{
    $parts = @{}
    $parts.Clear()

    if ($type -in ("CREATE STATISTICS", "CREATE NONCLUSTERED INDEX")) {
        $pattern = "^" + $type + "[\s]+(?<objectname>\[?[^\.\]]+\]?)[\s]+ON[\s]+(?<parentobjectname>\[?[^\.\]]+\]?\.\[?[^\.\]]+\]?)[\s]+"
    } elseif ($type -in ("CREATE USER", "CREATE ROLE")) {
        $pattern = "^" + $type + "[\s]+(?<objectname>\[?[^\.\]]+\]?)"
    } else {    
        # Either 2-part name or 3-part name
        $pattern = "^" + $type + "[\s]+(?<objectname>\[?[^\.\]]+\]?\.\[?[^\.\]]+\]?|\[?[^\.\]]+\]?\.\[?[^\.\]]+\]?\.\[?[^\.\]]+\]?)([\s]+|[\s]*\r?$)"
    }

    $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant, Multiline'
    $matches = [regex]::Matches($query, $pattern, $regexOptions)

    if ($matches.Count -eq 0)
    {
        Write-Host $query -ForegroundColor Red
        throw "Query did not match the pattern"
    } 

    $objectName = $matches[0].Groups["objectname"].Value
    $parentObjectName = $matches[0].Groups["parentobjectname"].Value
    $objectNameParts = $objectName.Split(".")
    

    if ($objectNameParts.Count -eq 3) {
        $databaseName = $objectNameParts[0].Replace("[","").Replace("]","")
        $schemaName = $objectNameParts[1].Replace("[","").Replace("]","")
        $objectName = $objectNameParts[2].Replace("[","").Replace("]","")
    }
    elseif ($objectNameParts.Count -eq 2) {
        $databaseName = ""
        $schemaName = $objectNameParts[0].Replace("[","").Replace("]","")
        $objectName = $objectNameParts[1].Replace("[","").Replace("]","")
    }
    elseif ($objectNameParts.Count -eq 1) {
        $databaseName = ""
        $schemaName = ""
        $objectName = $objectNameParts[0].Replace("[","").Replace("]","")
    }
    else {
        Write-Output " Something is not right. Check this input line: " $line " and Type " $type 
    }

    $parts.add("Database", $databaseName) # database
    $parts.add("Schema", $schemaName) # schema
    $parts.add("Object", $objectName) # object
    $parts.add("ParentObject", $parentObjectName) # ParentObject

    return $parts
}


# Get all the database names from directory names 
#$subFolderPaths = Get-ChildItem -Path $SqldwObjectScriptsFolder -Exclude *.dsql -Depth 1
$subFolderPaths = Get-ChildItem -Path $SynapseObjectScriptsFolder -Exclude *.dsql
$allDirNames = Split-Path -Path $subFolderPaths -Leaf
$dbNames = New-Object 'System.Collections.Generic.List[System.Object]'
#get only dbNames 
foreach ($nm in $allDirNames)
{
	if ( (($nm.toUpper() -ne "Tables") -and ($nm.toUpper() -ne "Views") -and  ($nm.toUpper() -ne "SPs") )) { $dbNames.add($nm)} 
}
Write-Output " ---------------------------------------------- "
Write-Output "database names: " $dbNames 
Write-Output " ---------------------------------------------- "

################################################################################
#
# Key Section where each input folder and files are examined
#
################################################################################

# Set up one APS export config file & Synapse import config file
if ($OneConfigFile -eq "YES")
{
	$oneApsExportConfigFileFullPath = $GeneratedConfigFileFolder + $OneApsExportConfigFileName 
	if (Test-Path $oneApsExportConfigFileFullPath)
	{
		Remove-Item $oneApsExportConfigFileFullPath -Force
	}
	$oneSynapseObjectsConfigFileNameFullPath = $GeneratedConfigFileFolder + $OneSynapseObjectsConfigFileName 
	if (Test-Path $oneSynapseObjectsConfigFileNameFullPath)
	{
		Remove-Item $oneSynapseObjectsConfigFileNameFullPath -Force
	}
	$OneSynapseImportConfigFileNameFullPath = $GeneratedConfigFileFolder + $OneSynapseImportConfigFileName 
	if (Test-Path $OneSynapseImportConfigFileNameFullPath)
	{
		Remove-Item $OneSynapseImportConfigFileNameFullPath -Force
	}
	$OneSynapseExtTablesConfigFileNameFullPath = $GeneratedConfigFileFolder + $OneSynapseExtTablesConfigFileName 
	if (Test-Path $OneSynapseExtTablesConfigFileNameFullPath)
	{
		Remove-Item $OneSynapseExtTablesConfigFileNameFullPath -Force
	}

}

# Step 6 To DO List
# (1) Create Tables/Views/SPs in Synapse (take files from step 3) - 
# (2) Create APS external tables (Take files from step 4 export scripts)
# (3) Insert Stattement for Synapse (Take files from step 4 insret statements - import Synapse) 
# (4) Create External Tables in Synapse (take files from step 5)
# (5) Create Indexes and Stats (later...) check with Andy to see if the PS1 works with indexes and stats 

$inFilePaths = @{}
$outFilePaths = @{} 
$oneConfigFilePaths = @{}

$oneConfigFilePaths.add("OneConfigSynapseObjects",$GeneratedConfigFileFolder + $OneSynapseObjectsConfigFileName)
$oneConfigFilePaths.add("OneConfigSynapseExtTables",$GeneratedConfigFileFolder + $OneSynapseExtTablesConfigFileName)
$oneConfigFilePaths.add("OneConfigApsExport",$GeneratedConfigFileFolder + $OneApsExportConfigFileName)
$oneConfigFilePaths.add("OneConfigSynapseImport",$GeneratedConfigFileFolder + $OneSynapseImportConfigFileName)

foreach ($key in $oneConfigFilePaths.Keys)
{
	if (Test-Path $oneConfigFilePaths[$key])
	{
		Remove-Item $oneConfigFilePaths[$key] -Force
	}
}

foreach ($dbName in $dbNames)
{
	$inFilePaths.Clear()
	$outFilePaths.Clear()

	$dbFilePath = $SynapseObjectScriptsFolder + $dbName + "\"
	
	##################################################################
	# Input Files
	#################################################################
	
	
	# from Step 3
	$inFilePaths.add("SynapseTables",$dbFilePath + "Tables\")
	$inFilePaths.add("SynapseViews",$dbFilePath + "Views\" )
	$inFilePaths.add("SynapseSPs",$dbFilePath + "SPs\" )
	$inFilePaths.add("SynapseFunctions",$dbFilePath + "Functions\" )
	$inFilePaths.add("SynapseIndexes",$dbFilePath + "Indexes\" )
	$inFilePaths.add("SynapseStatistics",$dbFilePath + "Statistics\" )
	$inFilePaths.add("SynapseRoles",$dbFilePath + "Roles\" )
	$inFilePaths.add("SynapseUsers",$dbFilePath + "Users\" )
	# from step 5
	$inFilePaths.add("SynapseExtTables",$SynapseExternalTablesFolder + $dbName + "\")

	# from step 4
	$inFilePaths.add("ApsExport",$ApsExportScriptsFolder + $dbName + "\")
	$inFilePaths.add("SynapseImport",$SynapseImportScriptsFolder + $dbName + "\")


	##################################################################
	# output Files
	#################################################################
	# For Synapse 
	$outFilePaths.add("SynapseTables",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_Tables_Generated.csv" )
	$outFilePaths.add("SynapseViews",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_Views_Generated.csv" )
	$outFilePaths.add("SynapseSPs",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_SPs_Generated.csv" )
	$outFilePaths.add("SynapseFunctions",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_Functions_Generated.csv" )
	$outFilePaths.add("SynapseIndexes",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_Indexes_Generated.csv" )
	$outFilePaths.add("SynapseStatistics",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_Statistics_Generated.csv" )
	$outFilePaths.add("SynapseExtTables",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_ExtTables_Generated.csv" )
	$outFilePaths.add("SynapseRoles",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_Roles_Generated.csv" )
	$outFilePaths.add("SynapseUsers",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_Users_Generated.csv" )

	# for APS export and Synapse Import 
	$outFilePaths.add("ApsExport",$GeneratedConfigFileFolder + "$dbName" + "_Aps_Export_Generated.csv"  )
	$outFilePaths.add("SynapseImport",$GeneratedConfigFileFolder + "$dbName" + "_Synapse_Import_Generated.csv"  )

	
	foreach ($key in $inFilePaths.Keys)
	{
        $inFileFolder = $inFilePaths[$key]
        $outCsvFileName = $outFilePaths[$key] 
        if (Test-Path $outCsvFileName)
        {
	        Remove-Item $outCsvFileName -Force
        }
		# test line: to remove later 
		#Write-Output ( " Key: " + $key + "  inFileFolder: " + $inFileFolder  + " outCsvFileName: " + $outCsvFileName )

		# Set Apart the required confi parameters based on key set earlier  
		if ($key -eq "SynapseTables") 
		{ 
			$objectType = "Table" 
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    }
		elseif ($key -eq "SynapseViews") 
		{ 
			$objectType = "View" 
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    } 
		elseif ($key -eq "SynapseSPs") 
		{ 
			$objectType = "SP" 
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    } 
		elseif ($key -eq "SynapseFunctions") 
		{ 
			$objectType = "Function" 
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    } 
		elseif ($key -eq "SynapseIndexes") 
		{ 
			$objectType = "Index" 
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    } 
		elseif ($key -eq "SynapseStatistics") 
		{ 
			$objectType = "Statistic" 
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    } 
		elseif ($key -eq "SynapseRoles") 
		{ 
			$objectType = "Role"
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    } 
		elseif ($key -eq "SynapseUsers") 
		{ 
			$objectType = "User"
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    } 
		elseif ($key -eq "SynapseExtTables") 
		{ 
			$objectType = "EXT"
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
	    } 
		elseif ($key -eq "ApsExport") 
		{ 
			$objectType = "EXT" 
			$serverName = $ApsServerName
			$databaseName = $dbName
		} 
		# this is for Insert Into but we are not creating anything... need to check with Andy 
		# Two lines have internal and external objects/// 
		elseif ($key -eq "SynapseImport")  
		{ 
			$objectType = "EXT"  #???? 
			#$objectType = ""  #???? 
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
        } 
        else 
        {
	        Write-Output ("Unexpected Key for Object Type. Key received: " + $key) 
        }

        if (!(Test-Path $inFileFolder)) {
            continue
        }

		foreach ($f in Get-ChildItem -Path $inFileFolder -Filter *.dsql)
		{
			$fileName = $f.Name.ToString()
			# exclude IDXS_ and STATS_ 
		 	#if (($fileName -Match "IDXS_") -or ($fileName -Match "STATS_"))
		 	#{
			#	 continue 
			#}			 
			 
			$parts = @{}
			$parts.Clear() 

			$query = Get-Content -path $f.FullName -First 2
			
			if($query.ToUpper() -match "^CREATE TABLE")
			{
			    $parts = GetObjectNames $query "CREATE TABLE"
			}
			elseif ($query.ToUpper() -match "^CREATE PROC")
			{
				$parts = GetObjectNames $query "CREATE PROC"
			}
			elseif ($query.ToUpper() -match "^CREATE VIEW")
			{
				$parts = GetObjectNames $query "CREATE VIEW"
			}
			elseif ($query.ToUpper() -match "^CREATE NONCLUSTERED INDEX")
			{
				$parts = GetObjectNames $query "CREATE NONCLUSTERED INDEX"
			}
			elseif ($query.ToUpper() -match "^CREATE FUNCTION")
			{
				$parts = GetObjectNames $query "CREATE FUNCTION"
			}
			elseif ($query.ToUpper() -match "^CREATE STATISTICS")
			{
				$parts = GetObjectNames $query "CREATE STATISTICS"
			}
			elseif ($query.ToUpper() -match "^CREATE EXTERNAL TABLE")
			{
				$parts = GetObjectNames $query "CREATE EXTERNAL TABLE"
			}
			elseif ($query.ToUpper() -match "^CREATE USER")
			{
				$parts = GetObjectNames $query "CREATE USER"
			}
			elseif ($query.ToUpper() -match "^CREATE ROLE")
			{
				$parts = GetObjectNames $query "CREATE ROLE"
			}
			<# 
			# discuss this with Andy 
			INSERT INTO adw_dbo.DimDate
  		SELECT * FROM ext_adw_dbo.ext_DimDate
			Option(Label = 'Import_Table_adw_dbo.DimDate')
			#>
			elseif ($query.ToUpper() -match "^INSERT INTO")
			{
				$parts = GetObjectNames $query "INSERT INTO"
			}
			else 
			{
				Write-Output "Unexpected first line here: " $query
			}		
			 
			$schemaName = $parts.Schema
		 	$objectName = $parts.Object
            $parentObjectName = $parts.ParentObject

			$row = New-Object PSObject 		
			  
			$filefolderNoSlash = $inFileFolder.Substring(0, $inFileFolder.Length-1) # get rid of '/' at end of the path

			#Write-Output "Value " $filefolderNoSlash
			
			$row | Add-Member -MemberType NoteProperty -Name "Active" -Value $ActiveFlag -force
			$row | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $serverName -force
			$row | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $databaseName  -force
			$row | Add-Member -MemberType NoteProperty -Name "FilePath" -Value $filefolderNoSlash -force  
			$row | Add-Member -MemberType NoteProperty -Name "CreateSchema" -Value $CreateSchemaFlag -force
			$row | Add-Member -MemberType NoteProperty -Name "ObjectType" -Value $objectType -force
			$row | Add-Member -MemberType NoteProperty -Name "SchemaAuth" -Value $SchemaAuth  -force
			$row | Add-Member -MemberType NoteProperty -Name "SchemaName" -Value $schemaName -force
			$row | Add-Member -MemberType NoteProperty -Name "ObjectName" -Value $objectName -force
			$row | Add-Member -MemberType NoteProperty -Name "ParentObjectName" -Value $parentObjectName -force
			$row | Add-Member -MemberType NoteProperty -Name "DropTruncateIfExists" -Value $DropTruncateIfExistsFlag -force
			$row | Add-Member -MemberType NoteProperty -Name "Variables" -Value $Variables -force
			$row | Add-Member -MemberType NoteProperty -Name "FileName" -Value 	$fileName  -force

			if ($OneConfigFile -eq "NO")
			{
				Export-Csv -InputObject $row -Path $outCsvFileName -NoTypeInformation -Append -Force 
			}
			elseif ($OneConfigFile -eq "YES")
		 	{
                if ( $key -in ("SynapseTables", "SynapseViews", "SynapseSPs", "SynapseFunctions", "SynapseIndexes", "SynapseStatistics", "SynapseUsers", "SynapseRoles") )
				{
					Export-Csv -InputObject $row -Path  $oneConfigFilePaths.OneConfigSynapseObjects -NoTypeInformation -Append -Force 		 
				}
				elseif ( ($key -eq "SynapseExtTables") )
				{
					Export-Csv -InputObject $row -Path  $oneConfigFilePaths.OneConfigSynapseExtTables -NoTypeInformation -Append -Force 
				}			
				elseif ( ($key -eq "ApsExport"))
				{
					Export-Csv -InputObject $row -Path  $oneConfigFilePaths.OneConfigApsExport -NoTypeInformation -Append -Force 
				}
				elseif ( ($key -eq "SynapseImport"))
				{
					Export-Csv -InputObject $row -Path  $oneConfigFilePaths.OneConfigSynapseImport -NoTypeInformation -Append -Force 
				}
				else 
				{
					Write-Output ("Error: please look at key " + $key )
				}					
			}
			else {
				Write-Output " Check the value of the OneConfigFile. Expected Value: Yes or No. Not expected value : " $OneConfigFile
			}
		}
		if (($OneConfigFile -eq "NO") -and [IO.File]::Exists($outCsvFileName)) 
		{
			Write-Output "**************************************************************************************************************"
			Write-Output ("   Completed writing to : " + $outCsvFileName)
			Write-Output " "
		}	 
	} # end of each folder 
} # enf of foreach ($dbName in $dbNames)



foreach ($key in $oneConfigFilePaths.Keys)
{
	if (($OneConfigFile -eq "YES") -and [IO.File]::Exists($oneConfigFilePaths[$key])) 
	{
		Write-Output " -------------------------------------------------------------------------------------------------------------------- "
		Write-Output ("        Completed writing to combined config File: " + $oneConfigFilePaths[$key] )
		Write-Output " "
	}	 	
}

$finishTime = Get-Date
Write-Output ("          Finished at: " + $finishTime)
Write-Output " "
