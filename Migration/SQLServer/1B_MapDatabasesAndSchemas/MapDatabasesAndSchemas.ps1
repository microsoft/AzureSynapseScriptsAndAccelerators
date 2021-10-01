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
#       Use this to map databases/schemas in DDL scripts extracted from SQL Server. 
#       Parameters driven configuration files are the input of this powershell scripts 
# =================================================================================================================================================
# =================================================================================================================================================
# 
# Authors: Andrey Mirskiy
# Tested with Azure Synaspe Analytics and SQL Server 2017 
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\migratemaster\modules\1B_MapDatabasesAndSchemas\MapDatabasesAndSchemas.ps1


##########################################################################################################

function AddMissingSchemas($query, $defaultSchema)
{
    # \s - single whitespace
    # [\s]* - any number of whitespace
    # [\s]+ - at least one whitespace
    # . - any character
    # [^\s] - anything except for whitespace
    # | - logical OR
    # ^ - start of the string / file

    $patterns = @()

    # Object name should be found in capture group #4 !!!

    # Object name without []
    $patterns += "(^|[\s]+)(FROM)([\s]+)([^'\s\.#\(\)\-\[\]]+?)(\)|[\s]+|[\s]*\r?$)"
    $patterns += "(^|[\s]+)(JOIN|EXEC|EXECUTE)([\s]+)([^'\s\.#\(\)\-\[\]]+?)([\s]+|[\s]*\r?$)"
    #????$patterns += "(?!\-\-)[.]*(^|[\s]+)(FROM|JOIN|EXEC|EXECUTE)([\s]+)([^'\s\.#\(\)\-\[\]]+?)([\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(UPDATE)([\s]+)([^'\s\.#\(\)\-\[\]]+?)([\s]+)SET([\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(DELETE)([\s]+)(?!FROM)([^'\s\.#\(\)\-\[\]]+?)([\s]+|[\s]*\r?$)"                         # DELETE FROM is processed as FROM pattern
    $patterns += "(^[\s]*)(INSERT[\s]+INTO)([\s]+)([^'\s\.#\(\)\-\[\]]+?)(\(|[\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(INSERT)([\s]+)(?!INTO)([^'\s\.#\(\)\-\[\]]+?)(\(|[\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(UPDATE[\s]+STATISTICS)([\s]+)([^'\s\.#\(\)\-\[\]]+?)([\s]+|[\s]*\r?$)"                  # exclude UPDATE STATISTICS '...' (dynamic SQL)
    $patterns += "(^[\s]*)(RENAME[\s]+OBJECT)([\s]+)([^'\s\.#\(\)\-\[\]]+?)([\s]+|[\s]*\r?$)"          
    $patterns += "(^.*)(OBJECT_ID)([\s]*\(')([^'\.#\(\)]+?)('\))"
    # Object name with []
    $patterns += "(^|[\s]+)(FROM)([\s]+)(\[[^'\.#\(\)]+?\])(\)|[\s]+|[\s]*\r?$)"
    $patterns += "(^|[\s]+)(JOIN|EXEC|EXECUTE)([\s]+)(\[[^'\.#\(\)]+?\])([\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(UPDATE)([\s]+)(\[[^'\.#\(\)]+?\])([\s]+)SET([\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(DELETE)([\s]+)(?!FROM)(\[[^'\.#\(\)]+?\])([\s]+|[\s]*\r?$)"                             # DELETE FROM is processed as FROM pattern
    $patterns += "(^[\s]*)(INSERT[\s]+INTO)([\s]+)(\[[^'\.#\(\)]+?\])(\(|[\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(INSERT)([\s]+)(?!INTO)(\[[^'\.#\(\)]+?\])(\(|[\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(UDPATE[\s]+STATISTICS)([\s]+)(\[[^'\.#\(\)]+?\])([\s]+|[\s]*\r?$)"                      # exclude UPDATE STATISTICS '...' (dynamic SQL)
    $patterns += "(^[\s]*)(RENAME[\s]+OBJECT)([\s]+)(\[[^'\.#\(\)]+?\])([\s]+|[\s]*\r?$)"             
    $patterns += "(^.*)(OBJECT_ID)([\s]*\(')(\[[^'\.#\(\)]+?\])('\))"

    # Object name without []
#    $patterns += "(^[\s]*)(CREATE|ALTER|DROP)[\s]+(TABLE|VIEW|PROC|PROCEDURE|FUNCTION)[\s]+(?<objectname>[^#\s\.]+?)([\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(CREATE|ALTER|DROP)[\s]+(TABLE|VIEW|PROC|PROCEDURE|FUNCTION)[\s]+([^#\s\.]+?)(\s|[\s]*\r?$)"
#    $patterns += "(^[\s]*)(TRUNCATE)[\s]+(TABLE)[\s]+([^#\s\.]+?)([\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(TRUNCATE)[\s]+(TABLE)[\s]+([^#\s\.]+?)(\s|[\s]*\r?$)"

    # Object name with []
#    $patterns += "(^[\s]*)(CREATE|ALTER|DROP)[\s]+(TABLE|VIEW|PROC|PROCEDURE|FUNCTION)[\s]+(?<objectname>\[[^#\.]+?\])([\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(CREATE|ALTER|DROP)[\s]+(TABLE|VIEW|PROC|PROCEDURE|FUNCTION)[\s]+(?<objectname>\[[^#\.]+?\])(\s|[\s]*\r?$)"
#    $patterns += "(^[\s]*)(TRUNCATE)[\s]+(TABLE)[\s]+(\[[^#\.]+?\])([\s]+|[\s]*\r?$)"
    $patterns += "(^[\s]*)(TRUNCATE)[\s]+(TABLE)[\s]+(\[[^#\.]+?\])(\s|[\s]*\r?$)"

    foreach ($pattern in $patterns)
    {
        $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant, Multiline'
        $matches = [regex]::Matches($query, $pattern, $regexOptions)

        foreach ($match in $matches)
        {
            if ($match.Groups.Count -lt 5)
            {
                # Didn't find an object name
                continue
            }

            $oldValue = $match.Groups[0].Value
            $oldObjectName = $match.Groups[4].Value
            if ($defaultSchema.Contains(" ")) {
                $newObjectName = "[" + $defaultSchema + "]." + $oldObjectName
            } else {
                $newObjectName = $defaultSchema + "." + $oldObjectName
            }
            $newValue = $oldValue.Replace($oldObjectName, $newObjectName)
            $query = $query.Replace($match.Groups[0].Value, $newValue)
        }
    }

    return $query
}


