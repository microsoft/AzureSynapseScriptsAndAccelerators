# **Module 1_TranslateMetaData** 

Use Module **1_TranslateMetaData** to Translate SQL Server Tables into Azure Synapse Tables and save them into target .sql files.  You don’t need to change GetTableMetaDataData.sql or TranslateTables.ps1.

You need to run **TranslateMetaData.ps1** which will prompt you for the names of two configuration files:

(1)  translate_config.json: This file specifies the SQL Server Name, Security setting, and Output files folder. 

(2)  SourceToTargetTablesConfig.xlsx. This file has a list of items that specify the SQL Server Database, Schema Name, Table Name, desired Synapse table Schema name, and table distribution. 

The definition and sample values for each row in **translate_config.json** file is described in below table:

| Parameter Name     | Description                                                  | Values (Sample)                                          |
| ------------------ | ------------------------------------------------------------ | -------------------------------------------------------- |
| ServerName         | Fully qualified SQL Server Name                              | .\\YourSQLServerName  or YourFullyQualifiedSqlServerName |
| IntegratedSecurity | YES or NO for IntegratedSecurity                             | YES or NO                                                |
| ThreePartsName     | YES or NO for Three-Parts-Name  code generation (db.schema.table) | YES or NO                                                |
| OutputFolder       | Full File Path where the  translated code will be stored.    | C:\\migratemaster\\output\\1_TranslateMetaData           |

The definition and sample values for each column in “**SourceToTargetTablesConfig.xlsx**” is described in below table:

| Parameter Name    | Description                                                  | Values (Sample)                                              |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Active            | 1 – Run line,  0 – Skip line.                                | 0 or 1                                                       |
| DatabaseName      | Database Name                                                | AdventureWorksDW2017                                         |
| SchemaName        | SQL Server Schema Name                                       | dbo                                                          |
| AsaDatabaseName   | Azure Synapse Database Name                                  | SynapseSQLPool (This field is not currently  used. It was planned for future use). |
| AsaSchemaName     | The schema name to be used in Azure Synapse  SQL pool        | dbo_asa, edw                                                 |
| ObjectName        | Table Name                                                   | DimEmployee                                                  |
| ObjectType        | Type of the SQL Object (Table, View, Stored  Procedure)      | Table                                                        |
| DropFlag          | YES or NO. If Yes, drop table statement will  be generated for Create Table DDL. | YES or NO.                                                   |
| AsaTableType      | Table types: Heap or CCI                                     | HEAP, CCI                                                    |
| TableDistrubution | Azure Synapse Table Distribution Type  (Round_Robin, Hash, Replicate). | Round_Robin, Replicate, Hash                                 |
| HashKeys          | Keys to be used as Hash keys. Defined this  field only if the table is to be distributed as Hash. | ProductKey. If multiple keys, they must be  separated by “,”. See the sample configuration file “SourceToTargetConfig.xlsx”  for more details. |

**In addition, in the subfolder named “Utilities”, we provided below utilities**

·     <u>Find_DB_Table_RowCounts.sql</u> – For each database connected, it returns the row count for each table. 

·     <u>GenerateSourceToTargetConfig.sql</u> – Run this against each SQL server database, it generates an initial starter configuration file that has the same structure as SourceToTargetTablesConfig.xlsx sample file. This will be to be used as input. 

·     <u>GetSqlSvrDatabaseObjectCountsAndSizes.sql</u> – For each dataset in the entire SQL server, it returns Database Size, #Tables, #Views, #Stored Procedures, #Triggers. 

·     <u>Module1-SQL-User-Permission.sq</u>l – Sample T-SQL script to set up permission for the migration user(s)

