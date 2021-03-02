-- Query for: 6. Database Information

    SELECT name, compatibility_level,collation_name,snapshot_isolation_state_desc,
	  recovery_model_desc,is_broker_enabled,is_cdc_enabled,is_encrypted 
    FROM sys.databases WHERE name = DB_NAME()
    