##########################################################################################################


function AddMissingSchemasSimple($query, $defaultSchema)
{
    $patterns = @()

    # single object name per line, e.g. stored procedure
    $patterns += "^([^\s\.#]+?)$"

    foreach ($pattern in $patterns)
    {
        $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant, Multiline'
        $matches = [regex]::Matches($query, $pattern, $regexOptions)

        foreach ($match in $matches)
        {
            if ($match.Groups.Count -lt 2)
            {
                # Didn't find an object name
                continue
            }

            $oldValue = $match.Groups[0].Value
            $oldObjectName = $match.Groups[1].Value
            $newObjectName = "[" + $defaultSchema + "]." + $oldObjectName
            $newValue = $oldValue.Replace($oldObjectName, $newObjectName)
            $query = $query.Replace($match.Groups[0].Value, $newValue)
        }
    }

    return $query
}

##########################################################################################################


function ChangeSchemas($DatabaseName, $SchemaMappings, $DefaultSchema, $query, $useThreePartNames)
{
    $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant, Multiline'

    foreach ($schemaMapping in $SchemaMappings)
    {
        #if ($schemaMapping.TargetSchema.Contains(" ")) {
        #    $newSchema = "[" + $schemaMapping.TargetSchema + "]"
        #} else {
        #    $newSchema = $schemaMapping.TargetSchema
        #}

        # Always use quoted identifiers
        $newSchema = "[" + $schemaMapping.TargetSchema + "]"

        if ($useThreePartNames) {
            $newSchema = "[" + $schemaMapping.TargetDatabase + "]." + $newSchema                                                # [TargetDatabase].[TargetSchema].
        }

        $newPat = '${prefix}' + $newSchema + '.'                                                                                 # ==> [TargetDatabase].[TargetSchema].

        if ($schemaMapping.SourceSchema -eq $DefaultSchema)
        {
            $oldPat = "(?<prefix>^|[\s]+)(?<objectname>" + $schemaMapping.SourceDatabase + "\.\.)"                                    # SourceDatabase.. 
            $query = $query -replace $oldPat, $newPat

            $oldPat = "(?<prefix>^|[\s]+)(?<objectname>\[" + $schemaMapping.SourceDatabase + "\]\.\.)"                                # [SourceDatabase].. 
            $query = $query -replace $oldPat, $newPat
        }

        $oldPat = "(?<prefix>^|[\s]+)(?<objectname>\[" + $schemaMapping.SourceDatabase + "\]\.\[" + $schemaMapping.SourceSchema + "\]\.)"# [SourceDatabase].[SourceSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "(?<prefix>^|[\s]+)(?<objectname>" + $schemaMapping.SourceDatabase + "\.\[" + $schemaMapping.SourceSchema + "\]\.)"    # SourceDatabase.[SourceSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "(?<prefix>^|[\s]+)(?<objectname>\[" + $schemaMapping.SourceDatabase + "\]\." + $schemaMapping.SourceSchema + "\.)"    # [SourceDatabase].SourceSchema. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "(?<prefix>^|[\s]+)(?<objectname>" + $schemaMapping.SourceDatabase + "\." + $schemaMapping.SourceSchema + "\.)"        # SourceDatabase.SourceSchema. 
        $query = $query -replace $oldPat, $newPat


        # This is for OBJECT_ID('schema.table') scenarios
        $newPat = '''' + $newSchema + '.'                                                                                       # ==> '[SQLDWSchema
        $oldPat = "'(?<objectname>\[" + $schemaMapping.SourceDatabase + "\]\.\[" + $schemaMapping.SourceSchema + "\]\.)"                # '[SourceDatabase].[SourceSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "'(?<objectname>"+$schemaMapping.SourceDatabase + "\.\[" + $schemaMapping.SourceSchema + "\]\.)"                      # 'SourceDatabase.[SourceSchema]. 
        $query = $query -replace $oldPat, $newPat

        $newPat = '''' + $newSchema + '.'                                                                       # ==> '[SQLDWSchema
        $oldPat = "'(?<objectname>\[" + $schemaMapping.SourceDatabase + "\]\." + $schemaMapping.SourceSchema + "\.)"                    # '[SourceDatabase].SourceSchema. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "'(?<objectname>"+$schemaMapping.SourceDatabase + "\." + $schemaMapping.SourceSchema + "\.)"                          # 'SourceDatabase.SourceSchema. 
        $query = $query -replace $oldPat, $newPat


        if ($schemaMapping.SourceDatabase -eq $DatabaseName)
        {
            $newPat = '''' + $newSchema + '.'                                                                                   # ==> '[SQLDWSchema].
            $oldPat = "'(?<objectname>\[" + $schemaMapping.SourceSchema + "\]\.)"                                  # OBJECT_ID('[SourceSchema]. 
            $query = $query -replace $oldPat, $newPat

            $newPat = '''' + $newSchema + '.'                                                                      # ==> '[SQLDWSchema].
            $oldPat = "'(?<objectname>"+$schemaMapping.SourceSchema + "\.)"                                        # OBJECT_ID('SourceSchema.
            $query = $query -replace $oldPat, $newPat


            $newPat = '${prefix}' + $newSchema + '.'                                                                      # ==> [SQLDWSchema].
            $oldPat = "(?<prefix>^|[\s]+)(?<objectname>\[" + $schemaMapping.SourceSchema + "\]\.)"                                  # [SourceSchema]. 
            $query = $query -replace $oldPat, $newPat

            $newPat = '${prefix}' + $newSchema + '.'                                                                      # ==> [SQLDWSchema].
            $oldPat = "(?<prefix>^|[\s]+)(?<objectname>"+$schemaMapping.SourceSchema + "\.)"                                       # SourceSchema.
            $query = $query -replace $oldPat, $newPat
        }
    }

	return $query
}

##########################################################################################################

function FixTempTables($query)
{
    $patterns = @()
    $patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?DISTRIBUTION[\s]*?=[\s]*(?<replicate>REPLICATE)(?<location>[\s]*?,[\s]*?LOCATION[\s]*?=[\s]*?USER_DB)[\s]*?\)"
    $patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?DISTRIBUTION[\s]*?=[\s]*(?<replicate>REPLICATE)[\s]*?\)"
    $patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?HEAP[\s]*?,[\s]*?DISTRIBUTION[\s]*?=[\s]*(?<replicate>REPLICATE)(?<location>[\s]*?,[\s]*?LOCATION[\s]*?=[\s]*?USER_DB)[\s]*?\)"
    $patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?HEAP[\s]*?,[\s]*?DISTRIBUTION[\s]*?=[\s]*(?<replicate>REPLICATE)[\s]*?\)"
    $patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?CLUSTERED[\s]+COLUMNSTORE[\s]+INDEX[\s]*?,[\s]*?DISTRIBUTION[\s]*?=[\s]*(?<replicate>REPLICATE)(?<location>[\s]*?,[\s]*?LOCATION[\s]*?=[\s]*?USER_DB)[\s]*?\)"
    $patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?CLUSTERED[\s]+COLUMNSTORE[\s]+INDEX[\s]*?,[\s]*?DISTRIBUTION[\s]*?=[\s]*(?<replicate>REPLICATE)[\s]*?\)"

    $patterns += "[\s]*CREATE[\s]+TABLE[\s]+#[\S]+[\s]+WITH[\s]*\([\s]*CLUSTERED[\s]+COLUMNSTORE[\s]+INDEX[\s]*(?<location>[\s]*,[\s]*?LOCATION[\s]*=[\s]*USER_DB)[\s]*,[\s]*?DISTRIBUTION[\s]*=[\s]*(?<replicate>REPLICATE)[\s]*\)"
    $patterns += "[\s]*CREATE[\s]+TABLE[\s]+#[\S]+[\s]+WITH[\s]*\([\s]*HEAP[\s]*(?<location>[\s]*,[\s]*?LOCATION[\s]*=[\s]*USER_DB)[\s]*,[\s]*?DISTRIBUTION[\s]*=[\s]*(?<replicate>REPLICATE)[\s]*\)"


    $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant'

    foreach ($pattern in $patterns){
        $matches = [regex]::Matches($query, $pattern, $regexOptions)

        foreach ($match in $matches)
        {            
            $oldValue = $match.Groups[0].Value
            $newValue = $oldValue.Replace($match.Groups["replicate"].Value,"ROUND_ROBIN")
            if ($match.Groups["location"].Success)
            {
                $newValue = $newValue.Replace($match.Groups["location"].Value, "")
            }
            $query = $query.Replace($oldValue, $newValue)
        }
    }


    $patterns = @()
    $patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?HEAP[\s]*?(?<location>[\s]*?,[\s]*?LOCATION[\s]*?=[\s]*?USER_DB)[\s]*?\)"
    $patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?CLUSTERED[\s]+COLUMNSTORE[\s]+INDEX[\s]*?(?<location>[\s]*?,[\s]*?LOCATION[\s]*?=[\s]*?USER_DB)[\s]*?\)"
    #$patterns += "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]*?\([\s]*?.*?([\s]*?,[\s]*?LOCATION[\s]*?=[\s]*?USER_DB)[\s]*?\)"

    foreach ($pattern in $patterns){
        $matches = [regex]::Matches($query, $pattern, $regexOptions)
        foreach ($match in $matches)
        {
            $oldValue = $match.Groups[0].Value
            if ($match.Groups["location"].Success)
            {
                $newValue = $oldValue.Replace($match.Groups["location"].Value, "")
                $query = $query.Replace($oldValue, $newValue)
            }
        }
    }

    return $query
}

