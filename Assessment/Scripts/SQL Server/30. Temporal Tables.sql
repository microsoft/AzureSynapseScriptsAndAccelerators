-- Query for: 30. Temporal Tables

    SELECT s.name, t.name, period_type_desc 
FROM sys.periods p
INNER JOIN sys.tables t ON t.object_id = p.object_id
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    

