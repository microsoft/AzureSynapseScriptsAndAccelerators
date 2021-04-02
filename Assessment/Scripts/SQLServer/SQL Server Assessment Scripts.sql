-- object counts - DONE
SELECT type_desc AS TYPE, count(*) AS COUNT FROM sys.objects group by type_desc

-- data types - DONE
SELECT y.name, count(*) FROM sys.all_columns c
INNER JOIN sys.tables t on t.object_id = c.object_id
INNER JOIN sys.types y on y.system_type_id = c.system_type_id
AND t.type = 'U'
GROUP BY y.name

-- Table row counts - DONE
select s.name as [schema], t.name, sum(p.rows) as COUNT from sys.partitions p
INNER JOIN sys.tables t on t.object_id = p.object_id
INNER JOIN sys.schemas s on s.schema_id = t.schema_id
AND t.type = 'U' 
AND p.index_id IN (0,1)
GROUP BY t.name, s.name
ORDER BY 3 DESC

-- Space used - DONE
SELECT DB_NAME() AS DbName, 
    name AS FileName, 
    type_desc,
    size/128.0 AS CurrentSizeMB,  
    size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB
FROM sys.database_files
WHERE type IN (0,1);

-- Database Information - DONE
SELECT name, compatibility_level,collation_name,snapshot_isolation_state_desc,
	recovery_model_desc,is_broker_enabled,is_cdc_enabled,is_encrypted 
FROM sys.databases WHERE name = DB_NAME()

-- Users  - DONE
SELECT name, islogin, isapprole, issqlrole, issqluser, isntgroup, isntname, isntuser FROM sys.sysusers

-- Remote Logins - DONE
SELECT remoteusername, status FROM sys.sysremotelogins

-- Full text indexes - DONE
SELECT name,status,path FROM sys.sysfulltextcatalogs

-- Schemas - DONE
SELECT name
  FROM sys.schemas
  WHERE schema_id < 16384
  AND name not in ('guest','INFORMATION_SCHEMA','sys')

-- Assemblies - DONE
SELECT * FROM sys.assemblies

-- In Memory Object Count - DONE
SELECT t.name, s.name, count(*) AS COUNT 
FROM sys.dm_db_xtp_table_memory_stats m
INNER JOIN sys.tables t on t.object_id = m.object_id
INNER JOIN sys.schemas s on s.schema_id = t.schema_id
GROUP BY t.name,s.name

-- Partitioned Tables Count - DONE
SELECT s.name, t.name, count(*)+1 as Partitions FROM sys.partitions p
INNER JOIN sys.tables t on t.object_id = p.object_id
INNER JOIN sys.schemas s on s.schema_id = t.schema_id
WHERE p.partition_number > 1
GROUP BY s.name, t.name

-- Service Broker Queues Count - DONE
SELECT name, type_desc, count(*) as COUNT 
FROM sys.service_queues 
WHERE is_ms_shipped <> 1
GROUP BY name, type_desc

-- Encrypted Columns - DONE
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

-- Masked Columns - DONE
SELECT s.name, t.name, c.name, definition, masking_function 
FROM sys.masked_columns c
INNER JOIN sys.tables t on t.object_id = c.object_id
INNER JOIN sys.schemas s on s.schema_id = t.schema_id

-- Store Procedure Row Counts - DONE
SELECT  o.type_desc AS ROUTINE_TYPE
       ,QUOTENAME(s.[name]) + '.' + QUOTENAME(o.[name]) AS [OBJECT_NAME]
       ,(LEN(m.definition) - LEN(REPLACE(m.definition, CHAR(10), ''))) AS LINES_OF_CODE
FROM    sys.sql_modules AS m
INNER JOIN sys.objects AS o
        ON m.[object_id] = o.[OBJECT_ID]
INNER JOIN sys.schemas AS s
        ON s.[schema_id] = o.[schema_id]

-- Replication Status - DONE
SELECT 
	name as [Database name],
	CASE is_published 
		WHEN 0 THEN 'No' 
		ELSE 'Yes' 
		END AS [Is Published],
	CASE is_merge_published 
		WHEN 0 THEN 'No' 
		ELSE 'Yes' 
		END AS [Is Merge Published],
	CASE is_distributor 
		WHEN 0 THEN 'No' 
		ELSE 'Yes' 
		END AS [Is Distributor],
	CASE is_subscribed 
		WHEN 0 THEN 'No' 
		ELSE 'Yes' 
		END AS [Is Subscribed]
FROM sys.databases
WHERE name = DB_NAME()

