/***************************************************************************************************
Create Date:        08-28-2020
Author:             Casey Karst MSFT
Description:        This query runs returns metadata regarding CCI health. The results are split by partition to provide a 
					granular understanding of the health of your index. 

					0 - UNKNOWN_UPGRADED_FROM_PREVIOUS_VERSION: Occurred when upgrading from the previous version of SQL Server.

- NO_TRIM: The row group was not trimmed. The row group was compressed with the maximum of 1,048,476 rows. The number of rows could be less if a subset of rows was deleted after delta rowgroup was closed

- BULKLOAD: The bulk-load batch size limited the number of rows.

- REORG: Forced compression as part of REORG command.

- DICTIONARY_SIZE: Dictionary size grew too large to compress all of the rows together.

- MEMORY_LIMITATION: Not enough available memory to compress all the rows together.

- RESIDUAL_ROW_GROUP: Closed as part of last row group with rows < 1 million during index build operation

- AUTO_MERGE: A Tuple Mover merge operation running in the background consolidated one or more rowgroups into this rowgroup.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
08-20-2020          Casey Karst			Added       
***************************************************************************************************/
 SELECT

	    DB_Name()                                                                AS [database_name]
,       s.name                                                                  AS [schema_name]
,       t.name                                                                  AS [table_name]
,        rg.[partition_number]                                                  AS [table_partition]
,       SUM(rg.[total_rows])                                                    AS [row_count_total]
,       SUM(rg.[total_rows])/COUNT(DISTINCT rg.[distribution_id])               AS [row_count_per_distribution_MAX]
,       CEILING    ((SUM(rg.[total_rows])*1.0/COUNT(DISTINCT rg.[distribution_id]))/1048576) AS [rowgroup_per_distribution_MAX]
,       SUM(CASE WHEN rg.[State] = 1 THEN 1                   ELSE 0    END)    AS [OPEN_rowgroup_count]
,       SUM(CASE WHEN rg.[State] = 1 THEN rg.[total_rows]     ELSE 0    END)    AS [OPEN_rowgroup_rows]
,       MIN(CASE WHEN rg.[State] = 1 THEN rg.[total_rows]     ELSE NULL END)    AS [OPEN_rowgroup_rows_MIN]
,       MAX(CASE WHEN rg.[State] = 1 THEN rg.[total_rows]     ELSE NULL END)    AS [OPEN_rowgroup_rows_MAX]
,       AVG(CASE WHEN rg.[State] = 1 THEN rg.[total_rows]     ELSE NULL END)    AS [OPEN_rowgroup_rows_AVG]
,       SUM(CASE WHEN rg.[State] = 3 THEN 1                   ELSE 0    END)    AS [COMPRESSED_rowgroup_count]
,       SUM(CASE WHEN rg.[State] = 3 THEN rg.[total_rows]     ELSE 0    END)    AS [COMPRESSED_rowgroup_rows]
,       SUM(CASE WHEN rg.[State] = 3 THEN rg.[deleted_rows]   ELSE 0    END)    AS [COMPRESSED_rowgroup_rows_DELETED]
,       MIN(CASE WHEN rg.[State] = 3 THEN rg.[total_rows]     ELSE NULL END)    AS [COMPRESSED_rowgroup_rows_MIN]
,       MAX(CASE WHEN rg.[State] = 3 THEN rg.[total_rows]     ELSE NULL END)    AS [COMPRESSED_rowgroup_rows_MAX]
,       AVG(CASE WHEN rg.[State] = 3 THEN rg.[total_rows]     ELSE NULL END)    AS [COMPRESSED_rowgroup_rows_AVG]
,       SUM(CASE WHEN  rg.[State] = 3 and TRIM_REASON_DESC = 'NO_TRIM' THEN 1 ELSE 0 END)  No_trim_Compressed_row_Groups 
,       SUM(CASE WHEN  rg.[State] = 3 and TRIM_REASON_DESC = 'BULKLOAD'THEN 1  ELSE 0 END)  BulkLoad_trim_Compressed_row_Groups 
,       SUM(CASE WHEN  rg.[State] = 3 and TRIM_REASON_DESC = 'DICTIONARY_SIZE'THEN 1  ELSE 0 END)  Dictionary_Size_trim_Compressed_row_Groups 
,       SUM(CASE WHEN  rg.[State] = 3 and TRIM_REASON_DESC = 'MEMORY_LIMITATION' THEN 1 ELSE 0 END)  Memory_limit_trim_Compressed_row_Groups 
,       SUM(CASE WHEN  rg.[State] = 3 and TRIM_REASON_DESC = 'REORG'THEN 1  ELSE 0 END)  Reorg_trim_Compressed_row_Groups 
,       SUM(CASE WHEN  rg.[State] = 3 and TRIM_REASON_DESC = 'RESIDUAL_ROW_GROUP'THEN 1  ELSE 0 END)  RESIDUAL_ROW_GROUP_trim_Compressed_row_Groups 
,       SUM(CASE WHEN  rg.[State] = 3 and TRIM_REASON_DESC = 'Auto_Merge'THEN 1  ELSE 0 END)  Auto_Merge_trim_Compressed_row_Groups 
--,       'ALTER INDEX ALL ON ' + s.name + '.' + t.NAME + ' REBUILD;'             AS [Rebuild_Index_SQL]
FROM    sys.[pdw_nodes_column_store_row_groups] rg
JOIN    sys.[pdw_nodes_tables] nt                   ON  rg.[object_id]          = nt.[object_id]
                                                    AND rg.[pdw_node_id]        = nt.[pdw_node_id]
                                                    AND rg.[distribution_id]    = nt.[distribution_id]
JOIN    sys.[pdw_permanent_table_mappings] mp                 ON  nt.[name]               = mp.[physical_name]
JOIN    sys.[tables] t                              ON  mp.[object_id]          = t.[object_id]
JOIN    sys.[schemas] s                             ON t.[schema_id]            = s.[schema_id]
JOIN    sys.[dm_pdw_nodes_db_column_store_row_group_physical_stats] RGP      ON  RGP.[object_id]     = nt.[object_id]
                                                                            AND RGP.[pdw_node_id]   = nt.[pdw_node_id]
                                        AND RGP.[distribution_id]    = nt.[distribution_id]
GROUP BY
        s.[name]
,       t.[name]
, rg.[partition_number] 
order by schema_name, Table_name, Table_partition
