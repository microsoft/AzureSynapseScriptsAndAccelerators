
# **5_DeployScriptsToSynapse:** Deploy Generated T-SQL Scripts
The deployment script is designed to run any .sql file.  For the purpose of the migration, it can be used to deploy objects to APS or Azure Synapse.  This tool can drop an existing object before running the .sql file.

The program processing logic and information flow is illustrated in the diagram below: 

![5_DeployScriptsToSynapse](../Images/5_DeployScriptsToSynapse_v2.PNG)

## **What the Script Does** ##

This PowerShell script connects to a specified MPP system (APS or Azure Synapse), runs the T-SQL Scripts specified in the configuration driver CSV file(s). The T-SQL scripts are in the following three categories:

1. Export APS Data into Azure Blob Storage by using T-SQL CETAS statements that create external tables reside in Azure Synapse and insert data into the external tables from APS tables. 
2. Create Table, View, Stored Procedures, and External Tables in Azure Synapse.
3. Import Data into Azure Synapse from Azure Blob Storage 



## How to Run the Script ##

Below are the steps to run the PowerShell script: 

**Step 5A:** Copy the scripts from Source Repository and Place them on in a local directory.

* Any directory structure will work.  As a suggestion this path can be used: C:\AzureSynapseScriptsAndAccelerators\Migration\APS\5_DeployScriptsToSynapse.
* Place the two PowerShell scripts in the above directory (RunSQLScriptDriver.ps1 and RunSQLScriptFile.ps1)
* You can choose to put all your CSV configuration files under the above directory, or in a separate directory under it, such as: C:\AzureSynapseScriptsAndAccelerators\Migration\APS\5_DeployScriptsToSynapse\Config_Files

**Step 5B:** Select one of the sample configuration files for the purpose of your deployment. All the three sample configuration files use the same format. Sample configuration files provided:

* Export APS Data to Azure Blob Storage: ApsCreateExtTablesAndExportData.csv
* Create Tables/Views/SPs in Azure Synapse:  SynapseCreateTablesViewsAndSPs.csv
* Import data from Azure Blob Storage into Azure Synapse using Polybase: SynapseImportData.csv 
* Import data from Azure Blob Storage into Azure Synapse using COPY INTO command: SynapseCopyData.csv 

Edit the one of the sample config files to fit the purpose of your deployment. Refer the below details for the configuration.

There is also a Job-Aid PowerShell script called [**Generate_Step5_ConfigFiles.ps1**](Generate_Step5_ConfigFiles.ps1) which can help you to generate an initial configuration file for this step. This Generate_Step5_ConfigFiles.ps1 uses a driver configuration CSV file named [**ConfigFileDriver.csv**](ConfigFileDriver.csv) which has instructions inside for each parameter to be set. 

