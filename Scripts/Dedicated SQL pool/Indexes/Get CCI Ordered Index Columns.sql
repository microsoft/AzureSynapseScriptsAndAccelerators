/***************************************************************************************************
Create Date:        08-24-2020
Author:             Casey Karst MSFT
Description:        This query runs against the USER DB and returns tables with ordered CCI indexes 
					and its columns and their ordinal position.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
08-20-2020          Casey Karst			Added      
***************************************************************************************************/
SELECT 
       object_schema_name(c.object_id) as schema_name,
	   object_name(c.object_id) table_name, 
	   c.name column_name, 
	   i.column_store_order_ordinal 
FROM sys.index_columns i 
JOIN sys.columns c ON i.object_id = c.object_id AND c.column_id = i.column_id

WHERE column_store_order_ordinal <>0
 order by 1, 3