-- Files and Filegroups in Use - DONE
SELECT g.name 
	  ,f.[name]
      ,f.[type_desc]
      ,[is_default]
      ,f.[is_read_only]
      ,[is_autogrow_all_files]
  FROM sys.master_files f
  LEFT OUTER JOIN sys.filegroups g ON g.data_space_id = f.data_space_id

-- External Data Sources - DONE
SELECT [name]
      ,[location]
      ,[type_desc]
      ,[database_name]
  FROM sys.external_data_sources

-- Availability Groups - DONE
SELECT [name]
      ,[version]
      ,[basic_features]
      ,[db_failover]
      ,[is_distributed]
      ,[cluster_type_desc]
  FROM sys.availability_groups

-- Change Tracking - DONE
SELECT t.name
      ,[is_track_columns_updated_on]
      ,[min_valid_version]
      ,[begin_version]
      ,[cleanup_version]
  FROM sys.change_tracking_tables c
  INNER JOIN sys.tables	t on t.object_id = c.object_id

-- Check Constraints - DONE
SELECT t.name, s.name, c.name
      ,c.type_desc
      ,c.definition
  FROM sys.check_constraints c
  INNER JOIN sys.tables	t on t.object_id = c.parent_object_id
  INNER JOIN sys.schemas s on s.schema_id = c.schema_id

-- Computed Columns - DONE
SELECT t.name, s.name, c.name, c.definition FROM sys.computed_columns c
INNER JOIN sys.tables t on t.object_id = c.object_id
INNER JOIN sys.schemas s on s.schema_id = t.schema_id
WHERE t.type = 'U'

-- Index Types Count - DONE
SELECT i.type_desc, is_primary_key, is_unique, count(*) as COUNT FROM sys.indexes i
INNER JOIN sys.tables t on t.object_id = i.object_id
WHERE t.type = 'U'
GROUP BY i.type_desc, is_primary_key, is_unique

-- XML Indexes Count - DONE
SELECT count(*)as 'XML INDEX COUNT' FROM sys.xml_indexes

-- Configuration Settings - DONE
SELECT *
  FROM sys.configurations

-- Host Operating System - DONE
SELECT [host_platform]
      ,[host_distribution]
      ,[host_release]
      ,[host_service_pack_level]
      ,[os_language_version]
  FROM sys.dm_os_host_info

-- Available Resources - DONE
SELECT [cpu_count]
      ,[socket_count]
      ,[cores_per_socket]
      ,[numa_node_count]
      ,[hyperthread_ratio]
      ,[physical_memory_kb]
      ,[virtual_memory_kb]
      ,[committed_kb]
      ,[committed_target_kb]
      ,[visible_target_kb]
      ,[affinity_type_desc]
  FROM sys.dm_os_sys_info
  
-- Temporal Tables - DONE
SELECT s.name, t.name, period_type_desc 
FROM sys.periods p
INNER JOIN sys.tables t ON t.object_id = p.object_id
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
-- DDL for Functions and Stored Procedures  
/*
SET NOCOUNT ON;
SET ROWCOUNT 0;
DECLARE @ObjectDef table(  
    id int identity(1,1) NOT NULL,  
    title nvarchar(255),  
    clause nvarchar(255));
DECLARE @RowsToProcess INT;
DECLARE @CurrentRow INT;
DECLARE @title NVARCHAR(255)=N'';
DECLARE @clause NVARCHAR(255)=N'';
DELETE FROM @ObjectDef;

INSERT INTO @ObjectDef (title, clause)
	SELECT '--Object Type: '+(type_desc COLLATE SQL_Latin1_General_CP1_CI_AS)+' Object Name:'+s.name+'.'+o.name,
		'SELECT OBJECT_DEFINITION (OBJECT_ID(N''['+s.name+'].['+o.name+']''));'
		FROM sys.objects o
		INNER JOIN sys.schemas s on s.schema_id = o.schema_id
		WHERE type NOT IN ('S', 'IT','C', 'D','F','PK','SO','TT','UQ','U','V', 'SQ')
		ORDER BY type;
SET @RowsToProcess=@@ROWCOUNT;

--SELECT * FROM @ObjectDef
SET @CurrentRow=0;
WHILE @CurrentRow<@RowsToProcess
BEGIN
    SET @CurrentRow=@CurrentRow+1;
    SELECT 
        @title=title,
		@clause=clause
        FROM @ObjectDef
        WHERE id=@CurrentRow;

	PRINT @title;
	EXECUTE sp_executesql @clause

END;
*/