##########################################################################################################




########################################################################################
#
# Main Program Starts here
#
########################################################################################

$ProgramStartTime = (Get-Date)

$ScriptPath = $PSScriptRoot

$defaultConfigFileName = "cs_dirs.csv"
$configFileName = Read-Host -prompt "Enter the name of the Config file name file. Press [Enter] if it is [$($defaultConfigFileName)]"
if($configFileName -eq "" -or $configFileName -eq $null)
	{$configFileName = $defaultconfigFileName}

$defaultSchemasFileName = "schemas.csv"
$schemasFileName = Read-Host -prompt "Please enter the name of your Schema Mapping file. Press [Enter] if it is [$($defaultSchemasFileName)]"
if($schemasFileName -eq "" -or $schemasFileName -eq $null)
	{$schemasFileName = $defaultSchemasFileName}

$defaultUseThreePartNames = "Yes"
$useThreePartNamesPrompt = Read-Host -prompt "Do you want to use 3-part names - Yes or No? Press [Enter] if it is [$($defaultUseThreePartNames)]"
if($useThreePartNamesPrompt -eq "" -or $useThreePartNamesPrompt -eq $null) {
    $useThreePartNamesPrompt = $defaultUseThreePartNames 
} 
if ( ($useThreePartNamesPrompt.ToUpper() -eq "YES") -or ($useThreePartNamesPrompt.ToUpper() -eq "Y") ) {
	$useThreePartNames = $true
} else {
    $useThreePartNames = $false
}

