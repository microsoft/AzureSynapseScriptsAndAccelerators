-- Query for: 29. Available Resources

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
    

