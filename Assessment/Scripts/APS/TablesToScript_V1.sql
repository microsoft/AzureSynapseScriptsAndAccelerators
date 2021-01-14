Declare @ServerName varchar(50)= '10.222.333.XXX'
Declare @OutputDir varchar(50)= 'C:\APS2SQLDW\Output\1_CreateMPPScripts\' 

Select '1' as Active, @ServerName as ServerName, 
db_name()  as DatabaseName, s.name as SchemaName, 'DDL' as WorkMode,
@OutputDir + db_name() + '\Tables\' as OutputFolderPath,
s.name + '_'+ t.name as FileName, 'Full' as Mode, 
s.name + '.'+ t.name as 'ObjectName', 'TABLE' as ObjectsToScript 
from sys.tables t 
inner join sys.schemas s 
on t.schema_id = s.schema_id 
inner join sys.databases d
on d.name = db_name()  and t.type_desc = 'USER_TABLE' 
and t.temporal_type_desc ='NON_TEMPORAL_TABLE' 
and t.object_id not in (select object_id from sys.external_tables)