# **Overview** 

This page will be updated with more details. This directory contains SQL server to Azure Synapse Migration Toolkit (Process, PowerShell Scripts Modules, and some useful Utilities).

These two documents posted in this directory provide detailed information to help you to get started:

- SqlToSynapseMigrationOverview.pptx - Overview of the SQL Server to Synapse Migration Scripts in Five Modules.
- SqlToSynapseMigration_User_Guide_V1.0.pdf - Detailed User Guide that also includes most of the information in the SqlToSynapseMigrationOverview.pptx.

**What does the Migration Utilities do?** 

The set of PowerShell Scripts performs below functions: 

1. Translate SQL Server Table DDLs into Azure Synapse DDLs
2. Execute Translated Table DDLs in Azure Synapse (Code Migration) 
3. Export SQL Server Data
4. Upload Exported Data into Azure Data Lake Store (or Blob Storge)
5. Generate T-SQL Copy Import Scripts 
6. Execute T-SQL Copy Import Scripts to Import Data into Azure Synapse 

**What are in the Migration Utilities?** 

There are five modules that contain PowerShell Scripts and T-SQL Scripts designed to accomplish key task(s) that are relevant to SQL server to Azure Synapse migration. 

The five modules are summarized as below:

**1_TranslateMetaData**: Translate SQL objects (DDLs) from source system format to Azure Synapse format. The output is stored as .sql files in specified file folder (configurable). 

**2_ExportSourceData**: Export SQL Server Tables into data files stored in predefined structure and format (.csv). 

**3_LoadDataIntoAzureStorage**: Load exported data files into specified container in Azure Storage (Blob Storage or Azure Data Lake Store).

**4_GenerateCopyIntoScripts**: Generate “COPY Into” T-SQL Scripts that will move data from Azure Storage into Azure Synapse SQL Pool tables, once executed.

**5_RunSqlFilesInFolder**: Run all T-SQL Scripts defined in .sql files stored in a specified file folder. The T-SQL Scripts can be DDL, DML, Data Movement Scripts (such as Copy Into scripts), or any other scripts such as create/update statistics or indexes. In fact, this module is designed to run any SQL scripts in a folder. 

