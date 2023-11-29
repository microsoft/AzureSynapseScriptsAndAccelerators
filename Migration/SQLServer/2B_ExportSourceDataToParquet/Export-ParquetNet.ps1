#======================================================================================================================#
#                                                                                                                      #
#  AzureSynapseScriptsAndAccelerators - PowerShell and T-SQL Utilities                                                 #
#                                                                                                                      #
#  This utility was developed to aid SMP/MPP migrations to Azure Synapse Analytics.                                    #
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
###################################################################################################################################
###################################################################################################################################
#
# Author: Andrey Mirskiy
# January 2022
# Description: The script extracts data from SQL Server or APS table to Parquet file.
#   The script requires Parquet.Net library installed and unzipped in the same folder. 
#   Parquet.Net nuget package - https://www.nuget.org/packages/Parquet.Net
#
###################################################################################################################################

#Requires -Version 7.0

[CmdletBinding()] 
param(
    [Parameter(Position=0, Mandatory=$true, HelpMessage="The name of SQL Server / APS / PDW instance")]
    [string] $ServerName, # = "synapse-demo.sql.azuresynapse.net",

    [Parameter(Position=1, Mandatory=$true, HelpMessage="Database name")]
    [string] $Database, # = "TPCH",

    [Parameter(Position=2, Mandatory=$true, HelpMessage="User name")]
    [string] $UserName, # = "sqladminuser",

    [Parameter(Position=3, Mandatory=$false, HelpMessage="Password")]
    [SecureString] $Password, # = $(ConvertTo-SecureString "******" -AsPlainText -Force),

    [Parameter(Position=4, Mandatory=$true, HelpMessage="Job name. Used for reference purposed only.")]
    [string] $JobName, # = "dbo_ORDERS",

    [Parameter(Position=5, Mandatory=$true, HelpMessage="Query to select data")]
    [string] $Query, # = "select top 100000 * from dbo.ORDERS",

    [Parameter(Position=6, Mandatory=$true, HelpMessage="The path to a folder where a file will be created")]
    [string] $FilePath, # = $("$PSScriptRoot\Output\dbo.ORDERS\ORDERS.snappy.parquet"),

    [Parameter(Position=7, Mandatory=$false, HelpMessage="Connection timeout")]
    [int] $ConnectionTimeout = 10,

    [Parameter(Position=8, Mandatory=$false, HelpMessage="Command timeout")]
    [int] $CommandTimeout = 30,

    [Parameter(Position=9, Mandatory=$false, HelpMessage="Maximum number of rows per rowgroup")]
    [int] $RowsPerRowGroup = 1000000,
    
    [Parameter(Position=10, Mandatory=$false, HelpMessage="The script will report progress every XXX records")]
    [int] $ReportProgressFrequency = 10000,

    [Parameter(Position=11, Mandatory=$false, HelpMessage="Debug mode")]
    [switch] $DebugMode
)

function CreateDataArray {
    [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] $SchemaColumns
    )

    $data = @{}
    foreach ($column in $SchemaColumns) {
        $columnData = [System.Collections.ArrayList]::new()
        $data.Add($column.ColumnName, $columnData)
    }  
    return $data  
}

function WriteRowGroup {
    param( 
        [Parameter(Position=0, Mandatory=$true)] $ParquetWriter,
        [Parameter(Position=1, Mandatory=$true)] $SchemaColumns,
        [Parameter(Position=2, Mandatory=$true)] $DataTypes,
        [Parameter(Position=3, Mandatory=$true)] $DataFields
    )

    try {
        $groupWriter = $parquetWriter.CreateRowGroup()

        foreach ($column in $SchemaColumns) {
            Write-Debug $column.ColumnName
    
            $field = $dataFields[$column.ColumnName]
            $dataType = $dataTypes[$column.ColumnName]
    
            $column = [Parquet.Data.DataColumn]::new($field, $data[$column.ColumnName].ToArray($dataType))
            $groupWriter.WriteColumn($column)
        }            
    } finally {
        $groupWriter.Dispose()
    }
}


