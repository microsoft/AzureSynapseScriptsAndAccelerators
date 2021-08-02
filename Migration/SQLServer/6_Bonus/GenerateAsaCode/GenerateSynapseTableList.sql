-----------------------------------------------------------------------
-- 
--Generate Starter Table List as Input for GenerateAsaScripts.ps1
-- Run against Azure Synaspe SQL Pool Database 
--
-- Augsut 2021
-----------------------------------------------------------------------
--
SELECT '1' as Active, 
-- SELECT distinct db_name() as DatabaseName, 
db_name() as DatabaseName, 
    s.name as SchemaName, 'staging' as StagingSchemaName,
    t.name as TableName, 
  tdp.distribution_policy_desc as CurrentDistributionType,
  CASE WHEN   cdp.distribution_ordinal=1 then c.name ELSE ' ' END as DistColumn,
  i.type_desc as StorageType,  
  --CASE WHEN count(p.rows)>1 THEN 'YES' ELSE 'NO' END as IsPartitioned,
  --count(p.rows) as NumPartitions,
  sum(p.rows) as NumRows,
  ' ' as DesiredDistributionType,
  ' ' as DistributionKeysIfHash,
  CASE WHEN cdp.distribution_ordinal=1 then c.name ELSE ' ' END as StatsColumns,
  CASE WHEN cdp.distribution_ordinal=1 then '100' ELSE ' ' END as StatsScanRate
  --, db_name() + '_' + s.name + '_' + t.name as row_key
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
     ON t.schema_id = s.schema_id
INNER JOIN sys.pdw_table_distribution_properties AS tdp 
    ON t.object_id = tdp.object_id
INNER JOIN sys.columns AS c 
    ON t.object_id = c.object_id
INNER JOIN sys.pdw_column_distribution_properties AS cdp 
    ON c.object_id = cdp.object_id AND c.column_id = cdp.column_id
--note rowcount from sys.partitions assumes stats are accurate. It does not get real numbers without accurate stats 
--to get stats from nodes use sys.pdw_nodes_partitions instead 
INNER JOIN sys.partitions p
 ON t.object_id = p.object_id
INNER JOIN sys.indexes i 
 ON  t.object_id = i.object_id
WHERE (tdp.distribution_policy_desc<>'HASH' or  cdp.distribution_ordinal=1) 
    AND (i.index_ID<2 and is_external = '0') 
    AND (t.object_id not in (select object_id from sys.external_tables)) 
    AND (t.is_external = '0') -- only internal tables 
    AND s.name not in ('staging') -- exclude schemas 
GROUP BY s.name, t.name, tdp.distribution_policy_desc, cdp.distribution_ordinal, c.name, i.type_desc, Is_external
 union 
SELECT '1' as Active, 
-- SELECT distinct db_name() as DatabaseName, 
 db_name() as DBName, 
 s.name as SchemaName, 'staging' as StagingSchemaName,
 t.name as TableName, '' as distribution_policy_desc,
	NULL as DistColumn,
	'HADOOP' StorageType,
	-- 'NO' as IsPartitioned,
	-- 0 as NumPartitions,
	0 as NumRows,
    ' ' as DesiredDistributionType,
    ' ' as DistributionKeysIfHash,
    ' ' StatsColumns,
    ' ' as StatsScanRate
--	, db_name() + '_' + s.name + '_' + t.name as row_key
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
     ON t.schema_id = s.schema_id
	 Where t.is_external = '1' -- external tables 
	 --exclude schemas here
	 and s.name not in ('staging') -- exclude schemas 
ORDER BY db_name(),S.name, t.name