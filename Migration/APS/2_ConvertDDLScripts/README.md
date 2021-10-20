
# **2_ConvertDDLScripts:** Translates APS DDL scripts to Azure Synapse DDL scripts.

The program processing logic and information flow is illustrated in the diagram below:

![Convert DDL Scripts Programs](../Images/2_ConvertDDLScripts_v2.PNG)

## **What the Script Does** ##

The PowerShell script converts T-SQL scripts for APS objects to make them Azure Synapse compatible. This includes:

- Add default schema name if schema name is missing in object references
- Schema replacement based on schema mapping
- Fixing #TEMP table options, incl. REPLICATE-->ROUND_ROBIN



## **How to Run the Script** ##

Below are the steps to run the PowerShell script: 

1. **Step 2A:** Prepare configuration files.

- Schema mapping file [schemas.csv](schemas.csv). This configuration file defines how source APS databases/schemas will be mapped to target Synapse schemas.

| **Parameter** | **Purpose**                            | **Value (Sample)** |
| ------------- | -------------------------------------- | ------------------ |
| ApsDbName     | Name of APS Database                   | AdventureWorksDW   |
| ApsSchema     | Name of the schema in APS database     | dbo                |
| SynapseSchema | Name of the schema in Synapse database | aw                 |

- Create directories configuration CSV file [cs_dirs.csv](cs_dirs.csv). This configuration file defines:
  - source folders where APS DDL scripts are located 
  - target folders where converted scripts will be created. 

| **Parameter**    | **Purpose**                                                  | **Value  (Sample)**                                      |
| ---------------- | ------------------------------------------------------------ | -------------------------------------------------------- |
| Active           | 1 – Run  line, 0 – Skip line                                 | 0 or 1                                                   |
| ApsDatabasesName | The  name of APS database                                    | AdventureWorksDW                                         |
| SourceDirectory  | Directory  where the input source files that has APS schema names. This is the output  files from previous step. <br />*Both absolute and relative paths are supported.* | ..\Output\1_CreateDDLScripts\AdventureWorksDW\Tables     |
| TargetDirectory  | Output  directory of this step, where the scripts with new Synapse schemas will reside.<br />*Both absolute and relative paths are supported.* | ..\Output\2_ConvertDDLScripts\AdventureWorksDW\Tables    |
| DefaultSchema    | The  name of default schema for this database. <br />If schema name is missing in an object reference this default schema will be assumed. | dbo                                                      |
| ObjectType       | Type of  the object                                          | Table,  View, SP, Index, Statistic, Function, Role, User |

2. **Step 2B:** Run PowerShell script **ConvertDDLScriptsDriver.ps1** and enter prompted information or accept default values:
   - The path to configuration files
   - The name directories configuration file (default is cs_dirs.csv)
   - The name of schema mapping file (default is schemas.csv)



## Output ##

Sample script output:

![Sample Script Output](../Images/2_ConvertDDLScripts_Sample_Output.PNG)

Converted DDL scripts will be stored in Output folder. The scripts are structured based on source database name and object type.

![Output folder](../Images/2_ConvertDDLScripts_Output_Folder.PNG)
