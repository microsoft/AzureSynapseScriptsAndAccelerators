-- Query for: 25. Index Types

    SELECT i.type_desc, is_primary_key, is_unique, count(*) as COUNT FROM sys.indexes i
INNER JOIN sys.tables t on t.object_id = i.object_id
WHERE t.type = 'U'
GROUP BY i.type_desc, is_primary_key, is_unique
    

