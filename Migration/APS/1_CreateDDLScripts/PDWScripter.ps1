# =================================================================================================================================================
# Scriptname: PDWScripter.ps1
# 
# Created: December, 2020
# Authors: Andrey Mirskiy
# Company: Microsoft 
# 
# =================================================================================================================================================
# Description:
#       Scripts PDW/APS objects
#
# ===============================================================================================================================================


#==================================================================================================

function GetDistributionPolicy($Connection, $TableName)
{
    $sqlCommandText = "select tdp.distribution_policy `
        from sys.tables so left join sys.external_tables et on so.object_id = et.object_id `
        join sys.pdw_table_distribution_properties AS tdp ON so.object_id = tdp.object_id `
        where et.name is NULL and so.type = 'U' `
            and so.object_id = object_id('{TableName}') `
        order by so.name" 

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $TableName)
    $distributionPolicy = $cmd.ExecuteScalar()
    $cmd.Dispose()

    return $distributionPolicy
}


#==================================================================================================

function GetColumns($Connection, $TableName)
{
    $sqlCommandText = "select c.column_id, c.name, t.name as type, c.max_length, c.precision, `
        c.scale, c.is_nullable, d.distribution_ordinal, c.collation_name, ISNULL('DEFAULT '+dc.definition,'') as default_constraint `
        from sys.columns c `
            join sys.pdw_column_distribution_properties d on c.object_id = d.object_id and c.column_id = d.column_id `
            join sys.types t on t.user_type_id = c.user_type_id `
            left join sys.default_constraints dc on c.default_object_id =dc.object_id and c.object_id =dc.parent_object_id `
        where c.object_id = object_id('{TableName}') `
        order by Column_Id " 

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $TableName)
    $reader = $cmd.ExecuteReader()

    $columns = @()
    while($reader.Read())
    {
        $column_id = $reader["column_id"].ToString()    
        $name = $reader["name"].ToString()  
        $type = $reader["type"].ToString()  
        $max_length = $reader["max_length"].ToString()  
        $precision = $reader["precision"].ToString()  
        $scale = $reader["scale"].ToString()  
        $is_nullable = $reader["is_nullable"].ToString()  
        $distribution_ordinal = $reader["distribution_ordinal"].ToString()  
        $collation_name = $reader["collation_name"].ToString()  
        $default_constraint  = $reader["default_constraint"].ToString()  
        $columns += New-Object psObject -Property @{ `
                'column_id'=$column_id; `
                'name'=$name; `
                'type'=$type; `
                'max_length'=$max_length; `
                'precision'=$precision; `
                'scale'=$scale; `
                'is_nullable'=$is_nullable; `
                'distribution_ordinal'=$distribution_ordinal; `
                'collation_name'=$collation_name; `
                'default_constraint'=$default_constraint; `
        }
    }  
    $reader.Close()
    $cmd.Dispose()

    return $columns
}


#==================================================================================================

function GetClusteredClause($Connection, $TableName)
{
    $sqlCommandText = "select i.key_ordinal, c.name, i.is_descending_key, si.[type] as index_type ,si.name as indexname `
        from sys.indexes si `
            left join sys.index_columns i on i.object_id = si.object_id `
            left join sys.columns c on c.column_id = i.column_id and c.object_id = i.object_id `
        where i.index_id = 1 and si.[type] <> 2 `
            and i.object_id = object_id('{TableName}') `
            and i.partition_ordinal = 0 `
        order by key_ordinal" 

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $TableName)
    $reader = $cmd.ExecuteReader()

    $clusteredClause = ""

    $columns = @()
    while($reader.Read())
    {
        $index_type = $reader["index_type"]
        $key_ordinal = $reader["key_ordinal"]
        $is_descending_key = $reader["is_descending_key"]
        $name = $reader["name"]

        if ($index_type -eq 5)
        {
            $clusteredClause = "CLUSTERED COLUMNSTORE INDEX"
            break
        }

        if ($index_type -eq 1)
        {
            if ($key_ordinal -eq 1) {
                $clusteredClause += "CLUSTERED INDEX ("
            } else {
                $clusteredClause += ", "
            }
            $clusteredClause += "[" + $name + "]"
            if ($is_descending_key -eq 1) {
                $clusteredClause += " DESC"
            } else {
                $clusteredClause += " ASC"
            }
        }
    } 
    $reader.Close()
    $cmd.Dispose()

    if ($index_type -eq 1) {
        $clusteredClause += ")"
    }

    if ($clusteredClause -eq "")
    {
        $clusteredClause = "HEAP"
    }

    return $clusteredClause
}


