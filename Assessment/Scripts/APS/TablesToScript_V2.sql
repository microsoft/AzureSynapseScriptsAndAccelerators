Declare @OutputDir varchar(max)= '##CreateMPPScriptsPath##' 

Select '1' as Active, db_name()  as DatabaseName, s.name as SchemaName, 
@OutputDir + '\' + db_name() + '\Tables\' as OutputFolderPath,
s.name + '_'+ t.name as FileName, 
s.name + '.'+ t.name as 'ObjectName', 'TABLE' as ObjectsToScript 
from sys.tables t 
inner join sys.schemas s 
on t.schema_id = s.schema_id 
inner join sys.databases d
on d.name = db_name()  and t.type_desc = 'USER_TABLE' 
and t.temporal_type_desc ='NON_TEMPORAL_TABLE' 
and t.object_id not in (select object_id from sys.external_tables)