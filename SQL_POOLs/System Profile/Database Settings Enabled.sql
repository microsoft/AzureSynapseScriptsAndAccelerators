/***************************************************************************************************
Create Date:        08-20-2020
Author:             Casey Karst MSFT
Description:        This query runs against the USER DB and returns the name of the DB, Current SQL Pool Version, Compatibility level
					State (ONLINE or Paused). In addition to these properties, it returns whether the following features are turned on (0 for off 1 for on)
					- read_committed_Snapshot
					- Auto_Create_Stats
					- Query_Store
					- Result_Set_Caching
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
08-20-2020          Casey Karst			Added      
***************************************************************************************************/

SELECT name, 
	@@Version as [VERSION],
       Compatibility_level, 
	   State_desc, 
	   is_read_committed_Snapshot_on, 
	   is_auto_Create_Stats_on, 
	   is_query_Store_on, 
	   is_result_Set_caching_on
FROM sys.databases