#==================================================================================================

function GetNonclusteredClause($Connection, $TableName)
{
    $sqlCommandText = "select ix.name as index_name, i.key_ordinal, c.name, i.is_descending_key, ix.index_id-1 as index_id `
        from sys.index_columns i `
            join sys.indexes ix on ix.index_id = i.index_id and ix.object_id = i.object_id `
            join sys.columns c on c.column_id = i.column_id  and c.object_id = ix.object_id `
        where i.key_ordinal > 0 `
            and i.object_id = object_id('{TableName}') `
            and i.index_id > 1 -- NonClustered Indexes `
        order by ix.name, key_ordinal" 

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $TableName)
    $reader = $cmd.ExecuteReader()

    $nonclusteredClause = ""
    $indexCount = 0
    $currIndexName = ""

    $columns = @()
    while($reader.Read())
    {
        $index_name = $reader["index_name"]
        $key_ordinal = $reader["key_ordinal"]
        $name = $reader["name"]
        $is_descending_key = $reader["is_descending_key"]
        $index_id = $reader["index_id"]
        $column_definition = "[" + $name + "]"
        if ($is_descending_key -eq 1) {
            $column_definition += " DESC"
        } else {
            $column_definition += " ASC"
        }

        $indexCount = $index_id

        $columns += New-Object psObject -Property @{ `
                'index_name'=$index_name; `
                'key_ordinal'=$key_ordinal; `
                'name'=$name; `
                'is_descending_key'=$is_descending_key; `
                'index_id'=$index_id; `
                'column_definition'=$column_definition; `
            }
    }
    $reader.Close()
    $cmd.Dispose()

    $indexes = @()
    for ($i=1; $i -le $indexCount; $i++)
    {
        $indexName = $columns | Where index_id -eq $i | Select -First 1 -ExpandProperty index_name 
        $columnsList = ($columns | Where index_id -eq $i | Select -ExpandProperty column_definition) -join ", "
        $idxTemplate = "CREATE INDEX [$indexName] `r`n`tON [" + $TableName.Replace(".","].[") + "] ($columnsList)"
        #$indexDefinition = $idxTemplate -f $indexName, $columnsList
        
        $indexes += $indexDefinition
    }
    
    $nonclusteredClause = $indexes -join "`r`n`r`n"

    return $nonclusteredClause
}


#==================================================================================================

