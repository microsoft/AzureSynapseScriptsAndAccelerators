SELECT SYS_CONTEXT ('USERENV','DB_NAME') AS INSTANCE_NAME, 
	OWNER AS SCHEMA_NAME, 
	OBJECT_NAME, 
	OBJECT_TYPE 
	,SYS_CONTEXT ('USERENV','DB_NAME') || OWNER AS ROWKEY
FROM DBA_OBJECTS 
WHERE OBJECT_TYPE='FUNCTION' 
	and OWNER NOT IN ('SYS', 'SYSTEM', 'ANONYMOUS', 'CTXSYS', 'DBSNMP', 'LBACSYS', 'MDSYS', 'OLAPSYS', 
		'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SCOTT', 'WKSYS', 'WMSYS', 'XDB',   'DVSYS', 'EXFSYS', 'MGMT_VIEW', 
		'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'SYSMAN', 'WKSYS', 'WKPROXY', 'AUDSYS', 'GSMADMIN_INTERNAL', 'DBSFWUSER', 
		'OJVMSYS', 'APPQOSSYS', 'REMOTE_SCHEDULER_AGENT', 'DVF', 'ORACLE_OCM');
