## **AssessmentConfigFile.json file details**

| **Key**                      | **Purpose**                                                     | **Value   (Sample)**                                      |
| --------------------------| ------------------------------------------------------------ | ----------------------------------------------------- |
|PreAssessmentOutputPath    | To specify the output folder                       | Any valid folder name. **Ex:** Results                     |
|ServerName                 | To specify the source DB server details.This can be provided during execution as well| testapsserver.centralus.cloudapp.azure.com,17001|
|DSNName                    | Required field only for Teradata & Netezza. It is case sensitive.It requires DSN to be created locally on the local machine where the scripts are executed| TD |
|DBFilter                   | Required to filter the DBs to be assessed. Recommendation is to run it for all DBs(%) unless there is any specific restrictions for any DBs |testdb1,testdb2 or % - default |
|SourceSystem               | To specify the source system name from the supported sources.This can be provided during execution as well |  APS |
|ConnectionType             | To specify the authenticatype to connect to the source DB. This can be provided during execution as well | SQLAuth |
|StoreOutputInSeperateFolders|To specify how to store the results for multiple iterations of the assessment.By enabling this key creates separate folder for each execution |  True or False(default)|


## **AssessmentFileDriver.json file details**
This file holds the generic information about the source systems.Please refer [here](AssessmentDriver_config_details.md)

## **SQLScriptstoRun.csv file details**

Each source system has it's own SQLScriptstoRun.csv file located at scripts/<sourcesystem>/SQLScriptstoRun.csv
Example : APS is located at Scripts/APS/SQLScriptsToRun.csv(APS [SQLScriptstoRun.csv](../Scripts/APS/SQLScriptsToRun.csv)) 

Note: This file only needs to be edited if:

- Need to not collect a specific results of a single query.
- Need to Limit the results to a single DB.
- Need to add a query to the result set.
- Need to update a query to run on a specific version of the source system.


| Parameter    | Purpose                                                      | Value   (Sample)                                      |
| ------------ | ------------------------------------------------------------ | ----------------------------------------------------- |
| Active       | 1 – Run line, 0 – Skip line                                  | 0 or 1                                                |
| SourceSystem | Source system to connect to and run the Query against.       | <ul><li>Netezza</li><li>APS</li><li>SYNAPSE</li><li>SQLServer</li><li>TERADATA</li><li>SNOWFLAKE</li></ul> |
| RunFor       | <ul><li>DB = Run Query for each Database on the server</li><li>Server = Server level Query</li><li>Table = Run Query for each Table in each DB.</li></ul> | DB, Server, Table                                     |
| DB           | Limit the DB to a single DB                                  | Database name                                         |
| CommandType   | <ul>File name for the Command to run.</ul>          | SQL, DBCC, ScriptDB                                   |
| VersionFrom  | Each line is validated against the version of the DB.  As DB versions change, the Query may need to be changed for the given version or may not be valid on some version.  This the starting version that the line/query can be run on. | Depend on the source system                           |
| VersionTo    | This the Ending version that the line/query can be run on.   | Depend on the source system                           |
| ExportFileName | Name to use to save the results of the query to.  A Timestamp will be appended to the end of the field value.  “ShowSpaceUsedTotal_{TimeStamp}” | ShowSpaceUsedTotal                                                |
| ScriptName   | SQL statement to be run against the source system                |                                                       | \APS\ShowSpaceUsedTotal_V1.sql
