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
#       Updates object names in SQL queries according to schema mappings (APS-->Synapse)
#        
# TODO:
#    1. CTE expression aliases are processed incorrectly
# =================================================================================================================================================
# 
# Authors: Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\2_ConvertDDLScripts\FixSchemas.ps1


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


function ChangeSchemas($DatabaseName, $SchemaMappings, $DefaultSchema, $query)
{
    $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant, Multiline'

    foreach ($schemaMapping in $SchemaMappings)
    {
        if ($schemaMapping.SynapseSchema.Contains(" ")) {
            $newSchema = "[" + $schemaMapping.SynapseSchema + "]"
        } else {
            $newSchema = $schemaMapping.SynapseSchema
        }

        $newPat = '${prefix}' + $newSchema + '.'                                                                                 # ==> [SQLDWSchema].

        if ($schemaMapping.ApsSchema -eq $DefaultSchema)
        {
            $oldPat = "(?<prefix>^|[\s]+)(?<objectname>" + $schemaMapping.ApsDbName + "\.\.)"                                    # apsDbName.. 
            $query = $query -replace $oldPat, $newPat

            $oldPat = "(?<prefix>^|[\s]+)(?<objectname>\[" + $schemaMapping.ApsDbName + "\]\.\.)"                                # [apsDbName].. 
            $query = $query -replace $oldPat, $newPat
        }

        $oldPat = "(?<prefix>^|[\s]+)(?<objectname>\[" + $schemaMapping.ApsDbName + "\]\.\[" + $schemaMapping.ApsSchema + "\]\.)"# [apsDbName].[apsSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "(?<prefix>^|[\s]+)(?<objectname>" + $schemaMapping.ApsDbName + "\.\[" + $schemaMapping.ApsSchema + "\]\.)"    # apsDbName.[apsSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "(?<prefix>^|[\s]+)(?<objectname>\[" + $schemaMapping.ApsDbName + "\]\." + $schemaMapping.ApsSchema + "\.)"    # [apsDbName].apsSchema. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "(?<prefix>^|[\s]+)(?<objectname>" + $schemaMapping.ApsDbName + "\." + $schemaMapping.ApsSchema + "\.)"        # apsDbName.apsSchema. 
        $query = $query -replace $oldPat, $newPat


        # This is for OBJECT_ID('schema.table') scenarios
        $newPat = '''' + $newSchema + '.'                                                                                       # ==> '[SQLDWSchema
        $oldPat = "'(?<objectname>\[" + $schemaMapping.ApsDbName + "\]\.\[" + $schemaMapping.ApsSchema + "\]\.)"                # '[apsDbName].[apsSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "'(?<objectname>"+$schemaMapping.ApsDbName + "\.\[" + $schemaMapping.ApsSchema + "\]\.)"                      # 'apsDbName.[apsSchema]. 
        $query = $query -replace $oldPat, $newPat

        $newPat = '''' + $newSchema + '.'                                                                       # ==> '[SQLDWSchema
        $oldPat = "'(?<objectname>\[" + $schemaMapping.ApsDbName + "\]\." + $schemaMapping.ApsSchema + "\.)"                    # '[apsDbName].apsSchema. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = "'(?<objectname>"+$schemaMapping.ApsDbName + "\." + $schemaMapping.ApsSchema + "\.)"                          # 'apsDbName.apsSchema. 
        $query = $query -replace $oldPat, $newPat


        if ($schemaMapping.ApsDbName -eq $DatabaseName)
        {
            $newPat = '''' + $newSchema + '.'                                                                                   # ==> '[SQLDWSchema].
            $oldPat = "'(?<objectname>\[" + $schemaMapping.ApsSchema + "\]\.)"                                  # OBJECT_ID('[apsSchema]. 
            $query = $query -replace $oldPat, $newPat

            $newPat = '''' + $newSchema + '.'                                                                      # ==> '[SQLDWSchema].
            $oldPat = "'(?<objectname>"+$schemaMapping.ApsSchema + "\.)"                                        # OBJECT_ID('apsSchema.
            $query = $query -replace $oldPat, $newPat


            $newPat = '${prefix}' + $newSchema + '.'                                                                      # ==> [SQLDWSchema].
            $oldPat = "(?<prefix>^|[\s]+)(?<objectname>\[" + $schemaMapping.ApsSchema + "\]\.)"                                  # [apsSchema]. 
            $query = $query -replace $oldPat, $newPat

            $newPat = '${prefix}' + $newSchema + '.'                                                                      # ==> [SQLDWSchema].
            $oldPat = "(?<prefix>^|[\s]+)(?<objectname>"+$schemaMapping.ApsSchema + "\.)"                                       # apsSchema.
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


#AddMissingSchemas -query "    FROM DimAccount AS r  " -defaultSchema "dbo" | Write-Output
#AddMissingSchemas -query "    FROM DimAccount" -defaultSchema "dbo" | Write-Output
#AddMissingSchemas -query "    FROM [DimAccount-123] AS r  " -defaultSchema "dbo" | Write-Output

#AddMissingSchemas -query "CREATE VIEW [v_l_cube] AS select" -defaultSchema "dbo" | Write-Output

#$query = "        --at least one table must be present for join
#        stg.WHERE COALESCE([glo].[PRODUCT_INITIAL_KEY], [def].[PRODUCT_INITIAL_KEY], [oth].[PRODUCT_INITIAL_KEY], [ex].[PRODUCT_INITIAL_KEY]) IS NOT NULL"
#$query = "select c1 from Table"

$query = "	option(label='DW.Price.Ssis.InternalFacts.DimMaster(SI_F_INTERNALPRICE_TempTable_Prepare_Temp)');
 
DECLARE @ChangeDate date

SET @ChangeDate = (select distinct upsert_date from SI_F_HOTEL_CONTRACT_COST_AND_ALLOTMENT_Mart_Prepare
	                            WHERE CONTRACTID = @CONTRACTID)
--Create the SI_F_HOTEL_CONTRACT_COST_AND_ALLOTMENT_TempTable  table
	if exists( select name from sys.tables where name = 'SI_F_HOTEL_CONTRACT_COST_AND_ALLOTMENT_Mart_TempTable')
		drop Table SI_F_HOTEL_CONTRACT_COST_AND_ALLOTMENT_Mart_TempTable; 

	CREATE TABLE SI_F_HOTEL_CONTRACT_COST_AND_ALLOTMENT_Mart_TempTable 
	WITH (DISTRIBUTION = REPLICATE) AS
	SELECT    @ChangeDate as Changedate, -- (förändrings datum)
			  1 AS ActStatus,
			  CONTRACTID,
STAYDATE, 

"
$query = "
CREATE TABLE F_BOOKING_MESSAGE_TEMP
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH([BOOKSEQNO]))
AS SELECT * FROM F_BOOKING_MESSAGE
WHERE BOOKSEQNO IN (SELECT DISTINCT BOOKSEQNO FROM SI_F_BOOKING_MESSAGE_LINK)
OPTION(label='_DW.CustomerService.Ssis.PCM2DW.FactMaster(F_BOOKING_MESSAGE_LINK_ST)');
"

#AddMissingSchemas -query $query -defaultSchema "dbo" | Write-Output
