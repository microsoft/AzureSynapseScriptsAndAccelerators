/***************************************************************************************************
Create Date:        08-20-2020
Author:             Casey Karst MSFT
Description:        This query runs against the USER DB and returns list of all Statistics objects, the Last time the object was updated
					, and if the stats object was user created
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
08-20-2020          Casey Karst			Added      
***************************************************************************************************/

SELECT
        sm.[name]                                                                AS [schema_name]
,        tb.[name]                                                               AS [table_name]
, co.name																	     AS [Column_Name]
,        st.[name]                                                               AS [stats_name]
,        st.[has_filter]                                                         AS [stats_is_filtered]
,       ROW_NUMBER()
        OVER(ORDER BY (SELECT NULL))                                             AS [seq_nmbr]
,                                 QUOTENAME(sm.[name])+'.'+QUOTENAME(tb.[name])  AS [two_part_name]
,        QUOTENAME(DB_NAME())+'.'+QUOTENAME(sm.[name])+'.'+QUOTENAME(tb.[name])  AS [three_part_name]
,  STATS_DATE(st.[object_id],st.[stats_id])   AS [stats_last_updated_date]
, st.[user_created] 
FROM    sys.objects            AS ob
JOIN    sys.stats              AS st    ON    ob.[object_id]        = st.[object_id]
JOIN    sys.stats_columns      AS sc    ON    st.[stats_id]        = sc.[stats_id]
                                          AND st.[object_id]        = sc.[object_id]
JOIN    sys.columns            AS co    ON    sc.[column_id]        = co.[column_id]
                                       AND    sc.[object_id]        = co.[object_id]
JOIN    sys.tables             AS tb    ON    co.[object_id]        = tb.[object_id]
JOIN    sys.schemas            AS sm    ON    tb.[schema_id]        = sm.[schema_id]
WHERE    1=1 and STATS_DATE(st.[object_id],st.[stats_id])   is not null
--AND        st.[user_created]   = 1