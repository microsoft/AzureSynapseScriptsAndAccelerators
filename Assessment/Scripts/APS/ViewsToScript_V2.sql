Declare @OutputDir varchar(max)= '##CreateMPPScriptsPath##' 

Select '1' as Active, db_name() as DatabaseName, s.name as SchemaName,
@OutputDir + db_name() + '\Views\' as OutputFolderPath,
s.name + '_'+ v.name as FileName, 
s.name + '.'+ v.name as 'ObjectName', 'VIEW' as ObjectsToScript 
from sys.views v
inner join sys.schemas s 
on v.schema_id = s.schema_id
inner join sys.databases d
on d.name = db_name() and v.type_desc = 'VIEW'