function GetPartitionClause($Connection, $TableName)
{
    $partitionClause = ""

    $sqlCommandText = "select c.name `
        from sys.tables t `
            join sys.indexes i on(i.object_id = t.object_id and i.index_id < 2) `
            join sys.index_columns  ic on(ic.partition_ordinal > 0 and ic.index_id = i.index_id and ic.object_id = t.object_id) `
            join sys.columns c on(c.object_id = ic.object_id and c.column_id = ic.column_id) `
        where t.object_id = object_id('{TableName}') " 

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $TableName)
    $partitionColumn = $cmd.ExecuteScalar()
    $cmd.Dispose()

    if ($partitionColumn -eq "" -or $partitionColumn -eq $null) {
        return $partitionClause
    } else {
        $partitionClause += "PARTITION ([" + $partitionColumn + "] RANGE "
    }

    $sqlCommandText = "select pf.boundary_value_on_right from sys.partition_functions pf `
            join sys.partition_schemes ps on pf.function_id=ps.function_id `
            join sys.data_spaces ds on ps.data_space_id = ds.data_space_id `
            join sys.indexes si on si.data_space_id = ds.data_space_id `
        where si.object_id = object_id('{TableName}') " 

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $TableName)
    $partitionAlignment = $cmd.ExecuteScalar()
    $cmd.Dispose()

    if ($partitionAlignment -eq $false) {
        $partitionClause += "LEFT FOR VALUES ("
    } else {
        $partitionClause += "RIGHT FOR VALUES ("
    }


    $sqlCommandText = "select cast(sp.partition_number as int) as partition_number , prv.value as boundary_value, lower(sty.name) as boundary_value_type `
        from sys.tables st join sys.indexes si on st.object_id = si.object_id and si.index_id <2 `
            join sys.partitions sp on sp.object_id = st.object_id and sp.index_id = si.index_id `
            join sys.partition_schemes ps on ps.data_space_id = si.data_space_id `
            join sys.partition_range_values prv on prv.function_id = ps.function_id `
            join sys.partition_parameters pp on pp.function_id = ps.function_id `
            join sys.types sty on sty.user_type_id = pp.user_type_id and prv.boundary_id = sp.partition_number `
        where st.object_id = object_id('{TableName}') `
        order by sp.partition_number " 

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $TableName)
    $reader = $cmd.ExecuteReader()

    $boundaries = @()
    while($reader.Read())
    {
        $partition_number = $reader["partition_number"]
        $boundary_value = $reader["boundary_value"]
        $boundary_value_type = $reader["boundary_value_type"]

        $boundaries += New-Object PSObject -Property @{ `
                'partition_number'=$partition_number; `
                'boundary_value'=$boundary_value; `
                'boundary_value_type'=$boundary_value_type; `
            }
    }
    $reader.Close()
    $cmd.Dispose()


    $boundary_value_type = $boundaries | Where partition_number -eq 1 | Select -First 1 -ExpandProperty boundary_value_type 

    if ($boundary_value_type -in ("int", "smallint", "bigint", "tinyint")) {
        $boundaryText = @{label="boundaryText";expression={$_.boundary_value.ToString()}}
    }
    elseif ($boundary_value_type -in ("char", "varchar")) {
        $boundaryText = @{label="boundaryText";expression={"'"+$_.boundary_value.ToString()+"'"}}
    }
    elseif ($boundary_value_type -in ("nchar", "nvarchar")) {
        $boundaryText = @{label="boundaryText";expression={"N'"+$_.boundary_value.ToString()+"'"}}
    }
    elseif ($boundary_value_type -in ("date")) {
        $boundaryText = @{label="boundaryText";expression={"'"+$_.boundary_value.ToString("yyyyMMdd")+"'"}}
    }
    elseif ($boundary_value_type -in ("time")) {
        $boundaryText = @{label="boundaryText";expression={"'"+$_.boundary_value.ToString("HH:mm:ss")+"'"}}
    }
    elseif ($boundary_value_type -in ("datetime", "datetime2", "smalldatetime")) {
        $boundaryText = @{label="boundaryText";expression={"'"+$_.boundary_value.ToString("yyyyMMdd HH:mm:ss")+"'"}}
    }

    $partitionClause += ($boundaries | Select $boundaryText | Select -ExpandProperty boundaryText) -join ", "
    $partitionClause += "))"
    return $partitionClause
}

#==================================================================================================

function GetColumnsClause($Columns)
{
    $columnsText = ""

    foreach ($column in $Columns) 
    {
        if ($columnsText -ne "") {
            $columnsText += ",`r`n"
        }

        $columnsText += "`t[" + $column.name + "] " + $column.type
        if ($column.type -in ("bigint", "bit", "date", "datetime", "int", "smalldatetime", "smallint", "smallmoney", "money", "tinyint", "real", "uniqueidentifier")) {
            # no extra processing needed
        }
        elseif ($column.type -in ("binary", "varbinary")) {
            if ($column.max_length -eq -1) {
                $maxLength = "max"
            }
            else {
                $maxLength = $column.max_length
            }
            $columnsText += "(" + $maxLength + ")"
        }
        elseif ($column.type -in ("char", "varchar", "nchar", "nvarchar")) {
            if ($column.max_length -eq -1) {
                $maxLength = "max"
            }
            elseif ($column.type -in ("nchar", "nvarchar")) {
                $maxLength = $column.max_length / 2
            } 
            else {
                $maxLength = $column.max_length
            }
            $columnsText += "(" + $maxLength + ") COLLATE "+$column.collation_name
        }
        elseif ($column.type -in ("float")) {
            $columnsText += "(" + $column.precision + ")"
        }
        elseif ($column.type -in ("datetime2", "datetimeoffset", "time")) {
            $columnsText += "(" + $column.scale + ")"
        }
        elseif ($column.type -in ("decimal", "numeric")) {
            $columnsText += "(" + $column.precision + "," + $column.scale + ")"
        }
        else {
            throw "Unsupported data type"
        }


        if ($column.is_nullable -eq "False") {
            $columnsText += " NOT NULL"
        } else {
            $columnsText += " NULL"
        }

        $columnsText += $column.default_constraint

    }


    return $columnsText
}

