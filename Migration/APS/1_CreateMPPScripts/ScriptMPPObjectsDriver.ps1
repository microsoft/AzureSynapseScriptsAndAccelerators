# =================================================================================================================================================
# Scriptname: ScriptMPPObjectsDriver.ps1
# 
# Created: December, 2020
# Authors: Andy Isley, Gaiye "Gail" Zhou, Andrey Mirskiy
# Company: Microsoft 
# 
# =================================================================================================================================================
# Description:
#       Driver to script out MPP objects to .dsql using PDWScripter
#
# ===============================================================================================================================================

function Display-ErrorMsg($ImportError, $ErrorMsg)
{
	Write-Host $ImportError
}

Function GetPassword($securePassword)
{
       $securePassword = Read-Host "PDW Password" -AsSecureString
       $P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
       return $P
}

###############################################################################################
# User Input Here
###############################################################################################



#$defaultConfigFilePath = "C:\APS2SQLDW\1_CreateMPPScripts"
$defaultConfigFilePath = "$PSScriptRoot"
$ConfigFilePath = Read-Host -prompt "Enter the directory where the Configuration CSV File resides or Press 'Enter' to accept the default [$($defaultConfigFilePath)]"
if($ConfigFilePath -eq "" -or $ConfigFilePath -eq $null)
	{$ConfigFilePath = $defaultConfigFilePath}


# Note: When we publish this code, the IP address needs to be deleted.
$defaultApsServerName = "1#.20#.22#.###,17001"       # Please fill in your own APS IP address 
$ServerName = Read-Host -prompt "Enter the name of the Server ('APS Server Name or IP Address, 17001')"
	if($ServerName -eq "" -or $ServerName -eq $null) 
		{$ServerName = $defaultApsServerName} 


$UseIntegrated = Read-Host -prompt "Enter 'Yes' to connect using integrated Security. Enter 'No' otherwise."
if($UseIntegrated -eq "" -or $UseIntegrated -eq $null) {
    $UseIntegrated = "No"
}


if($UseIntegrated.ToUpper() -ne "YES")
{
	$UserName = Read-Host -prompt "Enter the UserName to connect to the MPP System."
	if($UserName -eq "" -or $UserName -eq $null)
	{
		Write-Host "A password must be entered"
		break
	}
	$Password = GetPassword
	if($Password -eq "") 
	{
		Write-Host "A password must be entered."
		break
	}
    $connectionString = "Server=$ServerName;Database=master;Integrated Security=False; User ID=$UserName; Password=$Password;"
} else
{
    $connectionString = "Server=$ServerName;Database=master;Integrated Security=True;"
}



Import-Module "$PSScriptRoot\PDWScripter.ps1"  

$startTime = Get-Date

$OutputBasePath = Split-Path -Path $PSScriptRoot -Parent
$OutputBasePath += "\Output"

try
{
    $conn = New-Object System.Data.SqlClient.SqlConnection 	
    $conn.ConnectionString = $connectionString
    $conn.Open()


    foreach ($f in Get-ChildItem -path $ConfigFilePath  -Filter *.csv)
    {
	    $ObjectsToScriptDriverFile = $f.FullName.ToString()	

	    $csvFile = Import-Csv $ObjectsToScriptDriverFile

	    ForEach ($ObjectToScript in $csvFile ) 
	    {
		    $Active = $ObjectToScript.Active
			if($Active -eq '1') 
		    {
			    $ServerName = $ObjectToScript.ServerName 
			    $DatabaseName = $ObjectToScript.DatabaseName
			    $WorkMode = $ObjectToScript.WorkMode
			    $OutputFolderPath = $OutputBasePath + $ObjectToScript.OutputFolderPath
			    $FileName = $ObjectToScript.FileName + ".dsql"
			    $Mode= $ObjectToScript.Mode
			    $ObjectName = $ObjectToScript.ObjectName
			    $ObjectType = $ObjectToScript.ObjectsToScript
								
			    if (!(Test-Path $OutputFolderPath))
			    {
				    New-item "$OutputFolderPath" -ItemType Dir | Out-Null
			    }
	
			    $OutpputFolderPathFileName = $OutputFolderPath + $FileName
			
                if ($ObjectType.ToUpper() -in ("TABLE", "VIEW", "SP", "FUNCTION", "INDEX", "STATISTIC"))
                {
			        $test = $ObjectName.Split('.')
	
			        if($ObjectName.Split('.').Length -eq 1)
			        {
				        $ObjectName = 'dbo.' + $ObjectName
			        }
			        elseif($ObjectName.Split('.')[0] -eq '')
			        {
				        $ObjectName = 'dbo' + $ObjectName
			        }
                }
			
                (Get-Date -Format HH:mm:ss.fff)+" - Started scripting: "+$DatabaseName+"."+$ObjectName | Write-Host -ForegroundColor Yellow
                ScriptObject -Connection $conn -DatabaseName $DatabaseName -ObjectName $ObjectName -ObjectType $ObjectType -OutputFolderPath $OutputFolderPath -FileName $FileName
                (Get-Date -Format HH:mm:ss.fff)+" - Finished scripting: "+$DatabaseName+"."+$ObjectName | Write-Host -ForegroundColor Yellow
		    }
	    }
    }			 
}
finally 
{
    if ($conn -ne $null) {
        $conn.Close()
    }
}

$finishTime = Get-Date

Write-Host "Program Start Time:   ", $startTime -ForegroundColor Green
Write-Host "Program Finish Time:  ", $finishTime -ForegroundColor Green
Write-Host "Program Elapsed Time: ", ($finishTime-$startTime) -ForegroundColor Green
