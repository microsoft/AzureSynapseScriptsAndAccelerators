-- This summarizes the tables with APPROXIMATE row counts and sizes on each distribution
		/*
		
		MODIFICATION LOG:
		11/15/19	T. Richter Jones
					Doubling of rowcounts and inaccurate storage values reported by users.
					1. When running on single node databases (i.e. <DWU1000)
						Modification made to select only COMPUTE nodes from dm_pdw_nodes. Failing to do this on single node databases
						resulted in data expansion.
					2. When NCI indexes exist
						a.	Modification made to also join on the index id. 
							Failure to do so results in data expansion equal to the number of additional indexes created 
							(i.e. 1 NC index = 2x the number of rows in row count and inaccurate storage sums)
						b.	Modified to include all indexes in temp table and reporting
					3. New columns available index_id and index_name
		2/6/2020	T. Richter Jones
					Added column object_id
		6/2020		Corrected skew computation to handle partitioned tables
		*/


if object_id('tempdb.dbo.#TableSizes') is not null
	drop table #TableSizes;

create table #TableSizes with (distribution=round_robin, heap) as
WITH base
AS
(
SELECT 
 GETDATE()                                                             AS  [execution_time]
, DB_NAME()                                                            AS  [database_name]
, s.name                                                               AS  [schema_name]
, t.name                                                               AS  [table_name]
, QUOTENAME(s.name)+'.'+QUOTENAME(t.name)                              AS  [two_part_name]
, nt.[name]                                                            AS  [node_table_name]
, ROW_NUMBER() OVER(PARTITION BY nt.[name] ORDER BY (SELECT NULL))     AS  [node_table_name_seq]
, tp.[distribution_policy_desc]                                        AS  [distribution_policy_name]
, c.[name]                                                             AS  [distribution_column]
, nt.[distribution_id]                                                 AS  [distribution_id]
, i.[index_id]                                                         AS  [index_id]
, i.[type]                                                             AS  [index_type]
, i.[type_desc]                                                        AS  [index_type_desc]
, i.[name]		                                                       AS  [index_name]
, nt.[pdw_node_id]                                                     AS  [pdw_node_id]
, pn.[type]                                                            AS  [pdw_node_type]
, pn.[name]                                                            AS  [pdw_node_name]
, di.name                                                              AS  [dist_name]
, di.position                                                          AS  [dist_position]
, nps.[partition_number]                                               AS  [partition_nmbr]
, nps.[reserved_page_count]                                            AS  [reserved_space_page_count]
, nps.[reserved_page_count] - nps.[used_page_count]                    AS  [unused_space_page_count]
, nps.[in_row_data_page_count] 
    + nps.[row_overflow_used_page_count] 
    + nps.[lob_used_page_count]                                        AS  [data_space_page_count]
, nps.[reserved_page_count] 
 - (nps.[reserved_page_count] - nps.[used_page_count]) 
 - ([in_row_data_page_count] 
         + [row_overflow_used_page_count]+[lob_used_page_count])       AS  [index_space_page_count]
, nps.[row_count]                                                      AS  [approx_row_count]
, t.[object_id]                                                        AS  [object_id]
from 
    sys.schemas s
INNER JOIN sys.tables t
    ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.indexes i
    ON  t.[object_id] = i.[object_id]
    --AND i.[index_id] <= 1					-- <= 1 will Report only on primary table storage (i.e. do not include in report any NCI)
INNER JOIN sys.pdw_table_distribution_properties tp
    ON t.[object_id] = tp.[object_id]
INNER JOIN sys.pdw_table_mappings tm
    ON t.[object_id] = tm.[object_id]
INNER JOIN sys.pdw_nodes_tables nt
    ON tm.[physical_name] = nt.[name]
INNER JOIN sys.dm_pdw_nodes pn
    ON  nt.[pdw_node_id] = pn.[pdw_node_id]
	  AND pn.[type] = 'COMPUTE' -- need to filter out all but the COMPUTE nodes for data table information 
-- this was causing doubling of size values reported by users when running on single node (< DWU1000) databases
INNER JOIN sys.pdw_distributions di
    ON  nt.[distribution_id] = di.[distribution_id]
INNER JOIN sys.dm_pdw_nodes_db_partition_stats nps
    ON nt.[object_id] = nps.[object_id]
    AND nt.[pdw_node_id] = nps.[pdw_node_id]
    AND i.[index_id] = nps.[index_id]				-- Need to also join on the index id.   
    AND nt.[distribution_id] = nps.[distribution_id]
LEFT OUTER JOIN (select * from sys.pdw_column_distribution_properties where distribution_ordinal = 1) cdp
    ON t.[object_id] = cdp.[object_id]
LEFT OUTER JOIN sys.columns c
    ON cdp.[object_id] = c.[object_id]
    AND cdp.[column_id] = c.[column_id]

--WHERE 1=1
--AND s.name LIKE 'Prod_SysRef%'
)
, size
AS
(
SELECT
   [execution_time]
,  [database_name]
,  [schema_name]
,  [table_name]
,  [two_part_name]
,  [node_table_name]
,  [node_table_name_seq]
,  [distribution_policy_name]
,  [distribution_column]
,  [distribution_id]
,  [index_id]
,  [index_type]
,  [index_type_desc]
,  [index_name]
,  [pdw_node_id]
,  [pdw_node_type]
,  [pdw_node_name]
,  [dist_name]
,  [dist_position]
,  [partition_nmbr]
,  [reserved_space_page_count]
,  [unused_space_page_count]
,  [data_space_page_count]
,  [index_space_page_count]
,  [approx_row_count]
--,  [object_id]
,  ([reserved_space_page_count] * 8.0)                                 AS [reserved_space_KB]
,  ([reserved_space_page_count] * 8.0)/1000                            AS [reserved_space_MB]
,  ([reserved_space_page_count] * 8.0)/1000000                         AS [reserved_space_GB]
,  ([reserved_space_page_count] * 8.0)/1000000000                      AS [reserved_space_TB]
,  ([unused_space_page_count]   * 8.0)                                 AS [unused_space_KB]
,  ([unused_space_page_count]   * 8.0)/1000                            AS [unused_space_MB]
,  ([unused_space_page_count]   * 8.0)/1000000                         AS [unused_space_GB]
,  ([unused_space_page_count]   * 8.0)/1000000000                      AS [unused_space_TB]
,  ([data_space_page_count]     * 8.0)                                 AS [data_space_KB]
,  ([data_space_page_count]     * 8.0)/1000                            AS [data_space_MB]
,  ([data_space_page_count]     * 8.0)/1000000                         AS [data_space_GB]
,  ([data_space_page_count]     * 8.0)/1000000000                      AS [data_space_TB]
,  ([index_space_page_count]  * 8.0)                                   AS [index_space_KB]
,  ([index_space_page_count]  * 8.0)/1000                              AS [index_space_MB]
,  ([index_space_page_count]  * 8.0)/1000000                           AS [index_space_GB]
,  ([index_space_page_count]  * 8.0)/1000000000                        AS [index_space_TB]
FROM base
)
SELECT * 
FROM size


