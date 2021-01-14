Declare @OutputDir varchar(max)= '##CreateMPPScriptsPath##' 

select '1' as Active, db_name() as DatabaseName, '' SchemaName,
@OutputDir + '\' + db_name() + '\Roles\'  as OutputFolderPath,
principals.name as FileName, 
principals.name as 'ObjectName', 'ROLE' as ObjectsToScript 
from sys.database_principals principals
where is_fixed_role<>1 and principal_id<>0 and type_desc='DATABASE_ROLE'