$defaultAddMissingSchemas = "Yes"
$addMissingSchemasPrompt = Read-Host -prompt "Do you want to add missing schemas - Yes or No? Press [Enter] if it is [$($defaultAddMissingSchemas)]"
if($addMissingSchemasPrompt -eq "" -or $addMissingSchemasPrompt -eq $null) {
    $addMissingSchemasPrompt = $defaultAddMissingSchemas 
} 
if ( ($addMissingSchemasPrompt.ToUpper() -eq "YES") -or ($addMissingSchemasPrompt.ToUpper() -eq "Y") ) {
	$addMissingSchemas = $true
} else {
    $addMissingSchemas = $false
}



$configFilePath = Join-Path -Path $ScriptPath -ChildPath $configFileName
if (!(Test-Path $configFilePath )) {
    Write-Host "Could not find Config file: $configFilePath " -ForegroundColor Red
    break 
}

$schemasFilePath = Join-Path -Path $ScriptPath -ChildPath $schemasFileName
if (!(Test-Path $schemasFilePath )) {
    Write-Host "Could not find Schemas Mapping file: $schemasFilePath " -ForegroundColor Red
    break 
}

$configCsvFile = Import-Csv $configFilePath 
$schemaCsvFile = Import-Csv $schemasFilePath
 

