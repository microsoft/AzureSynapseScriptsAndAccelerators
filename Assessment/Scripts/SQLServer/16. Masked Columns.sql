-- Query for: 16. Masked Columns

    SELECT s.name, t.name, c.name, definition, masking_function 
    FROM sys.masked_columns c
    INNER JOIN sys.tables t on t.object_id = c.object_id
    INNER JOIN sys.schemas s on s.schema_id = t.schema_id
    