#==================================================================================================

function ScriptSqlModule($Connection, $ObjectName)
{
    $sqlViewDefinition = "select T1.definition `
        from sys.sql_modules T1 `
	        join sys.objects T2 on T1.object_id=T2.object_id `
	        join sys.schemas T3 on T2.schema_id=T3.schema_id `
        where T1.object_id = object_id('{objectname}')"

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $conn
    $cmd.CommandText = $sqlViewDefinition.Replace("{objectname}", $ObjectName)
    $DDL = $cmd.ExecuteScalar()
    $cmd.Dispose()

    return $DDL
}

#==================================================================================================

function ScriptIndex($Connection, $ObjectName)
{
    $nameParts = $ObjectName.Split(".")
    $schemaName = $nameParts[0]
    $tableName = $nameParts[1]
    $indexName = $nameParts[2]
    $DDL = "CREATE NONCLUSTERED INDEX [" + $indexName + "]`r`nON [$schemaName].[$tableName] ("

    $sqlCommandText = "select idxcol.*, col.name as column_name, idx.name as index_name, case when is_descending_key=0 then 'ASC' else 'DESC' end as ascdesc
        from sys.indexes idx 
	        inner join sys.index_columns idxcol on idx.object_id=idxcol.object_id and idx.type_desc = 'NONCLUSTERED'
	        inner join sys.columns col on idx.object_id=col.object_id and idxcol.column_id=col.column_id
		        and idx.index_id=idxcol.index_id
        where idx.object_id=object_id('{TableName}') and idx.name='{IndexName}'
        order by idxcol.key_ordinal ASC"


    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $schemaName+"."+$TableName).Replace("{IndexName}", $indexName)
    $reader = $cmd.ExecuteReader()

    $columns = @()
    while($reader.Read())
    {
        $column_name = $reader["column_name"]
        $ascdesc = $reader["ascdesc"]
        $key_ordinal = $reader["key_ordinal"]
        $is_descending_key = $reader["is_descending_key"]

        $columns += New-Object PSObject -Property @{ `
                'column_name'=$column_name; `
                'ascdesc'=$ascdesc; `
                'key_ordinal'=$key_ordinal; `
                'is_descending_key'=$is_descending_key; `
            }
    }
    $reader.Close()
    $cmd.Dispose()

    $columnText = @{label="columnText";expression={$_.column_name+" "+$_.ascdesc}}
    $DDL += ($columns | Select $columnText | Select -ExpandProperty columnText) -join ", "
    $DDL += ")"

    return $DDL
}

#==================================================================================================