option(label='DBCheck-#TableSizes');

GO

-- Table space summary
SELECT 'Table space summary';
SELECT 
     database_name
,    schema_name
,    table_name
,    distribution_policy_name
,      distribution_column
,    index_type_desc
,	 index_name
,    COUNT(distinct partition_nmbr) as nbr_partitions
,    SUM(approx_row_count)          as approx_table_row_count
,    SUM(reserved_space_GB)         as table_reserved_space_GB
,    SUM(data_space_GB)             as table_data_space_GB
,    SUM(index_space_GB)            as table_index_space_GB
,    SUM(unused_space_GB)           as table_unused_space_GB
FROM 
    dbo.#TableSizes
GROUP BY 
     database_name
,    schema_name
,    table_name
,    distribution_policy_name
,    distribution_column
,    index_type_desc
,    index_name
ORDER BY
    database_name
,    schema_name
,    table_name
,    distribution_policy_name
,    distribution_column
,    index_type_desc
,    index_name
	--table_reserved_space_GB desc
;


---- Table space by distribution type
--SELECT 'Table space by distribution type';
--SELECT 
--     distribution_policy_name
--,    SUM(approx_row_count)         as table_type_approx_row_count
--,    SUM(reserved_space_GB)        as table_type_reserved_space_GB
--,    SUM(data_space_GB)            as table_type_data_space_GB
--,    SUM(index_space_GB)           as table_type_index_space_GB
--,    SUM(unused_space_GB)          as table_type_unused_space_GB
--FROM dbo.#TableSizes
--WHERE index_id <= 1
--GROUP BY distribution_policy_name
--;

