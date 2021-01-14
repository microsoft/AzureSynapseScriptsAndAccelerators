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


##########################################################################################################

function AddMissingSchemas($query, $defaultSchema)
{
    $patterns = @()

    #$patterns += "[\s]*FROM[\s]+([^\s\.#]+?)([\s]+|[\s]*\r?$)"
    #$patterns += "[\s]*JOIN[\s]+([^\s\.#]+?)([\s]+|[\s]*\r?$)"
    # single object name per line, e.g. stored procedure
    #$patterns += "^()([^\s\.#-]+?)$"

    # Object name without []
    #????$patterns += "[\s]*(FROM|JOIN|EXEC|EXECUTE)([\s]+)([^\s\.#\(\)\-[]]+?)([\s]+|[\s]*\r?$)"
    $patterns += "[\s]*(FROM|JOIN|EXEC|EXECUTE)([\s]+)([^\s\.#\(\)\-\[\]]+?)([\s]+|[\s]*\r?$)"
    # Object name with []
    $patterns += "[\s]*(FROM|JOIN|EXEC|EXECUTE)([\s]+)(\[[^\.#\(\)]+?\])([\s]+|[\s]*\r?$)"

    # Object name without []
    $patterns += "[\s]*(CREATE|ALTER|DROP)[\s]+(TABLE|VIEW|PROC|PROCEDURE|FUNCTION)[\s]+([^\s\.]+?)([\s]+|[\s]*\r?$)" #AS[\s]+"
    $patterns += "[\s]*(TRUNCATE)[\s]+(TABLE)[\s]+([^\s\.]+?)([\s]+|[\s]*\r?$)"
    # Object name with []
    $patterns += "[\s]*(CREATE|ALTER|DROP)[\s]+(TABLE|VIEW|PROC|PROCEDURE|FUNCTION)[\s]+(\[[^\.]+?\])([\s]+|[\s]*\r?$)" #AS[\s]+"
    $patterns += "[\s]*(TRUNCATE)[\s]+(TABLE)[\s]+(\[[^\.]+?\])([\s]+|[\s]*\r?$)"

    foreach ($pattern in $patterns)
    {
        $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant, Multiline'
        $matches = [regex]::Matches($query, $pattern, $regexOptions)

        foreach ($match in $matches)
        {
            if ($match.Groups.Count -lt 4)
            {
                # Didn't find an object name
                continue
            }

            $oldValue = $match.Groups[0].Value
            $oldObjectName = $match.Groups[3].Value
            $newObjectName = "[" + $defaultSchema + "]." + $oldObjectName
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
    foreach ($schemaMapping in $SchemaMappings)
    {
        $newPat = "[" + $schemaMapping.SQLDWSchema + "]."                                                    # ==> [SQLDWSchema].

        if ($schemaMapping.ApsSchema -eq $DefaultSchema)
        {
            $oldPat = [Regex]::Escape($schemaMapping.ApsDbName + "..")                                      # apsDbName.. 
            $query = $query -replace $oldPat, $newPat
            $oldPat = [Regex]::Escape("[" + $schemaMapping.ApsDbName + "]..")                                # [apsDbName].. 
            $query = $query -replace $oldPat, $newPat
        }

        $oldPat = [Regex]::Escape("[" + $schemaMapping.ApsDbName + "].[" + $schemaMapping.ApsSchema + "].")  # [apsDbName].[apsSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = [Regex]::Escape($schemaMapping.ApsDbName + ".[" + $schemaMapping.ApsSchema + "].")         # apsDbName.[apsSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = [Regex]::Escape("[" + $schemaMapping.ApsDbName + "]." + $schemaMapping.ApsSchema + ".")    # [apsDbName].apsSchema. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = [Regex]::Escape($schemaMapping.ApsDbName + "." + $schemaMapping.ApsSchema + ".")           # apsDbName.apsSchema. 
        $query = $query -replace $oldPat, $newPat

        # This is for OBJECT_ID('schema.table') scenarios
        $newPat = "'[" + $schemaMapping.SQLDWSchema + "]."                                                    # ==> [SQLDWSchema].

        $oldPat = [Regex]::Escape("'[" + $schemaMapping.ApsDbName + "].[" + $schemaMapping.ApsSchema + "].")  # [apsDbName].[apsSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = [Regex]::Escape("'"+$schemaMapping.ApsDbName + ".[" + $schemaMapping.ApsSchema + "].")      # apsDbName.[apsSchema]. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = [Regex]::Escape("'[" + $schemaMapping.ApsDbName + "]." + $schemaMapping.ApsSchema + ".")    # [apsDbName].apsSchema. 
        $query = $query -replace $oldPat, $newPat
        $oldPat = [Regex]::Escape("'"+$schemaMapping.ApsDbName + "." + $schemaMapping.ApsSchema + ".")        # apsDbName.apsSchema. 
        $query = $query -replace $oldPat, $newPat


        if ($schemaMapping.ApsDbName -eq $DatabaseName)
        {
            $newPat = "[" + $schemaMapping.SQLDWSchema + "]."                                                 # ==> [SQLDWSchema].

            $oldPat = [Regex]::Escape("[" + $schemaMapping.ApsSchema + "].")                                  # [apsSchema]. 
            $query = $query -replace $oldPat, $newPat
            $oldPat = "'"+[Regex]::Escape($schemaMapping.ApsSchema + ".")                                     # apsSchema.
            $query = $query -replace $oldPat, $newPat

            $newPat = " [" + $schemaMapping.SQLDWSchema + "]."                                                # ==> [SQLDWSchema].

            $oldPat = "\s"+[Regex]::Escape("[" + $schemaMapping.ApsSchema + "].")                             # [apsSchema]. 
            $query = $query -replace $oldPat, $newPat
            $oldPat = "\s"+[Regex]::Escape($schemaMapping.ApsSchema + ".")                                    # apsSchema.
            $query = $query -replace $oldPat, $newPat
        }
    }

	return $query
}

##########################################################################################################

function FixTempTables($query)
{
    $pattern1 = "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]?\([\s]*?DISTRIBUTION[\s]*?=[\s]*(REPLICATE)([\s]*?,[\s]*?LOCATION[\s]*?=[\s]*?USER_DB)[\s]*?\)"
    $pattern2 = "[\s]*CREATE[\s]+?TABLE[\s]+?#[\S]+?[\s]+?WITH[\s]*?\([\s]*?.*?([\s]*?,[\s]*?LOCATION[\s]*?=[\s]*?USER_DB)[\s]*?\)"

    $regexOptions = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant'

    $matches = [regex]::Matches($query, $pattern1, $regexOptions)

    foreach ($match in $matches)
    {
        $oldValue = $match.Groups[0].Value
        $newValue = $oldValue.Replace("REPLICATE","ROUND_ROBIN")
        $newValue = $newValue.Replace($match.Groups[2].Value, "")
        $query = $query.Replace($oldValue, $newValue)
    }

    $matches = [regex]::Matches($query, $pattern2, $regexOptions)
    foreach ($match in $matches)
    {
        $oldValue = $match.Groups[0].Value
        $newValue = $oldValue.Replace($match.Groups[1].Value, "")
        $query = $content.Replace($oldValue, $newValue)
    }

    return $query
}

##########################################################################################################


#AddMissingSchemas -query "    FROM DimAccount AS r  " -defaultSchema "dbo" | Write-Output
#AddMissingSchemas -query "    FROM DimAccount" -defaultSchema "dbo" | Write-Output
#AddMissingSchemas -query "    FROM [DimAccount-123] AS r  " -defaultSchema "dbo" | Write-Output