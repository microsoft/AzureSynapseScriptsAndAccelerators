-- Query for: 1. Object Counts

    
    SELECT schema_name(Schema_id) as 'schema', type_desc AS TYPE, count(*) AS COUNT FROM sys.objects group by type_desc, schema_name(Schema_id)
    

