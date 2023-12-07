# **SQL Server to Azure Synapse Migration Process & Scripts** 

This directory contains SQL server to Azure Synapse Migration Toolkit. It includes the Process, PowerShell Scripts, and useful Utilities within each module.

Below two documents posted in this directory provide additional information besides what is already documented in readme.md files:

- [**SqlToSynapseMigrationOverview.pdf**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/blob/main/Migration/SQLServer/SqlToSynapseMigrationOverview.pdf) - Overview of the SQL Server to Synapse Migration Modules. This presentation is intended for communication to key stakeholders. 
- [**SqlToSynapseMigration_User_Guide.pdf**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/blob/main/Migration/SQLServer/SqlToSynapseMigration_User_Guide.pdf) - User Guide that provides additional information. This document may not include information on recently enhancement modules yet. Please refer to the readme page of each module for detailed guide .

Within each module (subfolder in this directory), there is a README.md file to guide you through the usage and configuration files for the particular module. 

### **What does the Migration Utilities do?** 

The PowerShell Scripts performs below functions: 

1. Translate SQL Server Table DDLs into Azure Synapse DDLs using module 1.
1.  Extract Code DDLs (Views, Functions, Stored Procedures, and Triggers), Map Databases and Schemas, and produce Azure Synapse Code, using module 1A **and** 1B. 
2. **Execute Translated Translated Code** in Azure Synapse using module 5. 
3. Export SQL Server Data into .csv or .parquet files using module 2 or module 2B, respectively. 
4. Generate Polybase Export T-SQL Scripts using module 2A. 
5. **Execute Generated Polybase Export Scripts** using module 5, this will export SQL tables and store the data in Azure Storage (blob or adls).
6. Upload Exported Data into Azure Data Lake Store (or Blob Storage) if using module 2 or 2B. 
7. Generate T-SQL Copy Import Scripts for various file formats, including .csv or .parquet. 
8. **Execute T-SQL Copy Import Scripts** to Import Data into Azure Synapse using module 5. <u>Data is imported into Azure Synapse Tables from Azure Storage after this step</u>.

### **What are in the Migration Utilities?** 

There are nine modules that contain PowerShell Scripts designed to accomplish key tasks that are relevant to SQL server to Azure Synapse migration. **For code conversion and execution**, you can use modules 1, 1A, 1B, and 5. To export tables into local files (.csv or .parquet), you can use Modules 2 or 2B. For Polybase export, you can use Modules 2A. Module 5 is reused in multiple tasks as it is designed as an all-purpose T-SQL code execution utility. 

The modules are summarized as below:

**[1_TranslateTableDDLs](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/1_TranslateTableDDLs)**: Translate SQL Table objects from SQL Server format to Azure Synapse format. The output is stored as Create Table .sql files in specified file folder. This module provides the template for you to optimize the Azure Synapse Analytics table designs. 

**[1A_ExtractCodeDDLs](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/1A_ExtractCodeDDLs)**: Script out SQL Objects (Views, Functions, Stored Procedures, and Triggers) and write each object into a separate .sql file.  

**[1B_MapDatabasesAndSchemas](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/1B_MapDatabasesAndSchemas)**: Map SQL Server Database & Schema into Synapse Database and Schema. In addition, unsupported data types in the code are mostly discovered and counted. 

[**2_ExportSourceDataWithBCP**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/2_ExportSourceDataWithBCP): Export SQL Server Tables into data files in delimited text format (.csv or .txt).  

[**2B_ExportSourceDataToParquet**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/2B_ExportSourceDataToParquet): Export SQL Server Tables into data files in parquet format (.parquet).  

**[2A_GeneratePolybaseExportScripts](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/2A_GeneratePolybaseExportScripts)**:  Generate Polybase Export T-SQL Script for each table in the table list (configurable).  Polybase export set up examples are provided in subfolder “Utilities” inside this module. 

[**3_LoadDataIntoAzureStorage**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/3_LoadDataIntoAzureStorage): Load exported data files into specified container in Azure Storage (Blob Storage or Azure Data Lake Store).

[**4_GenerateCopyIntoScripts**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/4_GenerateCopyIntoScripts): Generate “COPY Into” T-SQL Scripts, once executed, will copy data from Azure Storage into Azure Synapse Dedicated SQL Pool tables.

[**5_RunSqlFilesInFolder**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/tree/main/Migration/SQLServer/5_RunSqlFilesInFolder): Run all T-SQL Scripts defined in .sql files stored in a specified file folder. The T-SQL Scripts can be DDL, DML, Data Movement Scripts (such as Copy Into scripts or Polybase Export Scripts), or any other scripts such as create/update statistics or indexes. In fact, this module is designed to run any SQL scripts in a folder. 

### Migration Option 1: Export Tables into .CSV or .Parquet files (Works with All Versions of SQL Server) 

If using this option, you will need to use **modules 1, 2, 3, 4, 5, for .csv file format**, or **module 1, 2B, 3, 4, 5  for .parquet file format**. The overall tasks and flows are illustrated in the figure below. 

![BCP Option](images/Overview-All-Version-2022-Feb.jpg)

### **Migration Option 2: Use Polybase to Export SQL Server Data - Works SQL Server** 2016 or Later Versions

If using Polybase option, you will need to use Modules 1, 2A,  4, and 5. Module 3 is not needed as the Polybase method will load data directly to Azure Storage from SQL Server. The overall tasks and flows are illustrated in the figure below.

![Polybase Option](images/Overview-Polybase-2022-Feb.jpg)

### Reusability of  Module 3, 4, and 5 (for Netezza/Teradata/Exadata/etc. to Azure Synapse Migration)

Module 3, 4, 5 are reusable for other types of migrations, for example, Netezza or Teradata or Exadata or Oracle to Azure Synapse migrations. After the code is translated, and data is exported out of source systems, the rest of the tasks are the same. Therefore module 3-5 can be utilized for any of those migrations. 

