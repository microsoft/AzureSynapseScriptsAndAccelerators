#
# FixSchemas.ps1
#
# FileName: FixSchemas.ps1
# =================================================================================================================================================
# 
# Change log:
# Created:    Nov 30, 2020
# Author:     Andrey Mirskiy
# Company:    Microsoft
# 
# =================================================================================================================================================
# Description:
#       Updates object names in SQL queries according to schema mappings (APS-->SQLDW)
#
# =================================================================================================================================================
# TODO:
#    1. CTE expression aliases are processed incorrectly
#
#
# =================================================================================================================================================

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
