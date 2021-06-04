# **Overview** 

This directory contains SQL server to Azure Synapse Migration Toolkit. It includes the Process, PowerShell Scripts Modules, and some useful Utilities within each module.

These two documents posted in this directory provide detailed information to help you to get started:

- **SqlToSynapseMigrationOverview.pptx (.pdf)** - Overview of the SQL Server to Synapse Migration Scripts in Six Modules. It also provides step by step guide for exporting SQL Server data using BCP (Bulk Copy Program) or Polybase. Please note that Polybase is only available for SQL server 2016 or later versions.  
- **SqlToSynapseMigration_User_Guide_V1.0.pdf** - Detailed User Guide that not only includes most of the information in the SqlToSynapseMigrationOverview.pptx (.pdf), but also has detailed reference materials for each PowerShell Script (Module). It describes each configuration file parameters with sample values.

In addition, within each module (subfolder in this directory), there is a README.md file to guide you through the usage and configuration files for the particular module. 

### **What does the Migration Utilities do?** 

The set of PowerShell Scripts performs below functions: 

1. Translate SQL Server Table DDLs into Azure Synapse DDLs.
2. **Execute Translated Table DDLs** in Azure Synapse (DDLs Migrated after this task).
3. Export SQL Server Data Via BCP to local storage <u>(BCP Data Export Option, for all SQL Servers, data exported to local storage after this task)</u>.
4. Generate Polybase Export T-SQL Scripts <u>(Polybase Data Export Option, for SQL Server 2016 or later)</u>.
5. **Execute Generated Polybase Export Scripts** <u>(Data exported to Azure Storage after this task)</u>.
6. Upload Exported Data into Azure Data Lake Store (or Blob Storage) if using BCP Export Option.
7. Generate T-SQL Copy Import Scripts. 
8. **Execute T-SQL Copy Import Scripts** to Import Data into Azure Synapse <u>(Data is imported into Azure Synapse Tables from Azure Storage after this step)</u>.

### **What are in the Migration Utilities?** 

There are six modules that contain PowerShell Scripts and T-SQL Scripts designed to accomplish key tasks that are relevant to SQL server to Azure Synapse migration. For BCP export, you will need Modules 1, 2, 3, 4, and 5. For Polybase export, you will only need to use Modules 1, 2A, 4, and 5. Module 5 is reused in multiple tasks as it is designed as an all-purpose T-SQL code execution utility. 

The six modules are summarized as below:

**1_TranslateMetaData**: Translate SQL objects (DDLs) from SQL Server format to target system Azure Synapse format. The output is stored as .sql files in your specified file folder. 

**2_ExportSourceData**: Export SQL Server Tables into data files stored in delimited text format (.csv or .txt).  

**2A_GeneratePolybaseExportScripts**: Generate Polybase Export T-SQL Script for each table in the table list (configurable).  Polybase export set up examples are provided in subfolder “Utilities” inside this module. 

**3_LoadDataIntoAzureStorage**: Load exported data files into specified container in Azure Storage (Blob Storage or Azure Data Lake Store).

**4_GenerateCopyIntoScripts**: Generate “COPY Into” T-SQL Scripts, once executed, will move data from Azure Storage into Azure Synapse SQL Pool tables.

**5_RunSqlFilesInFolder**: Run all T-SQL Scripts defined in .sql files stored in a specified file folder. The T-SQL Scripts can be DDL, DML, Data Movement Scripts (such as Copy Into scripts or Polybase Export Scripts), or any other scripts such as create/update statistics or indexes. In fact, this module is designed to run any SQL scripts in a folder. 

### **Why do we need These Scripts when we already have Azure Synapse Pathway**? 

These Scripts are complementary to Azure Synapse Pathway (ASP). ASP does not perform data migration today (as of June 2021). We designed and implemented 6 modules to complete the end-to-end tasks of tables migration and data migration (using BCP or Polybase Export). Please check the latest release of Azure Synapse Pathway for more advanced SQL Server code translation capabilities. 

<u>You can use scripts described in this document (Module 5_RunSqlFilesInFolder) to execute all translated code by ASP or other methods.</u> Please check the newest release of Azure Synapse Pathway so you can use the best available functions. [sql-docs/azure-synapse-pathway-overview.md at live · ](https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/tools/synapse-pathway/azure-synapse-pathway-overview.md)[MicrosoftDocs](https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/tools/synapse-pathway/azure-synapse-pathway-overview.md)[/](https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/tools/synapse-pathway/azure-synapse-pathway-overview.md)[sql](https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/tools/synapse-pathway/azure-synapse-pathway-overview.md)[-docs (github.com)](https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/tools/synapse-pathway/azure-synapse-pathway-overview.md).

In addition, Module 3, 4, 5 are reusable for other types of migrations, for example, Netezza or Teradata or Exadata or Oracle to Azure Synapse migrations. After the code is translated, and data is exported out of source systems, the rest of the tasks are the same. Therefore module 3-5 can be utilized for any of those migrations. 

