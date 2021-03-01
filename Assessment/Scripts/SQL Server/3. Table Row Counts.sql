-- Query for: 3. Table Row Counts

    select s.name as [schema], t.name, sum(p.rows) as COUNT from sys.partitions p
    INNER JOIN sys.tables t on t.object_id = p.object_id
    INNER JOIN sys.schemas s on s.schema_id = t.schema_id
    AND t.type = 'U' 
    AND p.index_id IN (0,1)
    GROUP BY t.name, s.name
    ORDER BY 3 DESC
    

