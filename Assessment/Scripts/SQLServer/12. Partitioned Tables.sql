-- Query for: 12. Partitioned Tables

    SELECT s.name, t.name, count(*)+1 as Partitions FROM sys.partitions p
    INNER JOIN sys.tables t on t.object_id = p.object_id
    INNER JOIN sys.schemas s on s.schema_id = t.schema_id
    WHERE p.partition_number > 1
    GROUP BY s.name, t.name
    

