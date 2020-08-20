/***************************************************************************************************
Create Date:        08-20-2020
Author:             Casey Karst MSFT
Description:        This query runs against the USER DB and attributes about all tables (is external table, 
					Distribution of table, Distrubtion key, Dist Key Datatype, StorageType, Partition information,
					approximate number of rows.
					NOTE: Distribution value only supports single column distribution.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
08-20-2020          Casey Karst			Added      
***************************************************************************************************/
SELECT
  distinct db_name() as DBName,
  s.name as SchemaName,
  t.name as TableName,
  Is_external,
  tdp.distribution_policy_desc,
  CASE WHEN cdp.distribution_ordinal = 1 then c.name ELSE NULL END as DistCol,
  Case when cdp.distribution_ordinal = 1 then ty.Name ELSE NULL END as DistCOL_DataType,
  i.type_desc as StorageType,
  CASE WHEN count(p.rows) > 1 THEN 'YES' ELSE 'NO' END as IsPartitioned,
  count(p.rows) as NumPartitions,
  sum(p.rows) as NumRows,
  db_name() + '_' + s.name + '_' + t.name as row_key
FROM
  sys.tables AS t
  INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
  INNER JOIN sys.pdw_table_distribution_properties AS tdp ON t.object_id = tdp.object_id
  INNER JOIN sys.columns AS c ON t.object_id = c.object_id
  INNER join sys.types ty ON C.system_type_id = ty.system_type_id
  INNER JOIN sys.pdw_column_distribution_properties AS cdp ON c.object_id = cdp.object_id
  AND c.column_id = cdp.column_id --note rowcount from sys.partitions assumes PDW stats are accurate
  --to get stats from nodes use pdw_nodes_partitions instead
  INNER JOIN sys.partitions p ON t.object_id = p.object_id
  INNER JOIN sys.indexes i ON t.object_id = i.object_id
WHERE
  (
    tdp.distribution_policy_desc <> 'HASH'
    or cdp.distribution_ordinal = 1
  )
  AND i.index_ID < 2
  and is_external = '0'
GROUP BY
  s.name,
  t.name,
  tdp.distribution_policy_desc,
  cdp.distribution_ordinal,
  c.name,
  i.type_desc,
  Is_external,
  ty.Name
union
SELECT
  distinct db_name() as DBName,
  s.name as SchemaName,
  t.name as TableName,
  Is_external,
  '' as distribution_policy_desc,
  NULL AS DataType,
  NULL as DistCol,
  'HADOOP' StorageType,
  'NO' as IsPartitioned,
  0 as NumPartitions,
  0 as NumRows,
  db_name() + '_' + s.name + '_' + t.name as row_key
FROM
  sys.tables AS t
  INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
Where
  Is_External = '1'
ORDER BY
  db_name(),
  S.name,
  t.name
