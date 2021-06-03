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

--======================================================================================================================#
-- T-SQL Utilities that generage configuration files
-- Author: Gaiye "Gail" Zhou 
-- May 2021 
--======================================================================================================================#
--
--
--Declare @ServerName varchar(50) = @@SERVERNAME  -- not used anymore 
--

-- Capture the results and save it to SourceToTargetConfig.xslx 
-- Then modify a few fields such as Table Distribution and adding Hash Keys. 

--use AdventureWorksDW2017

Select '1' as Active, 
db_name()  as DatabaseName, 
s.name as SchemaName, 
'AsaDbName' as AsaDatabaseName,
s.name+'_asa' as AsaSchemaName,
t.name as ObjectName, 
'Table' as ObjectType,
'Yes' as DropFlag,
'CCI' as AsaTableType, -- Heap for Staging, CCI for target tables
'Round_Robin' as TableDistrubution, -- Modify results as needed 
'' as HashKeys
from sys.tables t 
inner join sys.schemas s 
on t.schema_id = s.schema_id 
inner join sys.databases d
on d.name = db_name()  and t.type_desc = 'USER_TABLE' 
and t.temporal_type_desc ='NON_TEMPORAL_TABLE' 
and t.object_id not in (select object_id from sys.external_tables)
-- if you want to specify tables:
and t.name in 
('DimAccount',
'DimCustomer', 
'DimDate', 
'DimGeography',
'DimReseller', 
'FactInternetSales',
'FactResellerSales',
'FactProductInventory',
'FactResellerSales'
 ) 