----Table space by index type
--SELECT 'Table space by index type';
--SELECT 
--     index_type_desc
--,    SUM(approx_row_count)         as table_type_approx_row_count
--,    SUM(reserved_space_GB)        as table_type_reserved_space_GB
--,    SUM(data_space_GB)            as table_type_data_space_GB
--,    SUM(index_space_GB)           as table_type_index_space_GB
--,    SUM(unused_space_GB)          as table_type_unused_space_GB
--FROM dbo.#TableSizes
--GROUP BY index_type_desc
--;

---- Distribution Space Summary
--SELECT 'Distribution Space Summary (Table storage)';
--SELECT 
--    distribution_id
--,    SUM(approx_row_count)         as total_node_distribution_approx_row_count
--,    SUM(reserved_space_MB)        as total_node_distribution_reserved_space_MB
--,    SUM(data_space_MB)            as total_node_distribution_data_space_MB
--,    SUM(index_space_MB)           as total_node_distribution_index_space_MB
--,    SUM(unused_space_MB)          as total_node_distribution_unused_space_MB
--FROM dbo.#TableSizes
--WHERE index_id <= 1
--GROUP BY    distribution_id
--ORDER BY    distribution_id
--;

-- Table space summary
--SELECT 'Table space summary - space by distribution';
--SELECT 
--     database_name
--,    schema_name
--,    table_name
--,   distribution_id
--,    SUM(approx_row_count)          as approx_table_row_count
--,    SUM(reserved_space_GB)         as table_reserved_space_GB
--,    SUM(data_space_GB)             as table_data_space_GB
--,    SUM(index_space_GB)            as table_index_space_GB
--,    SUM(unused_space_GB)           as table_unused_space_GB
--FROM 
--    dbo.#TableSizes
--GROUP BY 
--     database_name
--,    schema_name
--,    table_name
--,   distribution_id
--ORDER BY
--    database_name
--,    schema_name
--,    table_name
--,   distribution_id
--	--table_reserved_space_GB desc
--;

---- Table space summary
SELECT 'Table space summary - space by distribution/partition';
SELECT 
     database_name
,    schema_name
,    table_name
,   distribution_id
,	partition_nmbr
,    SUM(approx_row_count)          as approx_table_row_count
,    SUM(reserved_space_GB)         as table_reserved_space_GB
,    SUM(data_space_GB)             as table_data_space_GB
,    SUM(index_space_GB)            as table_index_space_GB
,    SUM(unused_space_GB)           as table_unused_space_GB
FROM 
    dbo.#TableSizes
GROUP BY 
     database_name
,    schema_name
,    table_name
,   distribution_id
,	partition_nmbr
ORDER BY
    database_name
,    schema_name
,    table_name
,   distribution_id
,	partition_nmbr
	--table_reserved_space_GB desc
;


--SELECT 'Distribution Space Summary (NCI storage)';
--SELECT 
--    distribution_id
--,    SUM(approx_row_count)         as total_node_distribution_approx_row_count
--,    SUM(reserved_space_MB)        as total_node_distribution_reserved_space_MB
--,    SUM(data_space_MB)            as total_node_distribution_data_space_MB
--,    SUM(index_space_MB)           as total_node_distribution_index_space_MB
--,    SUM(unused_space_MB)          as total_node_distribution_unused_space_MB
--FROM dbo.#TableSizes
--WHERE index_id > 1
--GROUP BY    distribution_id
--ORDER BY    distribution_id
--;

-- Table Skew
SELECT 'Find tables with > 10% skew';
select t.two_part_name,
[partition_nmbr],
	min(t.approx_row_count) as 'min approx_row_count',
	max(t.approx_row_count) as 'max approx_row_count',
	(max(t.approx_row_count * 1.000) - min(t.approx_row_count * 1.000))/max(t.approx_row_count * 1.000) as 'skew'
