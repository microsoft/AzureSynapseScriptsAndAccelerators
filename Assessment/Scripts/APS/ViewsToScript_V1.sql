Declare @ServerName varchar(50)= '10.222.333.XXX'
Declare @OutputDir varchar(50)= 'C:\APS2SQLDW\Output\1_CreateMPPScripts\' 

Select '1' as Active, @ServerName as ServerName, 
db_name() as DatabaseName, s.name as SchemaName, 'DML' as WorkMode,
@OutputDir + db_name() + '\Views\' as OutputFolderPath,
s.name + '_'+ v.name as FileName, 'Full' as Mode, 
s.name + '.'+ v.name as 'ObjectName', 'VIEW' as ObjectsToScript 
from sys.views v
inner join sys.schemas s 
on v.schema_id = s.schema_id
inner join sys.databases d
on d.name = db_name() and v.type_desc = 'VIEW'