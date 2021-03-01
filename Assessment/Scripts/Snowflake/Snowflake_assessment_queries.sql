-- Get information on databases in warehouse. Provides information
-- on all databases in warehouse.
select * from information_schema.databases;

-- Get information on schemas within database. 
-- NOTE: Remaining queries return information only for the current database
select * from information_schema.schemata;

-- Get information on tables in database
select * from information_schema.tables where table_schema not in ('INFORMATION_SCHEMA');

-- Get information on storage metrics for tables
select * from information_schema.table_storage_metrics;

-- Get information on table constraints
select * from information_schema.table_constraints;

-- Get information on referential constraints
select * from information_schema.referential_constraints;

-- Get information on views within database
select * from information_schema.views where table_schema not in ('INFORMATION_SCHEMA');

-- Get information on the table columns
select * from information_schema.columns where table_schema not in ('INFORMATION_SCHEMA');

-- Get information on any sequences
select * from information_schema.sequences;

-- Get information on any stored procedures
select * from information_schema.procedures;

-- Get information on any functions
select * from information_schema.functions;

-- Retrieve information on external data sources
select * from information_schema.stages;
select * from information_schema.load_history;
select * from information_schema.file_formats;
select * from information_schema.pipes;

-- Retrieve the roles and permissions
select * from information_schema.object_privileges;
select * from information_schema.applicable_roles;
select * from information_schema.enabled_roles;
select * from information_schema.external_tables;
select * from information_schema.table_privileges;
select * from information_schema.usage_privileges;

-- Get DDL for the database
-- Replace <db_name> with name of database
select GET_DDL('database','<db_name>') as <db_name>_schema;

-- Get Query History over last 6 days
select * from table(information_schema.query_history(
    end_time_range_start=>dateadd(d,-6,current_timestamp),
    end_time_range_end=>current_timestamp));

-- Show any notification, security and storage integrations
show integrations;

-- Show materialized views
show materialized views;

-- Show replicated databases
show replication databases;

-- Show Warehouse details
show warehouses;

-- Show Masking Policies
show masking policies;

-- Show any network policies
show network policies;

-- Show any defined tasks
show tasks;

-- Show any defined streams
show streams;