-- Query for: 19. Files and Filegroups

    SELECT g.name 
	  ,f.[name]
      ,f.[type_desc]
      ,[is_default]
      ,f.[is_read_only]
      ,[is_autogrow_all_files]
  FROM sys.master_files f
  LEFT OUTER JOIN sys.filegroups g ON g.data_space_id = f.data_space_id
    

