-- Query for: 12. Partitioned Tables


SELECT
s.Name AS SchemaName
, t.Name AS TableName
, p.rows AS RowCounts
, CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Used_MB
, CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2)) AS Unused_MB
, CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Total_MB
, CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2))/1024 AS Used_GB
, CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2))/1024 AS Unused_GB
, CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2))/1024 AS Total_GB
, CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2))/1024/1024 AS Used_TB
, CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2))/1024/1024 AS Unused_TB
, CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2))/1024/1024 AS Total_TB
, partition_number
, i.type_desc
, r.boundary_id
, r.value AS [Boundary Value] 
, Case when f.boundary_value_on_right = 1 then 'Right'
		when f.boundary_value_on_right = 1 then 'Left'
		else null end as Boundary_Range
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
Left JOIN  sys.partition_schemes AS ps ON i.data_space_id = ps.data_space_id  
Left JOIN sys.partition_functions AS f ON ps.function_id = f.function_id  
LEFT JOIN sys.partition_range_values AS r ON f.function_id = r.function_id and r.boundary_id = p.partition_number  
where i.type in (0, 1)
GROUP BY t.Name, s.Name, p.Rows, partition_number, i.type_desc, r.boundary_id, 
    r.value, f.boundary_value_on_right

    

