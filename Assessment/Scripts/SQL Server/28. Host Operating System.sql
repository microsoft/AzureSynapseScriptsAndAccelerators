-- Query for: 28. Host Operating System

    SELECT [host_platform]
      ,[host_distribution]
      ,[host_release]
      ,[host_service_pack_level]
      ,[os_language_version]
  FROM sys.dm_os_host_info
    

