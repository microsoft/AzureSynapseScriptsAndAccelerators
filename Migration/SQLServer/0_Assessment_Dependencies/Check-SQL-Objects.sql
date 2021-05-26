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


-- Tables
select count(*) from sys.tables where type_desc = 'USER_TABLE' 
select * from sys.tables where type_desc = 'USER_TABLE' 

-- Views
select * from sys.views where type_desc = 'VIWE' 

-- Stored Procedrues 
select s.name as schemaName, o.name as storedprocedureName
from sys.objects o
inner join sys.schemas s 
on o.schema_id = s.schema_id
inner join sys.databases d
on d.name = db_name()  and o.type_desc = 'SQL_STORED_PROCEDURE'
