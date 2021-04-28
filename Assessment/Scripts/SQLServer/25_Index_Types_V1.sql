-- Query for: 25. Index Types


    SELECT t.name as Table_Name, schema_name(Schema_id) as Schema_Name, i.type_desc, is_primary_key, is_unique
	FROM sys.indexes i
INNER JOIN sys.tables t on t.object_id = i.object_id
WHERE t.type = 'U'
    