function ScriptStatistic($Connection, $ObjectName)
{
    $nameParts = $ObjectName.Split(".")
    $schemaName = $nameParts[0]
    $tableName = $nameParts[1]
    $statName = $nameParts[2]
    $DDL = "CREATE STATISTICS [" + $statName + "] ON [$schemaName].[$tableName] ("

    $sqlCommandText = "select stat.filter_definition
        from sys.objects o
	        inner join sys.schemas s on o.schema_id = s.schema_id
	        inner join sys.stats stat on stat.object_id = o.object_id and stat.user_created = 1
        where o.object_id=object_id('{TableName}') and stat.name='{StatName}'"

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $conn
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $schemaName+"."+$TableName).Replace("{StatName}", $statName)
    $filterDefinition = $cmd.ExecuteScalar()
    $cmd.Dispose()


    $sqlCommandText = "select stat.name, col.name as column_name
        from sys.objects o
	        inner join sys.schemas s on o.schema_id = s.schema_id
	        inner join sys.databases d on d.name = db_name()  and o.type_desc = 'USER_TABLE'
	        inner join sys.stats stat on stat.object_id = o.object_id and stat.user_created = 1
	        inner join sys.stats_columns statcol on statcol.object_id = o.object_id and stat.stats_id = statcol.stats_id
	        inner join sys.columns col on col.object_id = o.object_id and col.column_id = statcol.column_id
        where o.object_id=object_id('{TableName}') and stat.name='{StatName}'
        order by statcol.stats_column_id"


    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $connection
    $cmd.CommandText = $sqlCommandText.Replace("{TableName}", $schemaName+"."+$TableName).Replace("{StatName}", $statName)
    $reader = $cmd.ExecuteReader()

    $columns = @()
    while($reader.Read())
    {
        $column_name = $reader["column_name"]

        $columns += New-Object PSObject -Property @{ `
                'column_name'=$column_name; `
            }
    }
    $reader.Close()
    $cmd.Dispose()

    $DDL += ($columns | Select -ExpandProperty column_name) -join ", "
    $DDL += ")"

    if ([String]::IsNullOrEmpty($filterDefinition) -ne $true) {
        $DDL += "`r`nWHERE " + $filterDefinition
    }

    return $DDL
}

#==================================================================================================

function ScriptRole($Connection, $ObjectName)
{
    $DDL = "CREATE ROLE [" + $ObjectName + "]"
    #+= "AUTHORIZATION ???"

    return $DDL
}

#==================================================================================================

function ScriptUser($Connection, $ObjectName)
{
    $DDL = "CREATE USER [" + $ObjectName + "] WITHOUT LOGIN"

    return $DDL
}

#==================================================================================================

function ScriptTable($Connection, $ObjectName)
{
    $tableName = "[" + $ObjectName.Replace(".", "].[") + "]"
    $DDL = "CREATE TABLE " + $tableName + "`r`n(`r`n" 
    $distribution_policy = GetDistributionPolicy -Connection $conn -TableName $ObjectName
    $columns = GetColumns -Connection $conn -TableName $ObjectName
    $distColumn = $columns | Where distribution_ordinal -eq 1 | Select -ExpandProperty name
    $clusteredClause = GetClusteredClause -Connection $conn -TableName $ObjectName
    $columnsClause = GetColumnsClause -Columns $columns
    $nonclusteredClause = GetNonclusteredClause -Connection $conn -TableName $ObjectName
    $partitionClause = GetPartitionClause -Connection $conn -TableName $ObjectName

    $DDL += $columnsClause

    if ($clusteredClause -ne "") {
        $DDL += "`r`n)`r`nWITH(" + $clusteredClause
    }
    $DDL += ", DISTRIBUTION = " 
    if ($distribution_policy -eq 2)
    {
        $DDL += "HASH([" + $distColumn + "])"
    } elseif ($distribution_policy -eq 3)
    {
        $DDL += "REPLICATE"
    } else
    {
        $DDL += "ROUND_ROBIN"
    }

    if ($partitionClause -ne "") {
        $DDL += ", `r`n`t" + $partitionClause
    }

    $DDL += ")"

    return $DDL
}

