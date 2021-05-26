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

-- Please review the documentation for details: 
--https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-tables-data-types#:~:text=Workarounds%20for%20unsupported%20data%20types%20%20%20,%20%20varbinary%20%208%20more%20rows%20

-- Suggested Mapping:
-- geometry -> varbinary 
-- geography -> varbinary
-- hierarchyid -> nvarchar(4000) 
-- image -> varbinary 
-- text -> varchar 
-- ntext -> nvarchar
-- sql_variant -> Split column into several strongly typed columns.
-- table -> Convert to temporary tables.
-- timestamp -> Rework code to use datetime2 and the CURRENT_TIMESTAMP function.
--              Only constants are supported as defaults, so current_timestamp can't be defined as a default constraint. 
--              If you need to migrate row version values from a timestamp typed column, 
--              use BINARY(8) or VARBINARY(8) for NOT NULL or NULL row version values.
-- xml -> varchar
-- user-defined type --> Convert back to the native data type when possible.
-- default values --> Default values support literals and constants only.

SELECT  t.[name], c.[name], c.[system_type_id], c.[user_type_id], y.[is_user_defined], y.[name]
FROM sys.tables  t
JOIN sys.columns c on t.[object_id]    = c.[object_id]
JOIN sys.types   y on c.[user_type_id] = y.[user_type_id]
WHERE y.[name] IN ('varbinary','geography','geometry','hierarchyid','image','text','ntext','sql_variant','xml')
 AND  y.[is_user_defined] = 1;
 
 