foreach ($configRow in $configCsvFile) 
{
    if ($configRow.Active -eq '1') 
	{
        $databaseName = $configRow.SourceDatabaseName  
        $sourceDir = $configRow.SourceDirectory
        $targetDir = $configRow.TargetDirectory
        $defaultSchema = $configRow.DefaultSchema
        
        if (!(Test-Path -Path $sourceDir)) {
            continue
        }

        foreach ($file in Get-ChildItem -Path $sourceDir -Filter *.sql)
        {
            $sourceFilePath = $file.FullName
            $targetFilePath = Join-Path -Path $targetDir -ChildPath $file.Name
            (Get-Date -Format HH:mm:ss.fff)+" - "+$targetFilePath | Write-Host -ForegroundColor Yellow
            $content = Get-Content -Path $SourceFilePath -Raw

            $newContent = $content
            $newContent = FixTempTables -Query $newContent
            if ($addMissingSchemas) {
                $newContent = AddMissingSchemas -Query $newContent -defaultSchema $defaultSchema
            }
            $newContent = ChangeSchemas -DatabaseName $databaseName -SchemaMappings $schemaCsvFile -query $newContent -defaultSchema $defaultSchema -useThreePartNames $useThreePartNames

            $targetFolder = [IO.Path]::GetDirectoryName($targetFilePath)
            if (!(Test-Path $targetFolder))
            {
	            New-item -Path $targetFolder -ItemType Dir | Out-Null
            }

            $newContent | Out-File $targetFilePath
        }
	}
}


$ProgramFinishTime = (Get-Date)

$progDuration = GetDurations  -StartTime  $ProgramStartTime -FinishTime $ProgramFinishTime
$progDurationText = $progDuration.DurationText

Write-Host "Total time mapping schemas in DDL scripts: $progDurationText " -ForegroundColor Magenta -BackgroundColor Black
