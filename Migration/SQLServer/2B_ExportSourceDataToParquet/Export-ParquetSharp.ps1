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
#   The script requires ParquetSharp library installed and unzipped in the same folder. 
#   ParquetSharp nuget package - https://www.nuget.org/packages/ParquetSharp
#
# Contributor: Yoni Sade
# November 2023
# Description: 	Added support for text, ntext, rowversion, timestamp data types
#		Added support for Windows Authentication / Trusted Connection when user skips "-Password" argument
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

    [Parameter(Position=11, Mandatory=$false, HelpMessage="Use beta version of ParquetSharp package")]
    [switch] $UseBeta,

    [Parameter(Position=12, Mandatory=$false, HelpMessage="Debug mode")]
    [switch] $DebugMode
)

function CreateDataArray {
    [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] $SchemaTable
    )

    $data = @{}
    foreach ($column in $SchemaTable.Rows) {
        $columnData = [System.Collections.ArrayList]::new()
        $data.Add($column.ColumnName, $columnData)
    }  
    return $data  
}

function WriteRowGroup {
    param( 
        [Parameter(Position=0, Mandatory=$true)] $FileWriter,
        [Parameter(Position=1, Mandatory=$true)] $Columns,
        [Parameter(Position=2, Mandatory=$true)] $DataTypes,
        [Parameter(Position=3, Mandatory=$true)] $Data
    )

    try {
        $rowGroup = $fileWriter.AppendRowGroup()

        foreach ($column in $Columns) {
            Write-Debug $column.Name

            $dataArray = $data[$column.Name].ToArray($dataTypes[$column.Name])
            $columnWriter = $rowGroup.NextColumn().LogicalWriter()
            $columnWriter.WriteBatch($dataArray)
        } 
        $rowGroup.Close()  
    } finally {
        $rowGroup.Dispose()
    }
}


function Convert-SecureStringToString
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline)]
    [System.Security.SecureString]
    $Password
  )
  
  process
  {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }
}


