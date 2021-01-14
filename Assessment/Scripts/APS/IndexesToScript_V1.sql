Declare @OutputDir varchar(max)= '##CreateMPPScriptsPath##' 

Select '1' as Active, db_name() as DatabaseName, s.name as SchemaName, 
@OutputDir + '\' + db_name() + '\Indexes\'  as OutputFolderPath,
s.name + '_' + o.name + '_' + idx.name as FileName,
s.name + '.' + o.name + '.' + convert(varchar,idx.name) as 'ObjectName', 'INDEX' as ObjectsToScript 
from sys.objects o
inner join sys.schemas s on o.schema_id = s.schema_id
inner join sys.databases d on d.name = db_name()  and o.type_desc = 'USER_TABLE'
inner join sys.indexes idx on idx.object_id = o.object_id and idx.type_desc = 'NONCLUSTERED'