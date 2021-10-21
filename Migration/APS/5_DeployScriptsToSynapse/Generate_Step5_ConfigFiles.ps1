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
# =================================================================================================================================================
# Description:
#       Generate Configuration File for APS-to-Synapse migration process 
#       It takes input from the the scripts generated in step 3, and 4. 
#        
# =================================================================================================================================================
# 
# Authors: Gail Zhou, Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\5_DeployScriptsToSynapse\\Generate_Step5_ConfigFiles.ps1


#Requires -Version 5.1
#Requires -Modules SqlServer


###############################################################################################
# User Input Here
###############################################################################################

# Get config file driver file name 
$defaultDriverFileName = "$PSScriptRoot\ConfigFileDriver_Step5.csv"
$ConfigFileDriverFileName = Read-Host -prompt "Enter the name of the config file driver file or press the 'Enter' key to accept the default [$($defaultDriverFileName)]"
if($ConfigFileDriverFileName -eq "" -or $ConfigFileDriverFileName -eq $null) {
    $ConfigFileDriverFileName = $defaultDriverFileName
}


###############################################################################################
# Main logic Here
###############################################################################################

Function Get-AbsolutePath
{
    [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$Path
    ) 

    if ([System.IO.Path]::IsPathRooted($Path) -eq $false) {
        return [IO.Path]::GetFullPath( (Join-Path -Path $PSScriptRoot -ChildPath $Path) )
    } else {
        return $Path
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


Write-Output ("Config Driver File: " + $ConfigFileDriverFileName)

$GeneratedConfigFileFolder = $PSScriptRoot

# Import CSV to get contents 
$ConfigFileDriverFile = Import-Csv $ConfigFileDriverFileName 
# The Config File Driver CSV file contains 'Name-Value' pairs. 
ForEach ($csvItem in $ConfigFileDriverFile ) 
{
	$name = $csvItem.Name.Trim()
	$value = $csvItem.Value.Trim() 

	if ($name -eq 'OneConfigFile') { $OneConfigFile = $value.ToUpper() } # YES or No 
	elseif ($name -eq 'OneApsExportConfigFileName') { $OneApsExportConfigFileName = $value } 
	elseif ($name -eq 'OneSynapseObjectsConfigFileName') { $OneSynapseObjectsConfigFileName = $value }
	elseif ($name -eq 'OneSynapseImportConfigFileName') { $OneSynapseImportConfigFileName = $value }
	elseif ($name -eq 'OneSynapseCopyConfigFileName') { $OneSynapseCopyConfigFileName = $value }
	elseif ($name -eq 'OneSynapseExtTablesConfigFileName') { $OneSynapseExtTablesConfigFileName = $value }
	elseif ($name -eq 'ActiveFlag') { $ActiveFlag = $value }
	elseif ($name -eq 'ApsServerName') { $ApsServerName = $value }
	elseif ($name -eq 'SynapseServerName') { $SynapseServerName = $value }  
	elseif ($name -eq 'SynapseDatabaseName') { $SynapseDatabaseName = $value }  
	elseif ($name -eq 'CreateSchemaFlag') { $CreateSchemaFlag = $value }  
	elseif ($name -eq 'SchemaAuth') { $SchemaAuth = $value }  
	elseif ($name -eq 'DropTruncateIfExistsFlag') { $DropTruncateIfExistsFlag = $value }  
	elseif ($name -eq 'Variables') { $Variables = $value }  
	elseif ($name -eq 'SchemaFileFullPath') { 
        $SchemaFileFullPath = $value 
        $SchemaFileFullPath = Get-AbsolutePath $SchemaFileFullPath
    }  
	elseif ($name -eq 'OutputObjectsFolder') { $OutputObjectsFolder = $value }  # there is really no objects to be produced in step 6
	elseif ($name -eq 'ApsExportScriptsFolder') 
	{ 
		$ApsExportScriptsFolder = $value 
        $ApsExportScriptsFolderAbsolute = Get-AbsolutePath $value
		if (!(Test-Path -Path $ApsExportScriptsFolderAbsolute))
		{	
			Write-Host "Input File Folder $ApsExportScriptsFolder does not exist." -ForegroundColor Red
			#exit (0)
		}
	} 
	elseif ($name -eq 'SynapseImportScriptsFolder') 
	{ 
		$SynapseImportScriptsFolder = $value 
        $SynapseImportScriptsFolderAbsolute = Get-AbsolutePath $value

		if (!(Test-Path -Path $SynapseImportScriptsFolderAbsolute))
		{	
			Write-Host "Input File Folder $SynapseImportScriptsFolder does not exist." -ForegroundColor Red
			#exit (0)
		}
	}
	elseif ($name -eq 'SynapseCopyScriptsFolder') 
	{ 
		$SynapseCopyScriptsFolder = $value 
        $SynapseCopyScriptsFolderAbsolute = Get-AbsolutePath $value

		if (!(Test-Path -Path $SynapseCopyScriptsFolderAbsolute))
		{	
			Write-Host "Input File Folder $SynapseCopyScriptsFolder does not exist." -ForegroundColor Red
			#exit (0)
		}
	}
	elseif ($name -eq 'SynapseExternalTablesFolder') 
	{ 
		$SynapseExternalTablesFolder = $value 
        $SynapseExternalTablesFolderAbsolute = Get-AbsolutePath $value 

		if (!(Test-Path -Path $SynapseExternalTablesFolderAbsolute))
		{	
			Write-Host "Input File Folder $SynapseExternalTablesFolder does not exist." -ForegroundColor Red
			#exit (0)
		}
	}
	elseif ($name -eq 'SynapseObjectScriptsFolder') 
	{ 
		$SynapseObjectScriptsFolder = $value 
		$SynapseObjectScriptsFolderAbsolute = Get-AbsolutePath $value 

		if (!(Test-Path -Path $SynapseObjectScriptsFolderAbsolute))
		{	
			Write-Host "Input File Folder $SynapseObjectScriptsFolder does not exist." -ForegroundColor Red
			#exit (0)
		}
	}
	else {
		Write-Host "Encountered unknown configuration item: " + $name + " with Value: " + $value -ForegroundColor Yellow
	}
	Write-Output ("name: " + $name + " value: " + $value) 
}


# Get all the database names from directory names 
$SynapseObjectScriptsFolderAbsolute = Get-AbsolutePath $SynapseObjectScriptsFolder
$subFolderPaths = Get-ChildItem -Path $SynapseObjectScriptsFolderAbsolute -Exclude *.sql
$allDirNames = Split-Path -Path $subFolderPaths -Leaf
$dbNames = New-Object 'System.Collections.Generic.List[System.Object]'
#get only dbNames 
foreach ($nm in $allDirNames)
{
	if ( (($nm.toUpper() -ne "Tables") -and ($nm.toUpper() -ne "Views") -and  ($nm.toUpper() -ne "SPs") )) { $dbNames.add($nm)} 
}
Write-Output "---------------------------------------------- "
Write-Output "database names: " $dbNames 
Write-Output "---------------------------------------------- "


################################################################################
#
# Key Section where each input folder and files are examined
#
################################################################################

# Set up one APS export config file & Synapse import config file
if ($OneConfigFile -eq "YES")
{
	$oneApsExportConfigFileFullPath = Joint-Path -Path $GeneratedConfigFileFolder -ChildPath $OneApsExportConfigFileName 
	if (Test-Path $oneApsExportConfigFileFullPath)
	{
		Remove-Item $oneApsExportConfigFileFullPath -Force
	}
	$oneSynapseObjectsConfigFileNameFullPath = Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneSynapseObjectsConfigFileName 
	if (Test-Path $oneSynapseObjectsConfigFileNameFullPath)
	{
		Remove-Item $oneSynapseObjectsConfigFileNameFullPath -Force
	}
	$OneSynapseImportConfigFileNameFullPath = Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneSynapseImportConfigFileName 
	if (Test-Path $OneSynapseImportConfigFileNameFullPath)
	{
		Remove-Item $OneSynapseImportConfigFileNameFullPath -Force
	}
	$OneSynapseCopyConfigFileNameFullPath = Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneSynapseCopyConfigFileName 
	if (Test-Path $OneSynapseCopyConfigFileNameFullPath)
	{
		Remove-Item $OneSynapseCopyConfigFileNameFullPath -Force
	}
	$OneSynapseExtTablesConfigFileNameFullPath = Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneSynapseExtTablesConfigFileName 
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

$oneConfigFilePaths.add("OneConfigSynapseObjects", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneSynapseObjectsConfigFileName))
$oneConfigFilePaths.add("OneConfigSynapseExtTables", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneSynapseExtTablesConfigFileName))
$oneConfigFilePaths.add("OneConfigApsExport", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneApsExportConfigFileName))
$oneConfigFilePaths.add("OneConfigSynapseImport", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneSynapseImportConfigFileName))
$oneConfigFilePaths.add("OneConfigSynapseCopy", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath $OneSynapseCopyConfigFileName))

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

	$dbFilePath = Join-Path -Path $SynapseObjectScriptsFolder -ChildPath $dbName
	
	##################################################################
	# Input Files
	#################################################################
	
	
	# from Step 3
	$inFilePaths.add("SynapseTables", (Join-Path -Path $dbFilePath -ChildPath "Tables"))
	$inFilePaths.add("SynapseViews", (Join-Path -Path $dbFilePath -ChildPath "Views" ))
	$inFilePaths.add("SynapseSPs",  (Join-Path -Path $dbFilePath -ChildPath "SPs" ))
	$inFilePaths.add("SynapseFunctions", (Join-Path -Path $dbFilePath -ChildPath "Functions" ))
	$inFilePaths.add("SynapseIndexes", (Join-Path -Path $dbFilePath -ChildPath "Indexes" ))
	$inFilePaths.add("SynapseStatistics", (Join-Path -Path $dbFilePath -ChildPath "Statistics" ))
	$inFilePaths.add("SynapseRoles", (Join-Path -Path $dbFilePath -ChildPath "Roles" ))
	$inFilePaths.add("SynapseUsers", (Join-Path -Path $dbFilePath -ChildPath "Users" ))
	# from step 5
	$inFilePaths.add("SynapseExtTables",(Join-Path -Path $SynapseExternalTablesFolder -ChildPath $dbName))

	# from step 4
	$inFilePaths.add("ApsExport", (Join-Path -Path $ApsExportScriptsFolder -ChildPath $dbName))
	$inFilePaths.add("SynapseImport", (Join-Path -Path $SynapseImportScriptsFolder -ChildPath $dbName))
    $inFilePaths.add("SynapseCopy", (Join-Path -Path $SynapseCopyScriptsFolder -ChildPath $dbName))


	##################################################################
	# output Files
	#################################################################
	# For Synapse 
	$outFilePaths.add("SynapseTables", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Tables_Generated.csv" )))
	$outFilePaths.add("SynapseViews", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Views_Generated.csv" )))
	$outFilePaths.add("SynapseSPs", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_SPs_Generated.csv" )))
	$outFilePaths.add("SynapseFunctions", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Functions_Generated.csv" )))
	$outFilePaths.add("SynapseIndexes", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Indexes_Generated.csv" )))
	$outFilePaths.add("SynapseStatistics", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Statistics_Generated.csv" )))
	$outFilePaths.add("SynapseExtTables", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_ExtTables_Generated.csv" )))
	$outFilePaths.add("SynapseRoles", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Roles_Generated.csv" )))
	$outFilePaths.add("SynapseUsers", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Users_Generated.csv" )))

	# for APS export and Synapse Import 
	$outFilePaths.add("ApsExport", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Aps_Export_Generated.csv"  )))
	$outFilePaths.add("SynapseImport", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Import_Generated.csv"  )))
	$outFilePaths.add("SynapseCopy", (Join-Path -Path $GeneratedConfigFileFolder -ChildPath ($dbName+"_Synapse_Copy_Generated.csv"  )))

	
	foreach ($key in $inFilePaths.Keys)
	{
        $inFileFolder = $inFilePaths[$key]
        $outCsvFileName = $outFilePaths[$key] 
        if (Test-Path $outCsvFileName)
        {
	        Remove-Item $outCsvFileName -Force
        }

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
		elseif ($key -eq "SynapseImport")  
		{ 
			$objectType = "IMP"  
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
        } 
		elseif ($key -eq "SynapseCopy")  
		{ 
			$objectType = "COPY"  
			$serverName = $SynapseServerName
			$databaseName = $SynapseDatabaseName
        } 
        else 
        {
	        Write-Output ("Unexpected Key for Object Type. Key received: " + $key) 
        }

        # Get absolute path for infolder
        $inFileFolderAbsolute = Get-AbsolutePath $inFileFolder
        # Skip folder if it does not exist
        if (!(Test-Path $inFileFolderAbsolute)) {
            continue
        }

		foreach ($f in Get-ChildItem -Path $inFileFolderAbsolute -Filter *.sql)
		{
			$fileName = $f.Name.ToString()
			 
			$parts = @{}
			$parts.Clear() 

			$query = Get-Content -path $f.FullName -First 2
			
			if ($query.ToUpper() -match "^CREATE PROC")
			{
				$parts = GetObjectNames $query "CREATE PROC"
			}
			elseif($query.ToUpper() -match "^CREATE TABLE")
			{
			    $parts = GetObjectNames $query "CREATE TABLE"
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
			elseif ($query.ToUpper() -match "^INSERT INTO")
			{
				$parts = GetObjectNames $query "INSERT INTO"
			}
			elseif ($query.ToUpper() -match "^COPY INTO")
			{
				$parts = GetObjectNames $query "COPY INTO"
			}
			else 
			{
				Write-Output "Unexpected first line here: " $query
			}		
			 
			$schemaName = $parts.Schema
		 	$objectName = $parts.Object
            $parentObjectName = $parts.ParentObject

			$row = New-Object PSObject 		
			$row | Add-Member -MemberType NoteProperty -Name "Active" -Value $ActiveFlag -force
			$row | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $serverName -force
			$row | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $databaseName  -force
			$row | Add-Member -MemberType NoteProperty -Name "FilePath" -Value $inFileFolder -force  
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
				elseif ( ($key -eq "SynapseCopy"))
				{
					Export-Csv -InputObject $row -Path  $oneConfigFilePaths.OneConfigSynapseCopy -NoTypeInformation -Append -Force 
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
