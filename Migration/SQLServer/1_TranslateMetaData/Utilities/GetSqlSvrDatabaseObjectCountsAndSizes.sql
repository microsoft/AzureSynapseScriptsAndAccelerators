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
/*                               April 2021                                            */
/***************************************************************************************/
-----------------------------------------------------------------------------------------
-- Important: This T-Scripts will create 'TempDB..#SQL_Assessment_Info_Temp_DB'
--            It will remove it in the end of the scritps. 
--            Please check your DB to see if you have a table with the same name 
-----------------------------------------------------------------------------------------
-- This T-Scripts Produces the following important information from SQL Server for each DB
-- (1) DbName - database name (exclude master, tempdb, msdb, model) 
-- (2) Tables - # of Tables in this database (1)
-- (3) Procedures - # of Stored Procedrues 
-- (4) Views - # of Views
-- (5) Triggers - # of Triggers 
-- (6) SizeMB - Size of the DB in MB
-- (7) SizeGB - Size of the DB in GB
-- (8) SizeTB - Size of the DB in TB 

If Object_ID('Tempdb..#SQL_Assessment_Info_Temp_DB','U') IS NOT NULL Drop Table #SQL_Assessment_Info_Temp_DB

CREATE TABLE #SQL_Assessment_Info_Temp_DB (
  [DbName] sysname, 
  [NTables] int, 
  [NProcedures] int, 
  [NViews] int, 
  [NTriggers] int,
  [SizeMB] decimal (18,2),
  [SizeGB] decimal (18,2),
  [SizeTB] decimal (18,2)
  ); 

DECLARE @SqlStmt NVARCHAR(MAX)
SELECT @SqlStmt = COALESCE(@SqlStmt,'') + 'USE ' + quotename(name) + '
Insert into #SQL_Assessment_Info_Temp_DB
Select ' + QUOTENAME(name,'''') + ', 
    (select count(*) from ' + QUOTENAME(Name) + '.sys.tables),
	(select count(*) from ' + QUOTENAME(Name) + '.sys.procedures),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.views),
    (select count(*) from ' + QUOTENAME(Name) + '.sys.triggers),
	(select (size*8)/1024.0 from sys.master_files where name = ' + QUOTENAME(Name,'''') + ' and type_desc = ''ROWS''),
	(select (size*8.0)/1024.0/1024.0 from sys.master_files where name = ' + QUOTENAME(Name,'''') + ' and type_desc = ''ROWS''),
	(select (size*8.8)/1024.0/1024.0/1024.0 from sys.master_files where name = ' + QUOTENAME(Name,'''') + ' and type_desc = ''ROWS'')
	'
FROM sys.databases 
where name not in ('master','tempdb','msdb','model') and state = 0 
ORDER BY name

--PRINT @SqlStmt 
EXECUTE(@SqlStmt)

Select * from #SQL_Assessment_Info_Temp_DB

If Object_ID('Tempdb..#SQL_Assessment_Info_Temp_DB','U') IS NOT NULL Drop Table #SQL_Assessment_Info_Temp_DB