Function Get-Int96Pieces {
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName='DateTime', Position=0)]
        [DateTime] $dt,
        [Parameter(ParameterSetName='TimeSpan', Position=0)]
        [TimeSpan] $ts
    )

    if ($dt) {
        [long]$nanos = $dt.TimeOfDay.Ticks * 100 # 1000000
    } else {
        [long]$nanos = $ts.Ticks * 100
    }
    [int]$a = [BitConverter]::ToInt32([BitConverter]::GetBytes($nanos -band 0xFFFFFFFF))
    [int]$b = $nanos -shr 32
    
    if ($dt) {
        $Year = $dt.Year; $Month = $dt.Month; $Day = $dt.Day;                    
        if ($Month -lt 3)
        {
            $Month = $Month + 12;
            $Year = $Year - 1;
        }
        $c = [math]::Floor($Day + (153 * $Month - 457) / 5 + 365 * $Year + ($Year / 4) - ($Year / 100) + ($Year / 400) + 1721119)
    } else {
        $c = 2440589    # 1/2/1970 constant
    }
    
    return $a, $b, $c
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
        $password = ConvertFrom-SecureString -SecureString $global:Password -AsPlainText        
        $conn.ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerName,$Database,$Username,$Password,$global:ConnectionTimeout
    }
    [string[]]$columnNames = @()
    [type[]]$columnTypes = @()
    [int[]]$sqlDataTypes = @()
    [string[]]$columnTypeNames = @()
    $dataTypes = @{}

    $columnsArray = [System.Collections.ArrayList]::new()
    
    try {
        $conn.Open() 
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.Connection = $conn
        $cmd.CommandText = $Query
        $cmd.CommandTimeout = $global:CommandTimeout
    
        $reader = $cmd.ExecuteReader()
    
        ####### SCHEMA definition ###############    
        $schemaTable = $reader.GetSchemaTable()
        foreach ($schemaColumn in $schemaTable.Rows) {
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
                    $dataType = if ($isNull) { [Nullable[int]] } else { [int] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[int]]]::new($columnName) } else {[ParquetSharp.Column[int]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::int
                    continue
                }
                {$_ -in @("tinyint") } { 
                    $dataType = if ($isNull) { [Nullable[byte]] } else { [byte] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[byte]]]::new($columnName) } else {[ParquetSharp.Column[byte]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::tinyint
                    continue
                }
                {$_ -in @("smallint") } { 
                    $dataType = if ($isNull) { [Nullable[Int16]] } else { [Int16] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[Int16]]]::new($columnName) } else {[ParquetSharp.Column[Int16]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::smallint
                    continue
                }
                {$_ -in @("bigint") } { 
                    $dataType = if ($isNull) { [Nullable[long]] } else { [long] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[long]]]::new($columnName) } else {[ParquetSharp.Column[long]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::bigint
                    continue
                }
                {$_ -in @("bit") } { 
                    $dataType = if ($isNull) { [Nullable[bool]] } else { [bool] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[bool]]]::new($columnName) } else {[ParquetSharp.Column[bool]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::bit
                    continue
                }
                {$_ -in @("nvarchar", "varchar", "nchar", "char", "ntext", "text") } { 
                    $dataType = [string]
                    $column = [ParquetSharp.Column[string]]::new($columnName)
                    $sqlDataTypes += [SqlDataTypes]::string
                    continue
                }
                {$_ -in @("date") } { 
                    $dataType = if ($isNull) { [Nullable[ParquetSharp.Date]] } else { [ParquetSharp.Date] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[ParquetSharp.Date]]]::new($columnName) } else {[ParquetSharp.Column[ParquetSharp.Date]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::date
                    continue
                }
                {$_ -in @("datetime") } { 
                    $dataType = if ($isNull) { [Nullable[ParquetSharp.Int96]] } else { [ParquetSharp.Int96] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[ParquetSharp.Int96]]]::new($columnName) } else {[ParquetSharp.Column[ParquetSharp.Int96]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::datetime
                    continue
                }
                {$_ -in @("datetime2") } { 
                    $dataType = if ($isNull) { [Nullable[ParquetSharp.Int96]] } else { [ParquetSharp.Int96] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[ParquetSharp.Int96]]]::new($columnName) } else {[ParquetSharp.Column[ParquetSharp.Int96]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::datetime2
                    continue
                }
                {$_ -in @("smalldatetime") } { 
                    $dataType = if ($isNull) { [Nullable[ParquetSharp.Int96]] } else { [ParquetSharp.Int96] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[ParquetSharp.Int96]]]::new($columnName) } else {[ParquetSharp.Column[ParquetSharp.Int96]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::smalldatetime
                    continue
                }
                {$_ -in @("time") } { 
                    $dataType = if ($isNull) { [Nullable[ParquetSharp.Int96]] } else { [ParquetSharp.Int96] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[ParquetSharp.Int96]]]::new($columnName) } else {[ParquetSharp.Column[ParquetSharp.Int96]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::time
                    continue
                }
                {$_ -in @("datetimeoffset") } { 
                    $dataType = if ($isNull) { [string] } else { [string] }
                    $column = [ParquetSharp.Column[string]]::new($columnName)
                    $sqlDataTypes += [SqlDataTypes]::datetimeoffset
                    continue
                }
                {$_ -in @("money", "smallmoney") } { 
                    $dataType = if ($isNull) { [Nullable[decimal]] } else { [decimal] }
                    $column = [ParquetSharp.Column[Nullable[decimal]]]::new($columnName, [ParquetSharp.LogicalType]::Decimal(29,4))
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[decimal]]]::new($columnName, [ParquetSharp.LogicalType]::Decimal(29,4)) } else {[ParquetSharp.Column[decimal]]::new($columnName, [ParquetSharp.LogicalType]::Decimal(29,4))}
                    $sqlDataTypes += [SqlDataTypes]::decimal
                    continue
                }
                {$_ -in @("real") } { 
                    $dataType = if ($isNull) { [Nullable[float]] } else { [float] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[float]]]::new($columnName) } else {[ParquetSharp.Column[float]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::real
                    continue
                }
                {$_ -in @("float") } { 
                    $dataType = if ($isNull) { [Nullable[double]] } else { [double] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[double]]]::new($columnName) } else {[ParquetSharp.Column[double]]::new($columnName)}
                    $sqlDataTypes += [SqlDataTypes]::float
                    continue
                }
                {$_ -in @("decimal") } { 
                    $dataType = if ($isNull) { [Nullable[decimal]] } else { [decimal] }
                    $column = if ($isNull) { [ParquetSharp.Column[Nullable[decimal]]]::new($columnName, [ParquetSharp.LogicalType]::Decimal(29,$schemaColumn.NumericScale)) } else {[ParquetSharp.Column[decimal]]::new($columnName, [ParquetSharp.LogicalType]::Decimal(29,$schemaColumn.NumericScale))}
                    $sqlDataTypes += [SqlDataTypes]::decimal
                    continue
                }
                {$_ -in @("binary", "varbinary", "rowversion", "timestamp") } { 
                    $dataType = [byte[]]
                    $column = [ParquetSharp.Column[byte[]]]::new($columnName)
                    $sqlDataTypes += [SqlDataTypes]::binary
                    continue
                }
                Default { throw "Data type ""$_"" Not Implemented" }
            }
    
            $columnsArray.Add($column) | Out-Null
            $dataTypes.Add($columnName, $dataType)
        }
    
        $columns = $columnsArray.ToArray([ParquetSharp.Column])

        ####### End SCHEMA definition ###############

        