FROM
(SELECT
	two_part_name,
	distribution_id,
	[partition_nmbr],
	sum(approx_row_count) as 'approx_row_count'
   from dbo.#TableSizes
    where approx_row_count > 0
	and distribution_policy_name = 'HASH'
	and index_id <= 1
	--and two_part_name LIKE '%BIG_KAHUNA%'
    group by two_part_name, index_id, distribution_id,[partition_nmbr]) as t

group by two_part_name,[partition_nmbr]
   -- having (max(t.approx_row_count * 1.000) - min(t.approx_row_count * 1.000))/max(t.approx_row_count * 1.000) >= .10
order by 4

------SELECT 'Distribution details for those tables with > 10% skew'; --> DOES NOT WORK FOR PARTITIONED TABLES
----select 
----	database_name,
----	schema_name,
----	table_name,
----	distribution_policy_name,
----	Distribution_column,
----	distribution_id,
----[partition_nmbr],
----	index_type_desc,
----	approx_row_count
----from dbo.#TableSizes
----where two_part_name in
----    (
----    select two_part_name
----    from dbo.#TableSizes
----    where approx_row_count > 0
----	and distribution_policy_name = 'HASH'
----    and index_id <= 1
----    group by two_part_name, index_id
----    having (max(approx_row_count * 1.000) - min(approx_row_count * 1.000))/max(approx_row_count * 1.000) >= .10
----    )
----order by two_part_name, distribution_id, [partition_nmbr] --approx_row_count DESC
----;

--- CORRECTED for partitioned tables
--select 
--	database_name,
--	schema_name,
--	table_name,
--	distribution_policy_name,
--	Distribution_column,
--	distribution_id,
--[partition_nmbr],
--	index_type_desc,
--	approx_row_count
--from dbo.#TableSizes
--where two_part_name in
--    (
--		select t.two_part_name
--		FROM
--		(SELECT
--			two_part_name,
--			distribution_id,
--			sum(approx_row_count) as 'approx_row_count'
--			from dbo.#TableSizes
--			where approx_row_count > 0
--			and distribution_policy_name = 'HASH'
--			and index_id <= 1
--			--and two_part_name LIKE '%BIG_KAHUNA%'
--			group by two_part_name, index_id, distribution_id) as t

--		group by two_part_name
--			having (max(t.approx_row_count * 1.000) - min(t.approx_row_count * 1.000))/max(t.approx_row_count * 1.000) >= .10
--    )
--order by two_part_name, distribution_id, [partition_nmbr] --approx_row_count DESC
--;


------------------------------------------------------

---- running the stats off the CTE table 
--SELECT DISTINCT
--    sm.[name] AS [schema_name],
--    tb.[name] AS [table_name],
----    co.[name] AS [stats_column_name],
----    st.[name] AS [stats_name],
----	st.[user_created] AS [user_created],
----    STATS_DATE(st.[object_id],st.[stats_id]) AS [stats_last_updated_date]
----,	st.[stats_generation_method_desc]	AS [stats_generation_method_desc] 
--       'UPDATE STATISTICS ' + sm.[name] + '.' + tb.[name] + ' WITH FULLSCAN;'             AS [Update_Stats_SQL]

--FROM
--    sys.objects ob
--    JOIN sys.stats st
--        ON  ob.[object_id] = st.[object_id]
--    JOIN sys.stats_columns sc    
--        ON  st.[stats_id] = sc.[stats_id]
--        AND st.[object_id] = sc.[object_id]
--    JOIN sys.columns co    
--        ON  sc.[column_id] = co.[column_id]
--        AND sc.[object_id] = co.[object_id]
--    JOIN sys.types  ty    
--        ON  co.[user_type_id] = ty.[user_type_id]
--    JOIN sys.tables tb    
--        ON  co.[object_id] = tb.[object_id]
--    JOIN sys.schemas sm    
--        ON  tb.[schema_id] = sm.[schema_id]
--INNER JOIN #TableSizes AS tsize on tsize.object_id = ob.object_id
--WHERE 1=1
----AND st.[name] NOT LIKE '%ClusteredIndex_%'
----AND st.[user_created] = 1
--AND tsize.[approx_row_count] > 0

-- cleanup
--drop table #TableSizes;

