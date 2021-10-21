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
#       Runs a single .sql script against a SQL Server/Synapse/APS
#        
# =================================================================================================================================================
# 
# Authors: Andrey Mirskiy
# Tested with APS (Analytics Platform System)
# 
# Use this to set Powershell permissions (examples)
# Set-ExecutionPolicy Unrestricted -Scope CurrentUser 
# Unblock-File -Path C:\AzureSynapseScriptsAndAccelerators\Migration\APS\5_DeployScriptsToSynapse\RunSQLScriptFile.ps1


#Requires -Version 5.1
#Requires -Modules SqlServer


function RunSQLScriptFile 
{ 
    [CmdletBinding()] 
    param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$ServerName, 
        [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
        [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
        [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
        [Parameter(Position=4, Mandatory=$false)] [string]$Password,
	    [Parameter(Position=5, Mandatory=$false)] [string]$SynapseADIntegrated,
        [Parameter(Position=6, Mandatory=$false)] [Int32]$QueryTimeout=0, 
        [Parameter(Position=7, Mandatory=$false)] [Int32]$ConnectionTimeout=0, 
        [Parameter(Position=8, Mandatory=$false)] [string]$InputFile,#[ValidateScript({test-path $_})] , 
        [Parameter(Position=9, Mandatory=$false)] [ValidateSet("DataSet", "DataTable", "DataRow")] [string]$As="DataSet",
	    [Parameter(Position=10, Mandatory=$false)] [string]$Variables=''
	    #[Parameter(Position=11, Mandatory=$false)] [string]$SchemaName,
	    #[Parameter(Position=12, Mandatory=$false)] [string]$TableName,
	    #[Parameter(Position=13, Mandatory=$false)] [string]$DropIfExists,
	    #[Parameter(Position=14, Mandatory=$false)] [string]$StatusLogFile #[ValidateScript({test-path $_})] 
    ) 

	try
    {
	    $ReturnValues = @{}
	    $ConnOpen = 'No'

        if ($InputFile) 
        { 
            $filePath = $(resolve-path $InputFile).path 
            $Query =  [System.IO.File]::ReadAllText("$filePath") 
        } 

	    if ($Variables)
	    {
		     if($Variables -match ";")
		     {
			     $splitvar = $Variables.Split(";")
			     foreach($var in $splitvar)
			     {
				    $splitstr = $var.Split("|")
				    $search =  "(?<![\w\d])" + $splitstr[0] + "(?![\w\d])"
				    $replace = $splitstr[1]
				    $Query = $Query -replace $search, $replace
			     }
		     }
		     else {
			    $splitstr = $Variables.Split("|")
			    $search =  "(?<![\w\d])" + $splitstr[0] + "(?![\w\d])"
			    $replace = $splitstr[1]
			    $Query = $Query -replace $search, $replace
		     }		 		 
	    }
 

		if($SynapseADIntegrated -eq 'ADINT') {
			$ConnectionString = "Server={0};Database={1};Trusted_Connection=False;Connect Timeout={2};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Integrated" -f $ServerName,$Database,$ConnectionTimeout
		}
		elseif($SynapseADIntegrated -eq 'ADPASS') {
			$ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Password" -f $ServerName,$Database,$Username,$Password,$ConnectionTimeout
		}
		elseif($SynapseADIntegrated -eq 'SQLAUTH') {
			$ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerName,$Database,$Username,$Password,$ConnectionTimeout 
		} 
		else { 
            $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerName,$Database,$ConnectionTimeout 
        } 
 
	    $conn=new-object System.Data.SqlClient.SQLConnection
        $conn.ConnectionString=$ConnectionString 
     
        #Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose parameter specified by caller 
        if ($PSBoundParameters.Verbose) 
        { 
            $conn.FireInfoMessageEventOnUserErrors=$true 
            $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Verbose "$($_)"} 
            $conn.add_InfoMessage($handler) 
        } 
     
        $conn.Open() 
	    $ConnOpen = 'YES'
        $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
        $cmd.CommandTimeout=$QueryTimeout 
        $ds=New-Object system.Data.DataSet 
        $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 

		[void]$da.fill($ds) 

		$ReturnValues.add('Status',"Success")
		$ReturnValues.add('Msg', $ErrVar)
    }
	Catch [System.Data.SqlClient.SqlException] # For SQL exception 
    { 
		$Err = $_ 

		$ReturnValues.add('Status',"Error")
		$ReturnValues.add('Msg', $Err)
		
		Write-Verbose "Capture SQL Error" 
		if ($PSBoundParameters.Verbose) {
            Write-Verbose "SQL Error:  $Err"
        } 
	} 
	Catch # For other exception 
	{
		$Err = $_ 

		$ReturnValues.add('Status',"Error")
		$ReturnValues.add('Msg', $Err)
	}  
	Finally 
	{ 
		if($ConnOpen -eq 'YES') 
		{
            $ConnOpen = 'NO'
			$conn.Close()
			$cmd.Dispose()
			$ds.Dispose()
			$da.Dispose()
		}
	}

	if($ConnOpen -eq 'YES') 
    {
        $ConnOpen = 'NO'
		$conn.Close()
    }
	
    return $ReturnValues	 
} 