The AssessmentFileDriver.json file is divide into several sections.

- General Configuration - Generic Configuration values necessary for all source systems
- APS Specific Configuration - APS Configuration values such as default DB and connection port
- Synapse Specific Configuration - Synapse Configuration values
- Netezza Specific Configuration - Netezza Configuration values such as connection port, default db and others info
- Teradata Specific Configuration
- SQLServer Specific Configuration
- SNOWFLAKE Specific Configuration
- Version Query – Query needed by each source system to retrieve the version of the system
- DB Listing Query – Query needed by each source system to retrieve a listing of all DB’s on the system.
- Table Listing Query – Query needed by each source system to retrieve a listing of all Tables with in a DB on the system.

**General Configuration:**
The values in the General Configuration section will need to change based on the location of the config files and the source system being assessed.

PreAssessmentDriverFile – Filename of the SQL csv config file.
PreAssessmentScriptPath – Location of the SQL CSV config file.
QueryTimeout – Length of time before the query should timeout if results have not been returned.
ConnectionTimeout – Length of time to wait on a connection to the source system to be made before timing out.
VerboseLogging - To enabled the additional logging.Be default is false
ValidSourceSystems – SQLServer, APS, SYNAPSE, TERADATA, NETEZZA, SNOWFLAKE

**APS Configuration:**
The values in the APS Configuration section that may need to change if connecting to APS or Synapse.

- Database : Default DB for APS/AzureDW. This should not be changed.
- Port : Port to use to connect to the APS/AzureDW.
- APS : 17001

**Synapse Configuration:**
- DatabaseEngineEdition : DB engine edition
- DatabaseEngineEditionQuery : Query to get the database engine edition

**Netezza Configuration:**
- Database : Default DB for Netezza. This should not be changed.
- Port : Port to use to connect to the Netezza.
- nzBinaryFolder : Location where the nz_ddl command needs to be executed from.
- SchemaExportFolder : Location on the Netezza Server to store the scripted DB files.

**Terdata Configuration:**
- Database : Default database for Teradata.
- Port : Port to use to connect to the Teradata
- ConnectionMethod : Authentication method to connect to Teradata

**SQLServer Configuration:**
- Database: Default database for SQLServer
- ConnectionMethod : Authentication method to connect to SQLServer

**SNOWFLAKE Configuration:**
- Database : Default database for Snowflake.
- Port : Port to use to connect to the Snowflake
- ConnectionMethod : Authentication method to connect to Snowflake

**Version Query Configuration:**

The query needed to return the version of the source system for each support system.

**DB Listing/Table Listing Query Configuration:**
The query needed to return a list to DB/Table Names on the source system. Should the query need to be changed from one version of the source system to the next, a new Object {} will need to be added to the file with a new from and to version and query.

- System – Source system to connect.
- VersionFrom – The beginning version of the source system to use the Query to obtain the results.
- VersionTo – The Last version of the source system to use the Query to obtain the results.
- Query – Query to run to obtain the desired results. DB Listing, Table Listing
