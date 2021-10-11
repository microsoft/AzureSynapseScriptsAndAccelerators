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
#       It takes input from the schema mapping file used in step 2, and output files produced in step 2
#        
# =================================================================================================================================================
# 
# Authors: Gail Zhou, Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\3_CreateAPSExportScriptSynapseImportScript\Generate_Step3_ConfigFiles.ps1


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


###############################################################################################
# User Input Here
###############################################################################################

# Get config file driver file name 
$defaultDriverFileName = "$PSScriptRoot\ConfigFileDriver_Step3.csv"
$configFileDriverFileName = Read-Host -prompt "Enter the name of the config file driver file or press the 'Enter' key to accept the default [$($defaultDriverFileName)]"
if($configFileDriverFileName -eq "" -or $configFileDriverFileName -eq $null)
{$configFileDriverFileName = $defaultDriverFileName}


###############################################################################################
# Main logic Here
###############################################################################################

# Import CSV to get contents 
$configFileDriverFile = Import-Csv $configFileDriverFileName 
# The Config File Driver CSV file contains 'Name-Value' pairs. 
ForEach ($csvItem in $configFileDriverFile ) 
{
	$name = $csvItem.Name.Trim()
	$value = $csvItem.Value.Trim()

	if ($name -eq 'OneConfigFile') { $OneConfigFile = $value.ToUpper() } # YES or No 
	elseif ($name -eq 'OneConfigFileName') { $OneConfigFileName = $value } 
	elseif ($name -eq 'ExtTableShemaPrefix') { $ExtTableShemaPrefix = $value }
	elseif ($name -eq 'ExtTablePrefix') { $ExtTablePrefix = $value }
	elseif ($name -eq 'InputObjectsFolder')
	{
		$InputObjectsFolder = Get-AbsolutePath $value

		if (!(Test-Path -Path $InputObjectsFolder))
		{	
			Write-Host "Input File Folder " + $InputObjectsFolder + " does not exist." -ForegroundColor Red
			exit (0)
		}
	}
	elseif ($name -eq 'SchemaMappingFileFullPath')
	{
		$SchemaMappingFileFullPath = Get-AbsolutePath $value

		if (![System.IO.File]::Exists($SchemaMappingFileFullPath)) 
		{	
			Write-Host "Schema Mapping File " + $SchemaMappingFileFullPath + " does not exist." -ForegroundColor Red
			exit (0)
		}
	}
	elseif ($name -eq 'ApsExportScriptsFolder') 
    { 
        $ApsExportScriptsFolder = $value 
    } 
	elseif ($name -eq 'SynapseImportScriptsFolder') 
    { 
        $SynapseImportScriptsFolder = $value 
    }
	elseif ($name -eq 'SynapseCopyScriptsFolder') 
    { 
        $SynapseCopyScriptsFolder = $value 
    }
	elseif ($name -eq 'ExternalDataSourceName') { $ExternalDataSourceName = $value }
	elseif ($name -eq 'FileFormat') { $FileFormat = $value }
	elseif ($name -eq 'ExportLocation') { $ExportLocation = $value }
	elseif ($name -eq 'StorageAccountName') { $StorageAccountName = $value }
	elseif ($name -eq 'ContainerName') { $ContainerName = $value }
	else {
		Write-Host "Encountered unknown configuration item: " + $name + " with Value: " + $value -ForegroundColor Red
	}

}

# Get Schema Mapping File content
$schemaMappingFile = Import-Csv $SchemaMappingFileFullPath


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
        throw "Query did not match the patter"
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


$inputObjectsFolderPath = Get-ChildItem -Path $InputObjectsFolder 

$allDirNames = Split-Path -Path $inputObjectsFolderPath -Leaf
$dbNames = New-Object 'System.Collections.Generic.List[System.Object]'
#get only dbNames 
foreach ($nm in $allDirNames)
{
	if ( (($nm.toUpper() -ne "Tables") -and ($nm.toUpper() -ne "Views") -and  ($nm.toUpper() -ne "SPs") )) { $dbNames.add($nm)} 
}
Write-Output "---------------------------------------------- "
Write-Output "Database names: " $dbNames 
Write-Output "---------------------------------------------- "

################################################################################
#
# Key Section where each input folder and files are examined
#
################################################################################

if ($OneConfigFile -eq "YES")
{
    $combinedOutputFile = Join-Path -Path $PSScriptRoot -ChildPath $OneConfigFileName 
	if (Test-Path $combinedOutputFile)
	{
		Remove-Item $combinedOutputFile -Force
	}
}


$startTime = Get-Date


