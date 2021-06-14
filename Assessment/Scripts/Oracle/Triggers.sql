select SYS_CONTEXT ('USERENV','DB_NAME') AS INSTANCE_NAME,
	OWNER AS SCHEMA_NAME,
	TRIGGER_NAME,
	TRIGGER_TYPE,
	TRIGGERING_EVENT,
	TABLE_OWNER,
	BASE_OBJECT_TYPE,
	TABLE_NAME,
	COLUMN_NAME,
	SYS_CONTEXT ('USERENV','DB_NAME') || OWNER AS ROWKEY
from DBA_TRIGGERS 
WHERE OWNER NOT IN ('SYS', 'SYSTEM', 'ANONYMOUS', 'CTXSYS', 'DBSNMP', 'LBACSYS', 'MDSYS', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SCOTT', 'WKSYS', 'WMSYS', 'XDB', 
    'DVSYS', 'EXFSYS', 'MGMT_VIEW', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'SYSMAN', 'WKSYS', 'WKPROXY', 'AUDSYS', 'GSMADMIN_INTERNAL', 'DBSFWUSER', 'OJVMSYS', 'APPQOSSYS', 'REMOTE_SCHEDULER_AGENT', 'DVF', 'ORACLE_OCM')
;