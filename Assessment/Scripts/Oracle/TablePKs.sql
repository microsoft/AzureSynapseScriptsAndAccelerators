SELECT
     INSTANCE_NAME,
     SCHEMA_NAME,
     TABLE_NAME, 
     COLUMN_NAME AS FIRST_COLUMN_NAME, 
     COLUMN_COUNT,
     ROWKEY
FROM (
  SELECT
     SYS_CONTEXT('USERENV','INSTANCE_NAME') AS INSTANCE_NAME,
     DBA_CONS_COLUMNS.OWNER AS SCHEMA_NAME,
     DBA_CONS_COLUMNS.TABLE_NAME, 
     DBA_CONS_COLUMNS.COLUMN_NAME, 
     DBA_CONS_COLUMNS.POSITION, 
     COUNT(DBA_CONS_COLUMNS.POSITION) OVER(PARTITION BY DBA_CONS_COLUMNS.OWNER, DBA_CONS_COLUMNS.TABLE_NAME) AS COLUMN_COUNT,
     SYS_CONTEXT('USERENV','INSTANCE_NAME') || DBA_CONS_COLUMNS.OWNER AS ROWKEY
  FROM DBA_CONSTRAINTS, DBA_CONS_COLUMNS 
  WHERE 
     DBA_CONSTRAINTS.CONSTRAINT_TYPE = 'P'
     AND DBA_CONSTRAINTS.STATUS = 'ENABLED'
     AND DBA_CONSTRAINTS.CONSTRAINT_NAME = DBA_CONS_COLUMNS.CONSTRAINT_NAME
     AND DBA_CONSTRAINTS.OWNER = DBA_CONS_COLUMNS.OWNER
)
WHERE POSITION = 1;