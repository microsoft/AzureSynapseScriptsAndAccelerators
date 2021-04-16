The Netezza Assessment scripts capture the following info:

- Version of the system – Version_{Datetime}.csv
- Count of all objects in all DB’s. - ObjectCount_{Datetime}.csv
- Size of each DB by MB, GB & TB. - DBSize_{Datetime}.csv
- Size of each table by MB, GB & TB. - TableSize_{Datetime}.csv
-  Returns a list of all the stored procedures and their attributes. - Procedure_{Datetime}.csv
-  Returns a list of all the Libraries and their attributes. - Library_{Datetime}.csv
-  Returns a list of all the Aggregates and their attributes. -  Aggregate_{Datetime}.csv
- Returns a list of all the Functions and their attributes. - Function_{Datetime}.csv
- Returns a list of tables and their attributes like: Distribution column, Distribution Type, Partition and  there attributes. – TableMetadata_{DateTime}.csv
- Returns a list of all the Sequence and their attributes.  - Sequence_{Datetime}.csv
- Unix Script used to script out the DB using NZ_DDL commands - ScriptNetezza_{Datetime}.csv