$inFilePaths = @{} 
$outFilePaths = @{} 
foreach ($dbName in $dbNames)
{
	$inFilePaths.Clear()
	$outFilePaths.Clear()

 	$dbFilePath = $InputObjectsFolder + $dbName + "\"
 
	# only need this folder to generate Export and Import Scripts 
	$inFilePaths.add("Tables",$dbFilePath + "Tables\")
    $outFilePaths.add("Tables", (Join-Path -Path $PSScriptRoot -ChildPath ("$dbName" + "_ExpImptStmtDriver_Generated.csv")) )
	
	foreach ($key in $inFilePaths.Keys)
	{
		$inFileFolder = $inFilePaths[$key]
		if ($OneConfigFile -eq "NO")
		{
			$outCsvFileName = $outFilePaths[$key] 

			if (Test-Path $outCsvFileName)
			{
				Remove-Item $outCsvFileName -Force
			}
		}
		
        
        if (!(Test-Path -Path $inFileFolder))
        {
            continue
        }

		foreach ($f in Get-ChildItem -path $inFileFolder  -Filter *.sql)
		{
            (Get-Date -Format HH:mm:ss.fff)+" - "+$dbName+" "+$f | Write-Host -ForegroundColor Yellow	 
			 
			$parts = @{}
			$parts.Clear()

			$firstLine = Get-Content -path $f.FullName -First 1
			
			if($firstLine.ToUpper() -match "^CREATE TABLE")
			{
                $parts = getObjectNames $firstLine "CREATE TABLE"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE PROC")
			{
				$parts = getObjectNames $firstLine "CREATE PROC"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE VIEW")
			{
				$parts = getObjectNames $firstLine "CREATE VIEW"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE NONCLUSTERED INDEX")
			{
				$parts = GetObjectNames $firstLine "CREATE NONCLUSTERED INDEX"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE FUNCTION")
			{
				$parts = GetObjectNames $firstLine "CREATE FUNCTION"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE STATISTICS")
			{
				$parts = GetObjectNames $firstLine "CREATE STATISTICS"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE EXTERNAL TABLE")
			{
				$parts = GetObjectNames $firstLine "CREATE EXTERNAL TABLE"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE USER")
			{
				$parts = GetObjectNames $firstLine "CREATE USER"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE ROLE")
			{
				$parts = GetObjectNames $firstLine "CREATE ROLE"
			}
			else 
			{
				Write-Output "Unexpected first line here: " $firstLine " in file: " $f.FullName
			}		
			 
		 	$synapseSchema = $parts.Schema
		 	$objectName = $parts.Object
 
 
            $apsSchema = $schemaMappingFile | Where-Object {$_.ApsDbName -eq $dbName -and $_.SynapseSchema -eq $synapseSchema} | Select-Object -Property ApsSchema -ExpandProperty ApsSchema

			$destSchema = -join($ExtTableShemaPrefix,$synapseSchema) 
			$destObject = -join($ExtTablePrefix,$objectName)
			
            $exportObjLocation = -join($ExportLocation,$dbName,"/",$apsSchema,"_",$objectName) # seperate scehame name and object name 
			$exportObjectFileName = -join($apsSchema,"_",$objectName) # seperate scehame name and object name 

			$apsExportScriptsFolderPerDb = Join-Path -Path $ApsExportScriptsFolder -ChildPath $dbName

			$synapseImportScriptsFolderPerDb = Join-Path -Path $SynapseImportScriptsFolder -ChildPath $dbName
			
			$synapseCopyScriptsFolderPerDb = Join-Path -Path $SynapseCopyScriptsFolder -ChildPath $dbName

		 	$row = New-Object PSObject 		 
			$row | Add-Member -MemberType NoteProperty -Name "Active" -Value "1" -force
			$row | Add-Member -MemberType NoteProperty -Name "DatabaseName" -Value $dbName -force
			$row | Add-Member -MemberType NoteProperty -Name "OutputFolderPath" -Value $apsExportScriptsFolderPerDb -force
		 	$row | Add-Member -MemberType NoteProperty -Name "FileName" -Value $exportObjectFileName -force
		 	$row | Add-Member -MemberType NoteProperty -Name "SourceSchemaName" -Value $apsSchema -force
		 	$row | Add-Member -MemberType NoteProperty -Name "SourceObjectName" -Value $objectName -force	
		 	$row | Add-Member -MemberType NoteProperty -Name "DestSchemaName" -Value $destSchema -force
		 	$row | Add-Member -MemberType NoteProperty -Name "DestObjectName" -Value $destObject -force
		 	$row | Add-Member -MemberType NoteProperty -Name "DataSource" -Value $ExternalDataSourceName -force
			$row | Add-Member -MemberType NoteProperty -Name "FileFormat" -Value $FileFormat -force
		 	$row | Add-Member -MemberType NoteProperty -Name "ExportLocation" -Value $exportObjLocation -force
			$row | Add-Member -MemberType NoteProperty -Name "InsertFilePath" -Value $synapseImportScriptsFolderPerDb -force
			$row | Add-Member -MemberType NoteProperty -Name "CopyFilePath" -Value $synapseCopyScriptsFolderPerDb -force
			$row | Add-Member -MemberType NoteProperty -Name "ImportSchema" -Value $synapseSchema -force
		 	$row | Add-Member -MemberType NoteProperty -Name "StorageAccountName" -Value $StorageAccountName -force
		 	$row | Add-Member -MemberType NoteProperty -Name "ContainerName" -Value $ContainerName -force
			 
			if ($OneConfigFile -eq "NO")
			{
				Export-Csv -InputObject $row -Path $outCsvFileName -NoTypeInformation -Append -Force 
			}
		 	elseif ($OneConfigFile -eq "YES")
		 	{
				Export-Csv -InputObject $row -Path $combinedOutputFile -NoTypeInformation -Append -Force 
			}
			else {
				Write-Output " Check the value of the OneConfigFile. Expected Value: Yes or No. Not expected value : " $OneConfigFile
			}
		}
		if (($OneConfigFile -eq "NO") -and [IO.File]::Exists($outCsvFileName)) 
		{
			Write-Output "          Completed writing to outCsvFileName: " $outCsvFileName
		}	 	
	} # end of each folder 
} # enf of foreach ($dbName in $dbNames)

if ( ($OneConfigFile -eq "YES") -and ([IO.File]::Exists($combinedOutputFile)) )
{
	Write-Output " ------------------------------------------------------------------------------------------------- "
	Write-Output " Completed writing to : " $combinedOutputFile
	Write-Output " ------------------------------------------------------------------------------------------------- "
}	 	

$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
