select owner as schema_name, object_type, count(*) from dba_objects 
where owner NOT IN ('SYS', 'SYSTEM', 'ANONYMOUS', 'CTXSYS', 'DBSNMP', 'LBACSYS', 'MDSYS', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SCOTT', 'WKSYS', 'WMSYS', 'XDB', 
'DVSYS', 'EXFSYS', 'MGMT_VIEW', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'SYSMAN', 'WKSYS', 'WKPROXY', 'AUDSYS', 'GSMADMIN_INTERNAL', 'DBSFWUSER', 'OJVMSYS', 'APPQOSSYS', 'REMOTE_SCHEDULER_AGENT', 'DVF', 'ORACLE_OCM', 'PUBLIC')
 group by owner, object_type order by owner;