Refer ***[Job Aid: Programmatically Generate Config Files](#job-aid:-programmatically-generate-config-files)*** after the steps for more details.

| **Parameter**    | **Purpose**                                                  | **Value  (Sample)**                                          |
| ---------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Active           | 1 – Run line, 0 – Skip line                                  | 0 or 1                                                       |
| ServerName       | The name of APS/PDW or Azure Synapse                         | synapseserver.database.windows.net<br />apshost.domain.corp,17001 |
| DatabaseName     | Name of the DB to connect to                                 | AdventureWorksDW                                             |
| FilePath         | Path to the script that needs to be executed.<br />*Both absolute and relative paths are supported.* | ..\Output\2_ConvertDDLScripts\AdventureWorksDW\Tables        |
| CreateSchema     | 1 – Create Schema, 0 – Don’t  create Schema                  | 0 or 1                                                       |
| ObjectType       | Type of object to Create. Used to create the drop statement. Valid Values: “”, TABLE, VIEW, SP, (SCHEMA,  STAT – Not implemented yet) | TABLE, VIEW, SP, SCHEMA, EXT                                 |
| SchemaAuth       | Specifies schema authorization (owner) when creating target schema | dbo                                                          |
| SchemaName       | Schema name for the object to be  created.                   | aw                                                           |
| ObjectName       | Name of the object that is being  created. Used in creating the drop statement and logging. | Name of the object                                           |
| ParentObjectName | Name of the parent object. Valid  for statistics and indexes. | DimAccount                                                   |
| DropIfExists     | DROP – Drop object if already exists,  TRUNCATE - Truncate Table if exists, NO – Do not drop or Truncate if exist. | DROP                                                         |
| FileName         | The name of the script file                                  | dbo_DimAccount.sql                                           |

**Step 5C:** Run the PowerShell script [**RunSQLScriptsDriver.ps1**](RunSQLScriptsDriver.ps1).  This script will prompt for the following information:

- “Enter the name of the Script Config csv File.” – This will be the location\name of your configuration file.
C:\AzureSynapseScriptsAndAccelerators\Migration\APS\5_DeployScriptsToSynapse: SynapseCreateTablesViewsAndSPs.csv or ApsCreateExtTablesAndExportData.csv or SynapseImportData.csv 
- “How do you want to connect to SQL(ADPass, ADInt, WinInt, SQLAuth)?”
	ADPass – This should be used for SQL Authentication with Password (Azure)
	ADINT – Azure AD Authentication
	SQLAUTH – SQL Server Authentication with username and password.
	“Blank” – AD integrated Authentication
- “Enter the User Name to Connect to the SQL Server.” – User name with permission to create objects
- “Enter the Password for the User” – Enter the Password for the user – reads password as a secure string
- “Enter the name of the Output File Directory.” – Enter the location where the output log will be written
- “Enter the name of the status file.” – Enter the name of the Status File

**Step 5D:** Review the Status log for Success Failures. Review the status log file. The file name and location are the prompted values of the PowerShell program in step 5C. The default location is the location of the PowerShell scripts with the file name status.csv. 

* Should a failure occur, the Status log will set the Active flag to 0 for all successful objects created  The Failures will remain Active = 1.  This will allow the status log to be used as the Script Config file and only the failed objects will be run.

  


## Job Aid: Programmatically Generate Config Files

There is a job-aid PowerShell script named [**Generate_Step5_ConfigFiles.ps1**](Generate_Step5_ConfigFiles.ps1) to help you to produce configuration file(s) programmatically. It uses output produced by previous steps (for example: T-SQL script files from module 2, schema mapping file from module 2, Export & Import T-SQL scripts generated from module 3, and T-SQL files for creating external tables generated in module 4). 

It uses parameters set inside the file named [**ConfigFileDriver_Step5.csv**](ConfigFileDriver_Step5.csv). The CSV file contains fields as value-named pairs with instructions for each field. You can set the value for each named field based on your own setup and output files. 

| **Parameter**                     | **Purpose**                                                  | **Value  (Sample)**                                          |
| --------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| OneConfigFile                     | Indicates whether single configuration file for all databases or separate configuration files for each database should be created | Yes or No                                                    |
| OneApsExportConfigFileName        | The name of single configuration file for exporting data from APS | One_ApsExportConfigFile_Generated.csv                        |
| OneSynapseObjectsConfigFileName   | The name of single configuration file for creating objects in Azure Synapse | One_SynapseObjectsConfigFile_Generated.csv                   |
| OneSynapseImportConfigFileName    | The name of single configuration file for importing data into Azure Synapse | One_SynapseImportConfigFile_Generated.csv                    |
| OneSynapseExtTablesConfigFileName | The name of single configuration file for creating external tables in Azure Synapse | One_SynapseExtTablesConfigFile_Generated.csv                 |
| OneSynapseCopyConfigFileName      | The name of single configuration file for running COPY INTO in Azure Synapse | One_SynapseCopyConfigFile_Generated.csv                      |
| ActiveFlag                        | This value will be added to generated config files as Active column | 1 or 0                                                       |
| ApsServerName                     | FQDN or IP address of APS appliance, including port number.  | demoaps,17001                                                |
| SynapseServerName                 | Azure Synapse Workspace SQL endpoint                         | demoapsmigration.sql.azuresynapse.net                        |
| SynapseDatabaseName               | The name of Azure Synapse Dedicated SQL Pool                 | EDW                                                          |
| ApsExportScriptsFolder            | The path to a folder where CETAS scripts for APS are stored.<br />*Both absolute and relative paths are supported.* | ..\Output<br />\3_CreateAPSExportScriptSynapseImportScript<br />\ExportAPS |
| SynapseImportScriptsFolder        | The path to a folder where INSERT INTO scripts for Azure Synapse are stored.<br />*Both absolute and relative paths are supported.* | ..\Output<br />\3_CreateAPSExportScriptSynapseImportScript<br />\ImportSynapse |
| SynapseCopyScriptsFolder          | The path to a folder where COPY INTO scripts for Azure Synapse are stored.<br />*Both absolute and relative paths are supported.* | ..\Output<br />\3_CreateAPSExportScriptSynapseImportScript<br />\CopySynapse |
| SynapseObjectScriptsFolder        | The path to a folder where converted DDL scripts  are stored.<br />*Both absolute and relative paths are supported.* | ..\Output\2_ConvertDDLScripts                                |
| SchemaFileFullPath                | The path to a schema mapping file. The file from module 2 can be reused.<br />*Both absolute and relative paths are supported.* | ..\2_ConvertDDLScripts\schemas.csv                           |
| SynapseExternalTablesFolder       | The path to a folder for CREATE EXTERNAL TABLE scripts for Azure Synapse are stored.<br />*Both absolute and relative paths are supported.* | ..\Output\4_CreateExternalTablesSynapse                      |
| CreateSchemaFlag                  | Indicates whether target schema should be created before running a script | 1 or 0                                                       |
| SchemaAuth                        | Specifies schema authorization (owner) when creating target schema | dbo                                                          |
| DropTruncateIfExistsFlag          | Indicates whether target object should be DROPped before running a script, or TRUNCATEd (for tables only), or NO action required. | DROP or TRUNCATE or NO                                       |
| OutputObjectsFolder               | The path to a folder where generated config file(s) will be stored.<br />*Both absolute and relative paths are supported.* | ..\Output\5_DeployScriptsToSynapse                           |
| Variables                         |                                                              |                                                              |

After running the [**Generate_Step5_ConfigFiles.ps1**](Generate_Step5_ConfigFiles.ps1), you can then review and edit the programmatically generated configuration files based on your own needs and environment. The generated config file(s) can then be used as input to the step 5 main script [**RunSQLScriptsDriver.ps1**](RunSQLScriptsDriver.ps1).






​    
