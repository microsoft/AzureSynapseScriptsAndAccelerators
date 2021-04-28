-- Query for: 22. Change Tracking
SELECT t.name as table_Name
	  , schema_Name(Schema_id) as schema_name
      ,[is_track_columns_updated_on]
      ,[min_valid_version]
      ,[begin_version]
      ,[cleanup_version]
  FROM sys.change_tracking_tables c
  INNER JOIN sys.tables	t on t.object_id = c.object_id
    