#==================================================================================================

function ScriptObject($Connection, $DatabaseName, $ObjectName, $ObjectType, $OutputFolderPath, $FileName)
{
    if ($Connection.Database -ne $DatabaseName) {
        $Connection.ChangeDatabase($DatabaseName)
    }

    if ($ObjectType -in ("VIEW", "SP", "FUNCTION")) 
    {
        $DDL = ScriptSqlModule -Connection $conn -ObjectName $ObjectName
    }
    elseif ($ObjectType -eq "TABLE")
    {
        $DDL = ScriptTable -Connection $conn -ObjectName $ObjectName
    }
    elseif ($ObjectType -eq "INDEX")
    {
        $DDL = ScriptIndex -Connection $conn -ObjectName $ObjectName
    }
    elseif ($ObjectType -eq "STAT")
    {
        $DDL = ScriptStatistic -Connection $conn -ObjectName $ObjectName
    }
    elseif ($ObjectType -eq "ROLE")
    {
        $DDL = ScriptRole -Connection $conn -ObjectName $ObjectName
    }
    elseif ($ObjectType -eq "USER")
    {
        $DDL = ScriptUser -Connection $conn -ObjectName $ObjectName
    }

    $outputFilePath = $OutputFolderPath+"\"+$FileName
    $DDL | Out-File -FilePath $outputFilePath
}

#==================================================================================================


#==================================================================================================

function Test()
{
    $ServerName = ""
    $DatabaseName = "AdventureWorksDW2008"
    $UserName = ""
    $Password = ""
    $OutputFolderPath = "C:\temp"
    $WorkMode = "DDL"
    $Mode = "Full"
    $ObjectToScript = "TABLE"
    $ObjectName = "dbo.FactInternetSalesReason"
    $configFilePath = "C:\AzureSynapseScriptsAndAccelerators\Migration\APS\1_CreateMPPScripts"


    $conn = New-Object System.Data.SqlClient.SqlConnection 	
    $conn.ConnectionString = "Server=$ServerName;Database=$DatabaseName;Integrated Security=False; User ID=$UserName; Password=$Password;"

    $conn.Open()


    foreach ($f in Get-ChildItem -path $ConfigFilePath  -Filter *.csv)
    {
	    $ObjectsToScriptDriverFile = $f.FullName.ToString()	

	    $csvFile = Import-Csv $ObjectsToScriptDriverFile

	    ForEach ($ObjectToScript in $csvFile) 
	    {
		    $Active = $ObjectToScript.Active
	        if($Active -eq '1') 
		    {
			    #$ServerName = $ObjectToScript.ServerName + "," + $PortNumber
			    $DatabaseName = $ObjectToScript.DatabaseName
			    #$WorkMode = $ObjectToScript.WorkMode
			    $OutputFolderPath = $ObjectToScript.OutputFolderPath
			    $FileName = $ObjectToScript.FileName + ".dsql"
			    #$Mode= $ObjectToScript.Mode
			    $ObjectName = $ObjectToScript.ObjectName
			    $ObjectType = $ObjectToScript.ObjectsToScript
								
			    if (!(Test-Path $OutputFolderPath))
			    {
				    New-item "$OutputFolderPath" -ItemType Dir | Out-Null
			    }

                (Get-Date -Format hh:mm:ss.fff)+" - Started scripting: "+$DatabaseName+"."+$ObjectName | Write-Host -ForegroundColor Yellow
                ScriptObject -Connection $conn -DatabaseName $DatabaseName -ObjectName $ObjectName -ObjectType $ObjectType -OutputFolderPath $OutputFolderPath -FileName $FileName
                (Get-Date -Format hh:mm:ss.fff)+" - Finished scripting: "+$DatabaseName+"."+$ObjectName | Write-Host -ForegroundColor Yellow
		    }
        }
    }


    $conn.Close()
}
