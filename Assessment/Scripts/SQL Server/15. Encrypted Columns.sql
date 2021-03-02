-- Query for: 15. Encrypted Columns

    SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    k.name AS KeyName,
    c.encryption_type_desc,
    c.encryption_algorithm_name
FROM sys.columns c
    INNER JOIN sys.column_encryption_keys k ON c.column_encryption_key_id = k.column_encryption_key_id
    INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE encryption_type IS NOT NULL
    

