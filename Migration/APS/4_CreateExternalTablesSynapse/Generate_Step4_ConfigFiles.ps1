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
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\4_CreateExternalTablesSynapse\Generate_Step4_ConfigFiles.ps1


#Requires -Version 5.1
#Requires -Modules SqlServer


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
$defaultDriverFileName = "$PSScriptRoot\ConfigFileDriver_Step4.csv"
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
		$InputObjectsFolder = $value        
        $AbsoluteInputObjectsFolder = Get-AbsolutePath $value

		if (!(Test-Path -Path $AbsoluteInputObjectsFolder))
		{	
			Write-Host "Input File Folder $AbsoluteInputObjectsFolder does not exist." -ForegroundColor Red
			exit (0)
		}
	}
	elseif ($name -eq 'OutputObjectsFolder') { $OutputObjectsFolder = $value }
	elseif ($name -eq 'SchemaMappingFileFullPath')
	{
		$SchemaMappingFileFullPath = Get-AbsolutePath $value

		if (![System.IO.File]::Exists($SchemaMappingFileFullPath)) 
		{	
			Write-Host "Schema Mapping File $SchemaMappingFileFullPath does not exist."  -ForegroundColor Red
			exit (0)
		}
	}
	elseif ($name -eq 'ExternalDataSourceName') { $ExternalDataSourceName = $value }
	elseif ($name -eq 'FileFormat') { $fileFormat = $value }
	elseif ($name -eq 'ExportLocation') { $exportLocation = $value }
	else {
		Write-Host "Encountered unknown configuration item: " + $name + " with Value: " + $value  -ForegroundColor Red
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


# Get all the database names from directory names 
$inputObjectsFolderPath = Get-ChildItem -Path $AbsoluteInputObjectsFolder

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

 	$dbFilePath = Join-Path -Path $InputObjectsFolder -ChildPath $dbName
  
	$inFilePaths.add("Tables",(Join-Path -Path $dbFilePath -ChildPath "Tables"))
    $outFilePaths.add("Tables", (Join-Path -Path $PSScriptRoot -ChildPath ("$dbName" + "_SqldwExtTablesDriver_Generated.csv")) )
	
	foreach ($key in $inFilePaths.Keys)
	{
		$inFileFolder = $inFilePaths[$key]
        $inFileFolderAbsolute = Get-AbsolutePath $inFileFolder
        if (!(Test-Path -Path $inFileFolderAbsolute))
        {
            continue
        }

		if ($OneConfigFile -eq "NO")
		{
			$outCsvFileName = $outFilePaths[$key] 

			if (Test-Path $outCsvFileName)
			{
				Remove-Item $outCsvFileName -Force
			}
		}

		foreach ($f in Get-ChildItem -path $inFileFolderAbsolute  -Filter *.sql)
		{
			$fileName = $f.Name.ToString()

            (Get-Date -Format HH:mm:ss.fff)+" - "+$dbName+" "+$f | Write-Host -ForegroundColor Yellow	 
			 
			$parts = @{} 
			$parts.Clear()

			$firstLine = Get-Content -path $f.FullName -First 1
			
			if($firstLine.ToUpper() -match "^CREATE TABLE")
			{
                $parts = GetObjectNames $firstLine "CREATE TABLE"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE PROC")
			{
				$parts = GetObjectNames $firstLine "CREATE PROC"
			}
			elseif ($firstLine.ToUpper() -match "^CREATE VIEW")
			{
				$parts = GetObjectNames $firstLine "CREATE VIEW"
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
				Write-Output "Unexpected first line here: " $firstLine " in file: " $fileName " DB: " $dbName
			}					 
			 			 
		 	$synapseSchema = $parts.Schema
		 	$objectName = $parts.Object
 
            $apsSchema = $schemaMappingFile | Where-Object {$_.ApsDbName -eq $dbName -and $_.SynapseSchema -eq $synapseSchema} | Select-Object -Property ApsSchema -ExpandProperty ApsSchema
		
			$destSchema = -join($ExtTableShemaPrefix,$synapseSchema) 
			$destObject = -join($ExtTablePrefix,$objectName)
			
			# perDB 
            $exportObjLocation = -join($exportLocation,$dbName,"/",$apsSchema,"_",$objectName)
			
			$externalTableDDLFileName = -join($destSchema, "_", $destObject ) # seperate scehame name and object name 

			$outputObjectsFolderPerDb = Join-Path -Path $OutputObjectsFolder -ChildPath $dbName

			$row = New-Object PSObject 		
			  
			$row | Add-Member -MemberType NoteProperty -Name "Active" -Value "1" -force
		 	$row | Add-Member -MemberType NoteProperty -Name "OutputFolderPath" -Value $outputObjectsFolderPerDb -force 
			$row | Add-Member -MemberType NoteProperty -Name "FileName" -Value $externalTableDDLFileName -force
			$row | Add-Member -MemberType NoteProperty -Name "InputFolderPath" -Value $inFileFolder   -force
			$row | Add-Member -MemberType NoteProperty -Name "InputFileName" -Value $fileName  -force	
			$row | Add-Member -MemberType NoteProperty -Name "SchemaName" -Value $destSchema -force	
		 	$row | Add-Member -MemberType NoteProperty -Name "ObjectName" -Value $destObject -force	
		 	$row | Add-Member -MemberType NoteProperty -Name "DataSource" -Value $ExternalDataSourceName -force
			$row | Add-Member -MemberType NoteProperty -Name "FileFormat" -Value $fileFormat -force
			$row | Add-Member -MemberType NoteProperty -Name "FileLocation" -Value $exportObjLocation -force

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
