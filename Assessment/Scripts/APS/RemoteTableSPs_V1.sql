Declare @OutputDir varchar(max)= '##CreateMPPScriptsPath##' 

Select '1' as Active, db_name() as DatabaseName, s.name as SchemaName,
@OutputDir + '\' + db_name() + '\SPs\'  as OutputFolderPath,
s.name + '_'+ o.name as FileName, 
s.name + '.'+ o.name as 'ObjectName', 'SP' as ObjectsToScript 
from sys.objects o
inner join sys.schemas s on o.schema_id = s.schema_id
inner join sys.databases d on d.name = db_name() and o.type_desc = 'SQL_STORED_PROCEDURE'
inner join sys.sql_modules m on m.object_id = o.object_id and m.definition like '%CREATE REMOTE TABLE%'