enum SqlDataTypes {
    int
    tinyint
    smallint
    bigint
    bit
    char
    nchar
    varchar
    nvarchar
	text
	ntext
    real
    float
    decimal
    money
    smallmoney
    date
    time
    datetime
    datetime2
    smalldatetime
    datetimeoffset
    binary
    varbinary
    string
    rowversion
	timestamp
}


Function Export-Table
{
    [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$Database,
        [Parameter(Position=1, Mandatory=$true)] [string]$JobName,
        [Parameter(Position=2, Mandatory=$true)] [string]$Query,
        [Parameter(Position=3, Mandatory=$true)] [string]$FilePath
    ) 

    Write-Output "$(Get-Date -Format hh:mm:ss.fff) - Job $JobName started"

    $conn = New-Object System.Data.SqlClient.SqlConnection

    if ($global:Password.Length -eq 0) {
        $conn.ConnectionString = "Server={0};Database={1};User ID={2};Trusted_Connection=True;Connect Timeout={3}" -f $ServerName,$Database,$Username,$global:ConnectionTimeout
    }
    else
    {
    $password = ConvertFrom-SecureString -SecureString $Password -AsPlainText
    $conn.ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerName,$Database,$Username,$Password,$ConnectionTimeout
    }
    
    [string[]]$columnNames = @()
    [type[]]$columnTypes = @()
    [int[]]$sqlDataTypes = @()
    [string[]]$columnTypeNames = @()
    $dataFields = @{}
    $dataTypes = @{}
    [Parquet.Data.Field[]]$fields = @()
    
    try {
        $conn.Open() 
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.Connection = $conn
        $cmd.CommandText = $Query
        $cmd.CommandTimeout = $CommandTimeout
    
        $reader = $cmd.ExecuteReader()
    
        ####### SCHEMA definition ###############    
        $schemaTable = $reader.GetSchemaTable()
        $schemaColumns = $schemaTable.Rows
        foreach ($schemaColumn in $schemaColumns) {
            $columnName = $schemaColumn.ColumnName
            $columnNames += $columnName
            $columnType = $schemaColumn.DataType
            $columnTypes += $columnType
            $columnTypeName = $schemaColumn.DataTypeName
            $columnTypeNames += $columnTypeName
            $isNull = $schemaColumn.AllowDBNull
    
            switch ($columnTypeName)
            {
                {$_ -in @("int") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::Int32, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[int]] } else { [int] }
                    $sqlDataTypes += [SqlDataTypes]::int
                    continue
                }
                {$_ -in @("tinyint") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::Byte, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[byte]] } else { [byte] }
                    $sqlDataTypes += [SqlDataTypes]::tinyint
                    continue
                }
                {$_ -in @("smallint") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::Int16, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[Int16]] } else { [Int16] }
                    $sqlDataTypes += [SqlDataTypes]::smallint
                    continue
                }
                {$_ -in @("bigint") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::Int64, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[long]] } else { [long] }
                    $sqlDataTypes += [SqlDataTypes]::bigint
                    continue
                }
                {$_ -in @("bit") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::Boolean, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[bool]] } else { [bool] }
                    $sqlDataTypes += [SqlDataTypes]::bit
                    continue
                }
                {$_ -in @("nvarchar", "varchar", "nchar", "char", "ntext", "text") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::String, $isNull, $false)
                    $dataType = [string]
                    $sqlDataTypes += [SqlDataTypes]::string
                    continue
                }
                {$_ -in @("date") } { 
                    $field = [Parquet.Data.DateTimeDataField]::new($columnName, [Parquet.Data.DateTimeFormat]::Date)
                    $dataType = if ($isNull) { [Nullable[DateTimeOffset]] } else { [DateTimeOffset] }
                    $sqlDataTypes += [SqlDataTypes]::datetime
                    continue
                }
                {$_ -in @("time") } { 
                    $field = [Parquet.Data.DateTimeDataField]::new($columnName, [Parquet.Data.DateTimeFormat]::Impala, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[DateTimeOffset]] } else { [DateTimeOffset] }
                    $sqlDataTypes += [SqlDataTypes]::time
                    continue
                }
                {$_ -in @("datetimeoffset") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::String, $isNull, $false)
                    $dataType = [string]
                    $sqlDataTypes += [SqlDataTypes]::datetimeoffset
                    continue
                }
                {$_ -in @("datetime", "smalldatetime", "datetime2") } { 
                    $field = [Parquet.Data.DateTimeDataField]::new($columnName, [Parquet.Data.DateTimeFormat]::Impala, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[DateTimeOffset]] } else { [DateTimeOffset] }
                    $sqlDataTypes += [SqlDataTypes]::datetime
                    continue
                }
                {$_ -in @("money") } { 
                    $field = [Parquet.Data.DecimalDataField]::new($columnName, 19, 4)
                    $dataType = if ($isNull) { [Nullable[decimal]] } else { [decimal] }
                    $sqlDataTypes += [SqlDataTypes]::decimal
                    continue
                }
                {$_ -in @("smallmoney") } { 
                    $field = [Parquet.Data.DecimalDataField]::new($columnName, 10, 4)
                    $dataType = if ($isNull) { [Nullable[decimal]] } else { [decimal] }
                    $sqlDataTypes += [SqlDataTypes]::decimal
                    continue
                }
                {$_ -in @("float") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::Double, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[double]] } else { [double] }
                    $sqlDataTypes += [SqlDataTypes]::float
                    continue
                }
                {$_ -in @("real") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::Float, $isNull, $false)
                    $dataType = if ($isNull) { [Nullable[float]] } else { [float] }
                    $sqlDataTypes += [SqlDataTypes]::real
                    continue
                }
                {$_ -in @("decimal") } { 
                    $field = [Parquet.Data.DecimalDataField]::new($columnName, $schemaColumn.NumericPrecision, $schemaColumn.NumericScale)
                    $dataType = if ($isNull) { [Nullable[decimal]] } else { [decimal] }
                    $sqlDataTypes += [SqlDataTypes]::decimal
                    continue
                }
                {$_ -in @("binary", "varbinary", "rowversion", "timestamp") } { 
                    $field = [Parquet.Data.DataField]::new($columnName, [Parquet.Data.DataType]::ByteArray, $isNull, $false)
                    $dataType = if ($isNull) { [byte[]] } else { [byte[]] }
                    $sqlDataTypes += [SqlDataTypes]::binary
                    continue
                }
                Default { throw "Not Implemented" }
            }
    
            $dataFields.Add($columnName, $field)
            $dataTypes.Add($columnName, $dataType)
            $fields += $field
        }
    
        $schema = [Parquet.Data.Schema]::new($fields)
    
        ####### End SCHEMA definition ###############
    

        $exportPath = Split-Path -Path $FilePath -Parent
        if (-not (Test-Path -Path $exportPath)) {
            New-Item -Path $exportPath -ItemType Directory | Out-Null
        }

        $fileStream = [System.IO.File]::Create($filePath)
        $parquetWriter = [Parquet.ParquetWriter]::new($schema, $fileStream)    
    
        $data = CreateDataArray $schemaColumns
    
        $rowNum = 0
        while ($reader.Read()) {
            $rowNum++
            for ([int]$i=0; $i -lt $columnNames.Length; $i++) {
                $val = $null
                $columnType = $columnTypes[$i]
                $columnTypeName = $columnTypeNames[$i]
                $sqlDataType = $sqlDataTypes[$i]

                if ($sqlDataType -eq [SqlDataTypes]::int)                { if (!$reader.IsDBNull($i)) { $val = $reader.GetInt32($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::decimal)        { if (!$reader.IsDBNull($i)) { $val = $reader.GetDecimal($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::date)           { if (!$reader.IsDBNull($i)) { $val = [ParquetSharp.Date]::new($reader.GetDateTime($i)) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::string)         { if (!$reader.IsDBNull($i)) { $val = $reader.GetString($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::smallint)       { if (!$reader.IsDBNull($i)) { $val = $reader.GetInt16($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::tinyint)        { if (!$reader.IsDBNull($i)) { $val = $reader.GetByte($i) }  }
                elseif ($sqlDataType -eq [SqlDataTypes]::bigint)         { if (!$reader.IsDBNull($i)) { $val = $reader.GetInt64($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::money)          { if (!$reader.IsDBNull($i)) { $val = $reader.GetDecimal($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::smallmoney)     { if (!$reader.IsDBNull($i)) { $val = $reader.GetDecimal($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::bit)            { if (!$reader.IsDBNull($i)) { $val = $reader.GetBoolean($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::real)           { if (!$reader.IsDBNull($i)) { $val = $reader.GetFloat($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::float)          { if (!$reader.IsDBNull($i)) { $val = $reader.GetDouble($i) } }
                elseif ($sqlDataType -eq [SqlDataTypes]::binary)         { if (!$reader.IsDBNull($i)) { $val = [byte[]]$reader[$i] } }
                elseif ($sqlDataType -eq [SqlDataTypes]::time)           { if (!$reader.IsDBNull($i)) { 
                            [TimeSpan]$ts = $reader.GetTimeSpan($i) 
                            $val = [DateTimeOffset]::new([DateTime]::new(1970,1,2) + $ts,$DateTimeOffset) }
                        }
                elseif ($sqlDataType -eq [SqlDataTypes]::datetime)       { if (!$reader.IsDBNull($i)) { 
                            [DateTime]$dt = $reader.GetDateTime($i) 
                            $val = [DateTimeOffset]::new($dt,$DateTimeOffset) }
                        }
                elseif ($sqlDataType -eq [SqlDataTypes]::datetimeoffset) { if (!$reader.IsDBNull($i)) { 
                            [DateTimeOffset]$dto = $reader.GetDateTimeOffset($i) 
                            $val = $dto.ToString("yyyy-MM-dd HH:mm:ss.fffffff zzz", [cultureinfo]::InvariantCulture) }
                        }
                else { throw "Not Implemented" }

                [void]$data[$columnNames[$i]].Add($val) 
            }

            # Report progress
            if ($rowNum%$ReportProgressFrequency -eq 0) {
                Write-Output "$(Get-Date -Format hh:mm:ss.fff) - Job $JobName processed rows - $rowNum"
            }

            # Need to dump RowGroup
            if ($rowNum%$RowsPerRowGroup -eq 0) {
                WriteRowGroup $parquetWriter $schemaColumns $dataTypes $dataFields
                $data = CreateDataArray $schemaColumns
            }
        }
        $reader.Close()
    
        # more records available for the last RowGroup
        if ($rowNum%$RowsPerRowGroup -gt 0) {
            WriteRowGroup $parquetWriter $schemaColumns $dataTypes $dataFields
            Write-Output "$(Get-Date -Format hh:mm:ss.fff) - Job $JobName processed rows - $rowNum"
        }

        Write-Output "$(Get-Date -Format hh:mm:ss.fff) - Job $JobName completed"
    } 
    finally {
        if ($conn) { $conn.Close() }
        if ($parquetWriter) { $parquetWriter.Dispose() }
        if ($fileStream) { $fileStream.Dispose() }
    }    
}


###############################################################################################
# Main logic here
###############################################################################################

# When running from a background job $PSScriptRoot is empty
$currentLocation = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

# Load assemblies
Add-Type -Path "$currentLocation\parquet.net.3.9.1.nupkg\lib\net5.0\Parquet.dll"
Add-Type -Path "$currentLocation\ironsnappy.1.3.0.nupkg\lib\netstandard2.1\IronSnappy.dll"


$DateTimeOffset = [TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now)
$DateTimeOffset = $DateTimeOffset.Negate()

$startTime = Get-Date

Export-Table -Database $database -JobName $jobName -Query $query -FilePath $filePath

$finishTime = Get-Date

if ($DebugMode) {
    Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
    Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
    Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
}
