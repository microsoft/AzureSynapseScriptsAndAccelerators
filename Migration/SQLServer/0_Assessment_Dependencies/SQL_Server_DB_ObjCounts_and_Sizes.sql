--#======================================================================================================================#
--#                                                                                                                      #
--#  AzureSynapseScriptsAndAccelerators - PowerShell and T-SQL Utilities                                                 #
--#                                                                                                                      #
--#  This utility was developed to aid SMP/MPP migrations to Azure Synapse Migration Practitioners.                      #
--#  It is not an officially supported Microsoft application or tool.                                                    #
--#                                                                                                                      #
--#  The utility and any script outputs are provided on "AS IS" basis and                                                #
--#  there are no warranties, express or implied, including, but not limited to implied warranties of merchantability    #
--#  or fitness for a particular purpose.                                                                                #
--#                                                                                                                      #                    
--#  The utility is therefore not guaranteed to generate perfect code or output. The output needs carefully reviewed.    #
--#                                                                                                                      #
--#                                       USE AT YOUR OWN RISK.                                                          #
--#                                                                                                                      #
--#======================================================================================================================#

/***************************************************************************************/
/*           T-SQL Script to test important and relevant database information          */ 
/*                          Gaiye "Gail" Zhou, Architect                               */
/*                               May 2021                                              */
/***************************************************************************************/
-----------------------------------------------------------------------------------------
-- Important: This T-Scripts will create 'TempDB..#SQL_Assessment_Info_Temp_DB'
--            It will remove it in the end of the scritps. 
--            Please check your DB to see if you have a table with the same name 
-----------------------------------------------------------------------------------------
--
-- This T-Scripts Produces the following important information from SQL Server for each DB
--
-- (1) DbName - database name (exclude master, tempdb, msdb, model) 
-- (2) # of Tables in this database (1)
-- (3) # of Tables Tracked by CDC (1)
-- (4) # of External Tables in this database (1)
-- (5) # of Columns in this database (1) 
-- (6) # of Identity Columns in Tables, Views, and Stored Procedures 
-- (7) # of XML Columns in Tables, Views, and Stored Procedures 
-- (8) # of Stored Procedures 
-- (9) # of Views
-- (10) # of Triggers 
-- (11) # of Primary Key Constraints 
-- (12) # of Foreign Key Constraints
-- (13) # of Scalar Functions 
-- (14) # of Table Value Functions 
-- (15) # of Synonym Object
-- (16) # of Sequence Object
-- (17) # of Service Queue 
-- (18) DBSizeGB - Size of the DB in GB
-- (19) OthersGB - Size of Log, FILESTREA, FULLTEXT in GB
-- (20) DBSizeTB - Size of the DB in TB
-- (21) OthersTB - Size of Log, FILESTREA, FULLTEXT in TB

If Object_ID('Tempdb..#SQL_Assessment_Info_Temp_DB','U') IS NOT NULL Drop Table #SQL_Assessment_Info_Temp_DB

CREATE TABLE #SQL_Assessment_Info_Temp_DB (
  [DatabaseName] sysname, 
  [Tables] int, 
  [TblsTrkdByCDC] int,
  [ExtTbls] int,
  [Columns] int, 
  [IdentityColums] int,
  [XmlColums] int,
  [Procs] int, 
  [Views] int, 
  [Triggers] int,
  [PKeyConstraints] int,
  [FKeyConstraints] int,
  [ScalarFcns] int,
  [TblValueFcns] int,
  [Synonyms] int,
  [Sequences] int,
  [ServiceQs] int,
  [DBSizeGB] decimal (8,2),
  [OthersGB] decimal (8,2),
  [DBSizeTB] decimal (8,2),
  [OthersTB] decimal (8,2)
  ); 

DECLARE @SqlStmt NVARCHAR(MAX)
SELECT @SqlStmt = COALESCE(@SqlStmt,'') + 'USE ' + quotename(name) + '
Insert into #SQL_Assessment_Info_Temp_DB
Select ' + QUOTENAME(name,'''') + ', 
    (select count(*) from ' + QUOTENAME(Name) + '.sys.tables),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.tables' + ' where is_tracked_by_cdc = ''1''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.tables' + ' where is_external = ''1''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.columns),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.columns' + ' where is_identity = ''1''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.columns' + ' where is_xml_document = ''1''),
	(select count(*) from ' + QUOTENAME(Name) + '.sys.procedures),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.views),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.triggers),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.objects' + ' where type = ''PK''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.objects' + ' where type = ''F''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.objects' + ' where type_desc = ''SQL_SCALAR_FUNCTION''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.objects' + ' where type_desc = ''SQL_TABLE_VALUED_FUNCTION''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.objects' + ' where type = ''SN''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.objects' + ' where type = ''SO''),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.objects' + ' where type_desc = ''SERVICE_QUEUE''),
    (select (sum(convert(numeric,size))*8.0)/1024.0/1024.0 from sys.database_files where name like ' + QUOTENAME('%'+Name+'%','''') + ' and type_desc = ''ROWS''),
     (select (sum(convert(numeric,size))*8.0)/1024.0/1024.0 from sys.database_files where name like ' + QUOTENAME('%'+Name+'%','''') + ' and type_desc <> ''ROWS''),
    (select (sum(convert(numeric,size))*8.8)/1024.0/1024.0/1024.0 from sys.database_files where name like ' + QUOTENAME('%'+Name+'%','''') + ' and type_desc = ''ROWS''),
     (select (sum(convert(numeric,size))*8.8)/1024.0/1024.0/1024.0 from sys.database_files where name like ' + QUOTENAME('%'+Name+'%','''') + ' and type_desc <> ''ROWS'')
    '
FROM sys.databases 
where name not in ('master','tempdb','msdb','model') and state = 0 
ORDER BY name


--PRINT @SqlStmt 
EXECUTE(@SqlStmt)


Select * from #SQL_Assessment_Info_Temp_DB

If Object_ID('Tempdb..#SQL_Assessment_Info_Temp_DB','U') IS NOT NULL Drop Table #SQL_Assessment_Info_Temp_DB