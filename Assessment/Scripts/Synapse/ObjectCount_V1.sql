select db_name() as DBName, s.name as SchemaName ,  o.type_desc, count(1) as ObjectCount, db_name() + '_' + s.name as row_key
from sys.objects o
inner join sys.schemas s 
ON o.schema_id = s.schema_id
group by s.name, o.type_desc
UNION ALL
select db_name() as DBName, s.name as SchemaName ,  'STAT' as type_desc, count(1) as ObjectCount, db_name() + '_' + s.name as row_key
from sys.objects o
inner join sys.schemas s 
ON o.schema_id = s.schema_id
inner join sys.stats  ss
ON o.object_id = ss.object_id
group by  s.name
ORDER BY db_name(), s.name;