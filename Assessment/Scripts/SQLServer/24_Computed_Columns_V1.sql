-- Query for: 24. Computed Columns

    SELECT t.name as TableName, s.name as SchemaName, c.name as ColumnName, c.definition FROM sys.computed_columns c
INNER JOIN sys.tables t on t.object_id = c.object_id
INNER JOIN sys.schemas s on s.schema_id = t.schema_id
    

