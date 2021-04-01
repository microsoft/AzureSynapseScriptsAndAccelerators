SELECT distinct db_name() as DBName, s.name as SchemaName, t.name as TableName, Is_external
	, tdp.distribution_policy_desc,
  CASE WHEN   cdp.distribution_ordinal=1 then c.name ELSE NULL END as DistCol,
  i.type_desc as StorageType
,  CASE WHEN count(p.rows)>1 THEN 'YES' ELSE 'NO' END as IsPartitioned
,count(p.rows) as NumPartitions
, sum(p.rows) as NumRows
, db_name() + '_' + s.name + '_' + t.name as row_key
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
     ON t.schema_id = s.schema_id
INNER JOIN sys.pdw_table_distribution_properties AS tdp 
    ON t.object_id = tdp.object_id
INNER JOIN sys.columns AS c 
    ON t.object_id = c.object_id
INNER JOIN sys.pdw_column_distribution_properties AS cdp 
    ON c.object_id = cdp.object_id AND c.column_id = cdp.column_id
--note rowcount from sys.partitions assumes PDW stats are accurate
--to get stats from nodes use pdw_nodes_partitions instead 
INNER JOIN sys.partitions p
 ON t.object_id = p.object_id
INNER JOIN sys.indexes i 
 ON  t.object_id = i.object_id
WHERE (tdp.distribution_policy_desc<>'HASH' or  cdp.distribution_ordinal=1) AND
 i.index_ID<2 and is_external = '0'
GROUP BY s.name, t.name, tdp.distribution_policy_desc, cdp.distribution_ordinal, c.name, i.type_desc, Is_external
 union 
SELECT distinct db_name() as DBName, s.name as SchemaName, t.name as TableName, Is_external
	, '' as distribution_policy_desc
	, NULL as DistCol
	, 'HADOOP' StorageType
	, 'NO' as IsPartitioned
	, 0 as NumPartitions
	, 0 as NumRows
	, db_name() + '_' + s.name + '_' + t.name as row_key
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
     ON t.schema_id = s.schema_id
	 Where Is_External = '1'
ORDER BY db_name(),S.name, t.name