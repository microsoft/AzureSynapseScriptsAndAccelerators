
# How ConnectionType is passed? Looks like it is not used. 
#$ReturnValues = RunSQLStatement $ServerName $Database $Query $Username $Password $ConnectionType $QueryTimeout $ConnectionTimeout $InputFile $ResultAs $Variables $SourceSystem $Port
# used a lot 
function RunSQLStatement 
{ 
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerName, #$ServerName
    [Parameter(Position=1, Mandatory=$false)] [string]$Database, #$DatabaseName
    [Parameter(Position=2, Mandatory=$false)] [string]$Query, #$Query
    [Parameter(Position=3, Mandatory=$false)] [string]$Username, #$UserName
    [Parameter(Position=4, Mandatory=$false)] [string]$Password, #$Password
	[Parameter(Position=5, Mandatory=$false)] [string]$ConnectionType, #$UseIntegrated
	[Parameter(Position=6, Mandatory=$false)] [Int32]$QueryTimeout=600, 
    [Parameter(Position=7, Mandatory=$false)] [Int32]$ConnectionTimeout=30, 
    [Parameter(Position=8, Mandatory=$false)] [string]$InputFile,#[ValidateScript({test-path $_})] , $FileName 
    [Parameter(Position=9, Mandatory=$false)] [ValidateSet("DataSet", "DataTable", "DataRow")] [string]$ResultAs="DataSet",
	[Parameter(Position=10, Mandatory=$false)] [string]$Variables='',
	[Parameter(Position=11, Mandatory=$false)] [String]$SourceSystemType, #SQLServer, AzureDW, APS, Netezza
	[Parameter(Position=12, Mandatory=$false)] [int32]$Port
	)   

	# $ServerName = '192.168.52.128'#'localhost'
    # $Database = 'System'#'master' #$DatabaseName
    # $Query = 'select * from sYSTEM.ADMIN._T_DATABASE'#'select * from sys.objects' #$Query
    # $Username = 'admin' #$UserName
    # $Password = 'password' #$Password
	# $ConnectionType = 'test'#$UseIntegrated
	# $QueryTimeout = 600
    # $ConnectionTimeout = 30
    # $InputFile = '' 
    # $ResultAs="DataSet"
	# $Variables=''
	# $SourceSystemType = 'NETEZZA' #SQLServer, AzureDW, APS, Netezza
	# $Port = 5480
	
	
	try{
		$ReturnValues = @{}
		$ConnOpen = 'No'

		#Open the query Fie is one is provided
		if ($InputFile) 
		{ 
			$filePath = $(resolve-path $InputFile).path 
			$Query =  [System.IO.File]::ReadAllText("$filePath") 
		} 

		#Replace the variables in the SQL Script
		if ($Variables)
		{
			if($Variables -match "|")
			{
				$splitvar = $Variables.Split("|")
				foreach($var in $splitvar)
				{
				$splitstr = $var.Split(":")
				$search =  "(?<![\w\d])" + $splitstr[0] + "(?![\w\d])"
				$replace = $splitstr[1]
				$Query = $Query -replace $search, $replace
				}
			}
			else {
			$splitstr = $Variables.Split(":")
			$search =  "(?<![\w\d])" + $splitstr[0] + "(?![\w\d])"
			$replace = $splitstr[1]
			$Query = $Query -replace $search, $replace
			}
		}
	
		#Connect to the Server
		if($SourceSystemType -eq 'SQLSERVER' -or $SourceSystemType -eq 'APS' -or $SourceSystemType -eq 'AZUREDW')
		{

			# 
			If (($SourceSystemType -eq 'APS') -or ($SourceSystemType -eq 'SQLSERVER'))
			{
				$ServerName = $ServerName + "," + $Port # Added by Gail 
			}

			if($ConnectionType -eq 'AZUREADINT')
			{
				#$ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Integrated" -f $ServerName,$Database,$Username,$Password,$ConnectionTimeout
				$ConnectionString = "Server={0};Database={1};Trusted_Connection=False;Connect Timeout={2};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Integrated" -f $ServerName,$Database,$ConnectionTimeout
			}
			elseif($ConnectionType -eq 'ADPASS')
			{
				$ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Password" -f $ServerName,$Database,$Username,$Password,$ConnectionTimeout
			}
			elseif($ConnectionType -eq 'SQLAUTH')
			{
				$ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerName,$Database,$Username,$Password,$ConnectionTimeout 
			} 
			else 
			{ 
				$ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerName,$Database,$ConnectionTimeout 
			} 

			$conn=new-object System.Data.SqlClient.SQLConnection
			$cmd=new-object system.Data.SqlClient.SqlCommand
		}
		elseif ($SourceSystemType -eq "NETEZZA") 
		{
			$ConnectionString = "Driver=NetezzaSQL;servername={0};port={1};database={2};username={3};password={4}" -f $ServerName,$Port,$Database,$Username,$Password #$ConnectionTimeout
			#$ConnectionString = "Server={0};Database={1};Trusted_Connection=False;Connect Timeout={0};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Integrated" -f $ServerName,$Database,$ConnectionTimeout
			$conn=new-object system.data.odbc.odbcconnection
			$cmd = new-object System.Data.Odbc.OdbcCommand
		}	
		elseif ($SourceSystemType -eq "TERADATA") 
		{
			#$ConnectionString = "Driver=Teradata;DBCName={0};Database={1};Uid={2};Pwd={3}" -f $ServerName,$Database,$Username,$Password #$ConnectionTimeout
			#$ConnectionString = "Server={0};Database={1};Trusted_Connection=False;Connect Timeout={0};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Integrated" -f $ServerName,$Database,$ConnectionTimeout
			$ConnectionString = "dsn=td;"
			$conn=new-object system.data.odbc.odbcconnection
			$cmd = new-object System.Data.Odbc.OdbcCommand
		}	
		elseif ($SourceSystemType -eq "SNOWFLAKE") 
		{
			#$ConnectionString = "Driver=Teradata;DBCName={0};Database={1};Uid={2};Pwd={3}" -f $ServerName,$Database,$Username,$Password #$ConnectionTimeout
			#$ConnectionString = "Server={0};Database={1};Trusted_Connection=False;Connect Timeout={0};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Integrated" -f $ServerName,$Database,$ConnectionTimeout
			$ConnectionString = "dsn=sf;UID=markpm;pwd=DriftersEndsnowflake1;"
			$conn=new-object system.data.odbc.odbcconnection
			$cmd = new-object System.Data.Odbc.OdbcCommand
		}		
		#$conn=new-object System.Data.SqlClient.SQLConnection
		$conn.ConnectionString=$ConnectionString 
				
		$conn.Open() 
		$ConnOpen = 'YES'

		#$cmd = new-object System.Data.Odbc.OdbcCommand
		#$cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
		$cmd.connection = $conn
		$cmd.CommandText = $Query
		$cmd.CommandTimeout = $QueryTimeout 


		Display-LogMsg "RunSQLStatement Query:$Query"

		#$datareader = $cmd.ExecuteReader();
		# Use odbcdataadpter for Netezza and Teradata
		$ds=New-Object system.Data.DataSet 
		if($SourceSystemType -eq "NETEZZA" -or $SourceSystemType -eq "TERADATA" -or $SourceSystemType -eq "SNOWFLAKE")
		{
			$da=New-Object System.Data.Odbc.OdbcDataAdapter($cmd) 
		}
		else 
		{
			$da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
		}

		$da.Fill($ds) >$null| Out-Null
		#$ds.Tables[0] | export-csv "c:\temp\tofile.csv" -notypeinformation

		$ReturnValues.add('Status',"Success")
		$ReturnValues.add('Msg', "Successful")
		$ReturnValues.add('DataSet', $ds)
    }
	Catch [System.Data.SqlClient.SqlException] # For SQL exception 
    { 
		$Err = $_ 

		$ReturnValues.add('Status',"Error")
		$ReturnValues.add('Msg', $Err)
		$ReturnValues.add('DataSet', $null)
		
		Write-Verbose "Capture SQL Error" 
		if ($PSBoundParameters.Verbose) {Write-Verbose "SQL Error:  $Err"}  
		

		#switch ($ErrorActionPreference.tostring()) 
		#{ 
		#	{'SilentlyContinue','Ignore' -contains $_} {} 
		#		'Stop' {     Throw $Err } 
		#        'Continue' { Throw $Err} 
		#        Default {    Throw $Err} 
		#} 
	} 
	Catch # For other exception 
	 {
	#	Write-Verbose "Capture Other Error"   
		
		$Err = $_ 

		Write-Verbose $Err

		$ReturnValues.add('Status',"Error")
		$ReturnValues.add('Msg', $Err)
		$ReturnValues.add('DataSet', $null)
		
	#	if ($PSBoundParameters.Verbose) {Write-Verbose "Other Error:  $Err"}  

	#	switch ($ErrorActionPreference.tostring()) 
	#	{'SilentlyContinue','Ignore' -contains $_} {} 
	#				'Stop' {     Throw $Err} 
	#				'Continue' { Throw $Err} 
	#				Default {    Throw $Err} 
	}  
	Finally 
	{ 
		#Close the connection 
		#if(-not $PSBoundParameters.ContainsKey('SQLConnection')) 
		#	{ 
			if($ConnOpen -eq 'YES') 
			{	
				$conn.Close()
				$cmd.Dispose()
				$ds.Dispose()
				$da.Dispose()
				$ConnOpen = 'NO'
			}
			
				
			#}  
	}
    #switch ($As) 
    #{ 
    #    'DataSet'   { Write-Output ($ds) } 
    #    'DataTable' { Write-Output ($ds.Tables) } 
    #    'DataRow'   { Write-Output ($ds.Tables[0]) } 
    #} 
	#Write-Host $da
	if($ConnOpen -eq 'YES') 
		{
			$conn.Close()
			$ConnOpen = 'NO'
		}
	return $ReturnValues
	 
} 