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

/*                                               
--======================================================================================================================#
T-SQL Utilities that finds #of rows in each table, for the database connected 
-- Author: Gaiye "Gail" Zhou 
-- April 2021 
--======================================================================================================================#
*/

Declare @Encoding varchar(10) = 'UTF8' 
--Declare @RowDelimiter varchar(4) = '' -- '0x1E' -- 30/0x1E  is ASCII row separator
Declare @RowDelimiter varchar(4) = '0x1E' -- '0x1E' -- 30/0x1E  is ASCII row separator
--Declare @ColumnDelimiter varchar(4) = '^|^' -- '0x1F' -- 31/0x1F  ASCII Field Delimieter. Other Option: 
Declare @ColumnDelimiter varchar(4) = '0x1F' -- '0x1F' -- 31/0x1F  ASCII Field Delimieter. Other Option: 
Declare @BatchSize int = 10000
Declare @UseCharDataType char(1) = '1' --'0' use char as storage type, '1' as nchar as storage type 
Declare @AutoCreateFileName char(1) = '0' -- '0' if you dont want timestamp as part of file name 

Select '1' as Active,
db_name()  as DatabaseName, 
s.name as SchemaName, 
t.name as TableName,
@Encoding as [Encoding],
'1' as UseQuery,
'Select * from ' + s.name + '.' + t.name as Query,
@RowDelimiter as RowDelimiter,
@ColumnDelimiter as ColumnDelimiter,
@BatchSize as 'BatchSize',
@UseCharDataType as UseCharDataType,
@AutoCreateFileName as AutoCreateFileName
from sys.tables t 
inner join sys.schemas s 
on t.schema_id = s.schema_id 
inner join sys.databases d
on d.name = db_name()  and t.type_desc = 'USER_TABLE' 
and t.temporal_type_desc ='NON_TEMPORAL_TABLE' 
and t.object_id not in (select object_id from sys.external_tables)
and s.name in ('dbo') 
and t.name in ('DimAccount','DimCustomer', 'DimDate', 'DimGeography','DimReseller', 'FactInternetSales') 
