-- Query for: 11. In Memory Objects

    SELECT t.name, s.name, count(*) AS COUNT 
    FROM sys.dm_db_xtp_table_memory_stats m
    INNER JOIN sys.tables t on t.object_id = m.object_id
    INNER JOIN sys.schemas s on s.schema_id = t.schema_id
    GROUP BY t.name,s.name
    

