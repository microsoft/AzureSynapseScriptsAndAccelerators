############################################################################################################
############################################################################################################
# 
# Author: Gail Zhou
# Augsut, 2018
# 
############################################################################################################
# Description:
#       Generate Configuration File for APS-to-SQLDW migration process 
# It takes input from the schema mapping file used in step 3, and output files produced in step 3 
#
############################################################################################################


# Get config file driver file name 
$defaultDriverFileName = "$PSScriptRoot\ConfigFileDriver_Step5.csv"
$configFileDriverFileName = Read-Host -prompt "Enter the name of the config file driver file or press the 'Enter' key to accept the default [$($defaultDriverFileName)]"
if($configFileDriverFileName -eq "" -or $configFileDriverFileName -eq $null)
{$configFileDriverFileName = $defaultDriverFileName}


# Import CSV to get contents 
$configFileDriverFile = Import-Csv $configFileDriverFileName 
# The Config File Driver CSV file contains 'Name-Value' pairs. 
ForEach ($csvItem in $configFileDriverFile ) 
{
	$name = $csvItem.Name.Trim()
	$value = $csvItem.Value.Trim() 

	if ($name -eq 'OneConfigFile') { $OneConfigFile = $value.ToUpper() } # YES or No 
	elseif ($name -eq 'OneConfigFileName') { $OneConfigFileName = $value } 
	elseif ($name -eq 'GeneratedConfigFileFolder') { $GeneratedConfigFileFolder = $value }
	elseif ($name -eq 'ExtTableShemaPrefix') { $ExtTableShemaPrefix = $value }
	elseif ($name -eq 'ExtTablePrefix') { $ExtTablePrefix = $value }
	elseif ($name -eq 'InputObjectsFolder')
	{
		$InputObjectsFolder = $value
		if (!(Test-Path -Path $InputObjectsFolder))
		{	
			Write-Output "Input File Folder " $InputObjectsFolder " does not exits."
			exit (0)
		}
	}
	elseif ($name -eq 'OutputObjectsFolder') { $OutputObjectsFolder = $value }
	elseif ($name -eq 'SchemaMappingFileFullPath')
	{
		$SchemaMappingFileFullPath = $value
		if (![System.IO.File]::Exists($SchemaMappingFileFullPath)) 
		{	
			Write-Output "Schema Mapping File " $SchemaMappingFileFullPath " does not exits."
			exit (0)
		}
	}
	elseif ($name -eq 'ExternalDataSourceName') { $ExternalDataSourceName = $value }
	elseif ($name -eq 'FileFormat') { $fileFormat = $value }
	elseif ($name -eq 'ExportLocation') { $exportLocation = $value }
	else {
		Write-Output "Encountered unknown configuration item: " + $name + " with Value: " + $value
	}

}

# Get Schema Mapping File into hashtable - same matrix in python file (step 3)
$smHT = @{}
$schemaMappingFile = Import-Csv $SchemaMappingFileFullPath
$htCounter = 0 
foreach ($item in $schemaMappingFile)
{
	$htCounter++
	$smHT.add($htCounter,  @($item.ApsDbName, $item.ApsSchema, $item.SQLDWSchema))
}
# Get SQLDW Schema based on the schema mapping matrix 
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

function Get-ApsSchema($dbName, $sqldwSchema, $hT)
{
	foreach ($key in $hT.keys)
	{	
		$myValues = $hT[$key]
		if (($myValues[0] -eq $dbName) -and $myValues[2] -eq $sqldwSchema) 
		{
			return $myValues[1] 
		}
	}
}


Function GetObjectNames ($query, $type)
{
    $parts = @{}
    $parts.Clear()
    
#    if ($type -in ("CREATE STATISTICS", "CREATE NONCLUSTERED INDEX")) {
#        $pattern = "^" + $type + "[\s]+(?<objectname>[\[]*[^\.]+[\]]*)[\s]+ON[\s]+(?<parentobjectname>[\[]*[^\.]+[\]]*\.[\[]*[^\.]+[\]]*)[\s]+"
#    } elseif ($type -in ("CREATE USER", "CREATE ROLE")) {
#        $pattern = "^" + $type + "[\s]+(?<objectname>[\[]*[^\.]+[\]]*)"
#    } else {    
#        $pattern = "^" + $type + "[\s]+(?<objectname>[\[]*[^\.]+[\]]*\.[\[]*[^\.]+[\]]*)"
#    }
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
#$inputObjectsFolderPath = Get-ChildItem -Path $InputObjectsFolder -Exclude *.dsql -Depth 1
$inputObjectsFolderPath = Get-ChildItem -Path $InputObjectsFolder

$allDirNames = Split-Path -Path $inputObjectsFolderPath -Leaf
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

if ($OneConfigFile -eq "YES")
{
	$combinedOutputFile = $GeneratedConfigFileFolder + $OneConfigFileName 
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
  
	$inFilePaths.add("Tables",$dbFilePath + "Tables\")

	$outFilePaths.add("Tables",$GeneratedConfigFileFolder + "$dbName" + "_SqldwExtTablesDriver_Generated.csv" )
	
	foreach ($key in $inFilePaths.Keys)
	{
		$inFileFolder = $inFilePaths[$key]

        if (!(Test-Path -Path $inFileFolder))
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

		foreach ($f in Get-ChildItem -path $inFileFolder  -Filter *dsql)
		{
			$fileName = $f.Name.ToString()
			# exclude IDXS_ and STATS_ 
		 	#if (($fileName -Match "IDXS_") -or ($fileName -Match "STATS_"))
		 	#{
			#	 continue 
			#}			 

            (Get-Date -Format HH:mm:ss.fff)+" - "+$f | Write-Host -ForegroundColor Yellow	 
			 
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
				Write-Output "Unexpected first line here: " $firstLine " in file: " $fileName " DB: " $dbName
			}					 
			 			 
		 	$sqldwSchema = $parts.Schema
		 	$objectName = $parts.Object
 
			$apsSchema = Get-ApsSchema $dbName $sqldwSchema $smHT
		
			$destSchema = -join($ExtTableShemaPrefix,$sqldwSchema) 
			$destObject = -join($ExtTablePrefix,$objectName)
			
			# perDB 
		  $exportObjLocation = -join($exportLocation,$dbName,"/",$apsSchema,"_",$objectName)
			
			$externalTableDDLFileName = -join($destSchema, "_", $destObject ) # seperate scehame name and object name 

			$outputObjectsFolderPerDb = -join($OutputObjectsFolder,$dbName,"\")

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
