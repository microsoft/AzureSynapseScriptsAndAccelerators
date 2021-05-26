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
/*                               March 2020                                            */
/***************************************************************************************/
--
-- Run this script against each DB in SQL Server
--
--use AdventureWorks2017
SELECT distinct OBJECT_NAME(referencing_id) AS referencing_entity_name,   
    o.type_desc AS referencing_desciption, 
	@@SERVERNAME as referenced_server_name, 
	ISNULL(referenced_database_name, db_name()) AS referenced_database_name, 
	s.name as referencing_schema, 
    COALESCE(COL_NAME(referencing_id, referencing_minor_id), '(n/a)') AS referencing_minor_id,   
    referencing_class_desc,  
	ISNULL(referenced_schema_name, 'dbo') AS referenced_schema_name,
    referenced_entity_name
    --COALESCE(COL_NAME(referenced_id, referenced_minor_id), '(n/a)') AS referenced_column_name,  
    --is_caller_dependent, is_ambiguous  
FROM sys.sql_expression_dependencies AS sed  WITH(NOLOCK)
INNER JOIN sys.objects AS o WITH(NOLOCK) ON sed.referencing_id = o.object_id  
inner join sys.schemas s on o.schema_id = s.schema_id
where o.type_desc = 'SQL_STORED_PROCEDURE' or o.type_desc = 'VIEW' 

