-- Query for: 4. Data Types

    SELECT y.name, count(*) as COUNT FROM sys.all_columns c
    INNER JOIN sys.tables t on t.object_id = c.object_id
    INNER JOIN sys.types y on y.system_type_id = c.system_type_id
    AND t.type = 'U'
    GROUP BY y.name
    

