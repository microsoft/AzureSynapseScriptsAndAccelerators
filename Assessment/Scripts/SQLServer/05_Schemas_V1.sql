-- Query for: 5. Schemas

    SELECT name
  FROM sys.schemas
  WHERE schema_id < 16384
  AND name not in ('guest','INFORMATION_SCHEMA','sys')
    

