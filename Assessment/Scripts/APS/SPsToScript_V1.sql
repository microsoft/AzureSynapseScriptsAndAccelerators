Declare @ServerName varchar(50)= '10.222.333.XXX' 
Declare @OutputDir varchar(50)= 'C:\APS2SQLDW\Output\1_CreateMPPScripts\' 

Select '1' as Active, @ServerName as ServerName, 
db_name() as DatabaseName, s.name as SchemaName, 'DML' as WorkMode,
@OutputDir + db_name() + '\SPs\'  as OutputFolderPath,
s.name + '_'+ o.name as FileName, 'Full' as Mode, 
s.name + '.'+ o.name as 'ObjectName', 'SP' as ObjectsToScript 
from sys.objects o
inner join sys.schemas s 
on o.schema_id = s.schema_id
inner join sys.databases d
on d.name = db_name()  and o.type_desc = 'SQL_STORED_PROCEDURE'