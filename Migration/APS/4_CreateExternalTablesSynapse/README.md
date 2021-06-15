
# **4_CreateExternalTablesSQLDW (PowerShell):** Generate "Create External Table" DDLs for Azure SQLDW 

The program processing logic and information flow is illustrated in the diagram below: 

![Generate T-SQL Scripts for Azure SQLDW External Table Creation DDLs](../Images/4_CreateExternalTablesSynapse.PNG)

## **How to Run the Program** ##

Below are the steps to run the PowerShell Program(s): 

**Step 4A:** Create the configuration driver CSV file for the Python Program.  Refer the "Preparation Task: Configuration Driver CSV File Setup" after the steps for more details.  
Create the Configuration Driver CSV File based on the definition below. Sample CSV configuration file is provided to aid this preparation task. 

There is also a Job-Aid PowerShell program called "**Generate_Step5_ConfigFiles.ps1**" which can help you to generate an initial configuration file for this step. This Generate_Step5_ConfigFiles.ps1 uses a driver configuration SCV file named "ConfigFileDriver.csv" which has instructions inside for each parameter to be set. 


| **Parameter**    | **Purpose**                                                  | **Value (Sample)**                                           |
| ---------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Active           | 1 – Run line, 0 – Skip line                                  | 0 or 1                                                       |
| OutputFolderPath | Name of the path where output  files will be stored          | C:\AzureSynapseScriptsAndAccelerators\Migration\APS\Output\4_CreateExternalTablesSynapse\AdventureWorksDW1\ |
| FileName         | Name of the output file                                      | DimCusDimAccounttomer                                        |
| InputFolderPath  | Path to the create Table output  from step 2                 | C:\AzureSynapseScriptsAndAccelerators\Migration\APS\Output\2_ConvertDDLScripts\AdventureWorksDW1\Tables\ |
| InputFileName    | Name of the Create Table script                              | DimAccount.dsql                                              |
| SchemaName       | Name of the schema to create the  external table in          | dbo                                                          |
| ObjectName       | Name of the external table to  create                        | ext_DimAccount                                               |
| DateSource       | Name of the data source to use  for the external table       | AZURE_BLOB_STORAGE                                           |
| FileFormat       | Name of the File Format to use  when exporting the data. Must already be created. | DelimitedNoDateZip                                           |
| FileLocation     | Folder path in the staging  container. Each Table should have its  own file location. | /AdventureWorksDW1/dbo_DimAccount                            |


If the FileLocation has the “{@Var}”, the PowerShell scripts will generate create external table having a configurable location. See sample T-SQL Statement generated below. 

This configurable variable {@Var} can be replaced with a value such as: 

**test** – to import data to a location to hold test data

**dev** – to import data to a locate to hold dev data

**prod** – to import data to a location to hold prod data. 

Sample Generated File: ext_adw_dbo_DimAccount_DDL.dsql 

    CREATE EXTERNAL TABLE [ext_adw_dbo].[ext_DimAccount]
    (
    	[AccountKey]	int	NOT NULL 
    	,[ParentAccountKey]	int	NULL 
    	,[AccountCodeAlternateKey]	int	NULL 
    	,[ParentAccountCodeAlternateKey]	int NULL 
    	,[AccountDescription]	nvarchar	(50)	
    	,[AccountType]	nvarchar	(50)		,[Operator]	nvarchar	(50)	COLLATE	
    	,[CustomMembers]	nvarchar	(300)		,[ValueType]	nvarchar	(50)	COLLATE	
    	,[CustomMemberOptions]	nvarchar	(200)	
    )
     WITH (  
    LOCATION='/{@Var}/adw/dbo_DimAccount',  
    DATA_SOURCE = AzureBlobDS,  
    FILE_FORMAT = DelimitedNoDateZIP)

**Step 4B:** Run the script ScriptCreateExternalTableDriver.ps1. Provide the prompted information: The path and name of the Configuration Driver CSV File. The script does not connect to the APS or SQLDW.  The only input for this script is the config.csv file. 



## **Job Aid** - Programmatically Generate Config Files

There is a job-aid PowerShell script named "Generate_Step4_ConfigFiles.ps1" to help you to produce configuration file(s) programmatically. It uses output produced by previous steps (for example: T-SQL script files from step 2, schema mapping file from step 2, and Export & Import T-SQL scripts generated from Step 3). 

It uses parameters set inside the file named "ConfigFileDriver_Step4.csv". The CSV file contains fields as value-named pairs with instructions for each field. You can set the value for each named field based on your own setup and output files. 

After running the "Generate_Step5_ConfigFiles.ps1", you can then review and edit the programmatically generated configuration files based on your own needs and environment. The generated config file(s) can then be used as input to the step 4 main program (PowerShell: ScriptCreateExternalTableDriver.ps1).

## What the Program(s) Does

After the data has been exported from APS, the data now needs to be inserted into SQLDW.  Before this can occur, the external table needs to be created on Azure SQLDW.  This is completed by using the create table statements and converting the statement into an external table. This PowerShell program(s) generate these "Create External Table" Statements. 


Sample generated T-SQL scripts for External Table Creation in Azure SQLDW:  

    CREATE EXTERNAL TABLE [ext_adw_dbo].[ext_FactFinance]
    (
    	[FinanceKey]	int	NOT NULL 
    	,[DateKey]	int	NOT NULL 
    	,[OrganizationKey]	int	NOT NULL 
    	,[DepartmentGroupKey]	int	NOT NULL 
    	,[ScenarioKey]	int	NOT NULL 
    	,[AccountKey]	int	NOT NULL 
    	,[Amount]	float	(53)	NOT NULL 
    )
    WITH (  
    LOCATION='/prod/adventure_works/dbo_FactFinance',  
    DATA_SOURCE = AzureBlobDS,  
    FILE_FORMAT = DelimitedNoDateZIP)

