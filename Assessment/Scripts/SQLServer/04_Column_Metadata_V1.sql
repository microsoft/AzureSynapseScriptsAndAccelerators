
	 SELECT 
			schema_name(t.schema_id) as schema_name
			, t.name
			, c.name as columnName
			, y.name as Sys_DataType
			, u.name as User_datatype
			, Case when c.system_type_id <> c.user_type_id then 'User_Defined' else 'System' end
			, c.Column_id
			, c.Max_length
			, c.precision
			, c.Scale
			, c.Collation_name
			, c.is_nullable
			, is_Ansi_padded
			, is_RowGuidcol
			, is_identity
			, is_computed
			, is_filestream
			, c.is_replicated
			, is_non_sql_subscribed
			, c.is_merge_published
			, is_dts_replicated
			, is_xml_document
			, encryption_type_desc
			, column_encryption_key_id
			, column_encryption_key_database_name
			, is_hidden
			, is_masked
	FROM sys.all_columns c
    INNER JOIN sys.tables t on t.object_id = c.object_id
    INNER JOIN sys.types y on y.system_type_id = c.system_type_id
	inner join sys.types u on u.system_type_id = c.system_type_id
    AND t.type = 'U'