#        $exportPath = Split-Path -Path $FilePath -Parent
#        if (-not (Test-Path -Path $exportPath)) {
#            New-Item -Path $exportPath -ItemType Directory | Out-Null
#        }
#        #$filePath = Join-Path -Path $ExportPath -ChildPath "$Table.parquet"

        $fileWriter = [ParquetSharp.ParquetFileWriter]::new($filePath, $columns)
        
        $data = CreateDataArray $schemaTable
    
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
                            $a, $b, $c = Get-Int96Pieces $ts
                            $val = [ParquetSharp.Int96]::new($a,$b,$c) }
                        }
                elseif ($sqlDataType -eq [SqlDataTypes]::datetime)       { if (!$reader.IsDBNull($i)) {
                            [DateTime]$dt = $reader.GetDateTime($i)
                            $a, $b, $c = Get-Int96Pieces $dt
                            $val = [ParquetSharp.Int96]::new($a,$b,$c) }
                        }
                elseif ($sqlDataType -eq [SqlDataTypes]::datetimeoffset) { if (!$reader.IsDBNull($i)) {
                            [DateTimeOffset]$dto = $reader.GetDateTimeOffset($i)
                            $val = $dto.ToString("yyyy-MM-dd HH:mm:ss.fffffff zzz", [cultureinfo]::InvariantCulture) }
                        }
                else { throw "Data type ""$sqlDataType"" Not Implemented" }

                [void]$data[$columnNames[$i]].Add($val)
            }    

            # Report progress
            if ($rowNum%$ReportProgressFrequency -eq 0) {
                Write-Output "$(Get-Date -Format hh:mm:ss.fff) - Job $JobName processed rows - $rowNum"
            }

            # Need to dump RowGroup
            if ($rowNum%$RowsPerRowGroup -eq 0) {
                WriteRowGroup $fileWriter $columns $dataTypes $data
                $data = CreateDataArray $schemaTable
            }
        }
        $reader.Close()
    
        # more records available for the last RowGroup
        if ($rowNum%$RowsPerRowGroup -gt 0) {
            WriteRowGroup $fileWriter $columns $dataTypes $data
            Write-Output "$(Get-Date -Format hh:mm:ss.fff) - Job $JobName processed rows - $rowNum"
        }

        Write-Output "$(Get-Date -Format hh:mm:ss.fff) - Job $JobName completed"
    }
	catch {
		$e = $_.Exception
		#this is wrong
		$line = $_.Exception.InvocationInfo.ScriptLineNumber
		$msg = $e.Message 

		Write-Host -ForegroundColor Red "caught exception: $e at $line"
		Write-Host -ForegroundColor Cyan $_
		Add-Content -Path Export-table.log -Value "caught exception: $e at $line"
	 $("[" + (Get-Date) + "] " + $_)
	}	
    finally {
        if ($conn) { $conn.Close() }
        if ($fileWriter) { $fileWriter.Dispose() }
    }    
}


###############################################################################################
# Main logic here
###############################################################################################

# When running from a background job $PSScriptRoot is empty
$currentLocation = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

if ($UseBeta) {
    # This is required for PowerShell to be able to find native library
    $env:Path += ";$currentLocation\parquetsharp.6.0.1-beta1.nupkg\runtimes\win-x64\native"
    # Load assemblies
    Add-Type -Path "$currentLocation\parquetsharp.6.0.1-beta1.nupkg\lib\netstandard2.1\ParquetSharp.dll"
} else {
    # This is required for PowerShell to be able to find native library
    $env:Path += ";$currentLocation\parquetsharp.5.0.0.nupkg\runtimes\win-x64\native"
    # Load assemblies
    Add-Type -Path "$currentLocation\parquetsharp.5.0.0.nupkg\lib\netstandard2.1\ParquetSharp.dll"
}


$DateTimeOffset = [TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now)
$DateTimeOffset = $DateTimeOffset.Negate()

$startTime = Get-Date

Export-Table -Database $database -JobName $JobName -Query $query -FilePath $filePath

$finishTime = Get-Date

if ($DebugMode) {
    Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
    Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
    Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
}
