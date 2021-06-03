# **Overview** 

This directory contains SQL server to Azure Synapse Migration Toolkit (Process, PowerShell Scripts Modules, and some useful Utilities).

These two documents posted in this directory provide detailed information to help you to get started:

- SqlToSynapseMigrationOverview.pptx - Overview of the SQL Server to Synapse Migration Scripts in Five Modules.
- SqlToSynapseMigration_User_Guide_V1.0.pdf - Detailed User Guide that not only includes most of the information in the SqlToSynapseMigrationOverview.pptx, but also has detailed reference materials for each PowerShell Script (Module). It describes each configuration file parameter with sample values. This will probably be the only document you need to guide you through SQL server to Synapse migration project. 

**What does the Migration Utilities do?** 

The set of PowerShell Scripts performs below functions: 

1. Translate SQL Server Table DDLs into Azure Synapse DDLs
2. Execute Translated Table DDLs in Azure Synapse (Code Migration) 
3. Export SQL Server Data Via BCP (Option 1, for all SQL Servers)
4. Generate Polybase Export T-SQL Scripts for Polybase Export (Option 2, for SQL Server 2016 or later)
5. Export SQL Server Data Via Polybase (Execute Generated Polybase Export Scripts)
6. Upload Exported Data into Azure Data Lake Store (or Blob Storage)
7. Generate T-SQL Copy Import Scripts 
8. Execute T-SQL Copy Import Scripts to Import Data into Azure Synapse 

**What are in the Migration Utilities?** 

There are six modules that contain PowerShell Scripts and T-SQL Scripts designed to accomplish key task(s) that are relevant to SQL server to Azure Synapse migration. For BCP export, you will need Modules 1, 2, 3, 4, 5. For Polybase export, you will only need to use Modules 1, 2A, 4, and 5. Module 5 is reused in multiple tasks. 

The six modules are summarized as below:

**1_TranslateMetaData**: Translate SQL objects (DDLs) from source system format to Azure Synapse format. The output is stored as .sql files in specified file folder (configurable). 

**2_ExportSourceData**: Export SQL Server Tables into data files stored in predefined structure and format (.csv). 

**2A_GeneragePolybaseExportScripts**: Generate Polybase Export T-SQL Script for each table. Polybase export set up examples are provided in subfolder “Utilities” inside this module. 

**3_LoadDataIntoAzureStorage**: Load exported data files into specified container in Azure Storage (Blob Storage or Azure Data Lake Store).

**4_GenerateCopyIntoScripts**: Generate “COPY Into” T-SQL Scripts that will move data from Azure Storage into Azure Synapse SQL Pool tables, once executed.

**5_RunSqlFilesInFolder**: Run all T-SQL Scripts defined in .sql files stored in a specified file folder. The T-SQL Scripts can be DDL, DML, Data Movement Scripts (such as Copy Into scripts or Polybase Export Scripts), or any other scripts such as create/update statistics or indexes. In fact, this module is designed to run any SQL scripts in a folder. 





