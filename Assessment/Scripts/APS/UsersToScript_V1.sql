Declare @OutputDir varchar(max)= '##CreateMPPScriptsPath##' 

select '1' as Active, db_name() as DatabaseName, '' SchemaName,
@OutputDir + '\' + db_name() + '\Users\'  as OutputFolderPath,
principals.name as FileName, 
principals.name as 'ObjectName', 'USER' as ObjectsToScript 
from sys.database_principals principals
where is_fixed_role<>1 and principal_id<>0 and type_desc='SQL_USER'
	and name not in ('dbo', 'guest', 'sys', 'INFORMATION_SCHEMA')