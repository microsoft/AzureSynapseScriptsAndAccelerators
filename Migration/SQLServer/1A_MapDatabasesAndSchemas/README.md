
# **1A** Map Databases and Schemas 

**Please note**: Code in this folder is being developed / enhanced. 

## **What the Script Does** ##

The PowerShell script converts T-SQL scripts for SQL schema objects to make it Azure Synapse compatible. This includes:

- Add default schema name if schema name is missing in object references
- Schema replacement based on schema mapping

## **How to Run the Script** ##

Below are the steps to run the PowerShell script: 

**Step 2A:** Prepare configuration files.
- Schema mapping file [schemas.csv](schemas.csv)

| **Parameter**  | **Purpose**                                   | **Value (Sample)** |
| -------------- | --------------------------------------------- | ------------------ |
| SourceDatabase | Name of SQL Server Database                   | AdventureWorksDW   |
| SourceSchema   | Name of the schema for SourceDatabase         | dbo                |
| TargetDatabase | Name of the schema in Synapse database        | mySqlPoolDB        |
| TargetSchema   | Name of the schema in Synapse database schema | edw                |

- Create input and output directory configuration CSV file [cs_dirs.csv](cs_dirs.csv)

| **Parameter**    | **Purpose**                                                  | **Value  (Sample)**             |
| ---------------- | ------------------------------------------------------------ | ------------------------------- |
| Active           | 1 – Run  line, 0 – Skip line                                 | 0 or 1                          |
| ApsDatabasesName | The  name of SQL Server database                             | AdventureWorksDW                |
| SourceDirectory  | Directory  where the input source files that has SQL Server Code (Stored Procedures, Views, Functions) | C:\AdventureWorksDW\StoredProcs |
| TargetDirectory  | Output  directory of this step, where the scripts with new Synapse schemas will  reside | C:\SynapseCode\StoredProcs      |
| DefaultSchema    | if schema is missing from source code, specify the default schema name for the target database | dbo                             |
| ObjectType       | Type of the SQL Objects in the .sql files                    | Table, View, SP                 |

**Step 2B:** Run PowerShell script **MapDatabasesAndSchemas.ps1** with the prompted information.

