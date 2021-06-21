Select '1' as Active, db_name() as DatabaseName, s.name as SchemaName,
'\' + db_name() + '\Statistics\'  as OutputFolderPath,
s.name + '_' + o.name + '_' + stats.name as FileName,
s.name + '.' + o.name + '.' + stats.name as 'ObjectName', 'STAT' as ObjectsToScript 
from sys.objects o
inner join sys.schemas s on o.schema_id = s.schema_id
inner join sys.databases d on d.name = db_name()  and o.type_desc = 'USER_TABLE'
inner join sys.stats stats on stats.object_id = o.object_id and stats.user_created = 1