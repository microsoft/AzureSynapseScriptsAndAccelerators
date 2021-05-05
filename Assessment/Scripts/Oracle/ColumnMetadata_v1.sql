select OWNER as Schema_Name,table_name,column_name,data_type,
data_length,char_length,'' as identity_column,data_default,'' as collation 
from ALL_TAB_COLUMNS 
where OWNER NOT IN ('SYS', 'SYSTEM', 'ANONYMOUS', 'CTXSYS', 'DBSNMP', 'LBACSYS', 'MDSYS', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SCOTT', 'WKSYS', 'WMSYS', 'XDB', 
 'DVSYS', 'EXFSYS', 'MGMT_VIEW', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'SYSMAN', 'WKSYS', 'WKPROXY', 'AUDSYS', 'GSMADMIN_INTERNAL', 'DBSFWUSER', 'OJVMSYS', 'APPQOSSYS', 'REMOTE_SCHEDULER_AGENT', 'DVF', 'ORACLE_OCM', 'PUBLIC');