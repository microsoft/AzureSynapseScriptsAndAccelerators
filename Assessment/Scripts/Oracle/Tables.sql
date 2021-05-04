select t.owner As Schema_Name,t.table_name,t.partitioned,
sum(t.num_rows) as "RowCount",
round(sum(bytes)/1024/1024,4) as "Table Size (MB)",
round(sum(bytes)/1024/1024/1024,5) as "Table Size (GB)",
round(sum(bytes)/1024/1024/1024/1024,8) as "Table Size (TB)"
from dba_tables t,dba_segments s 
where t.owner=s.owner and t.table_name=s.segment_name and
t.OWNER NOT IN ('SYS', 'SYSTEM', 'ANONYMOUS', 'CTXSYS', 'DBSNMP', 'LBACSYS', 'MDSYS', 'OLAPSYS', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'SCOTT', 'WKSYS', 'WMSYS', 'XDB', 
 'DVSYS', 'EXFSYS', 'MGMT_VIEW', 'ORDDATA', 'OWBSYS', 'ORDPLUGINS', 'SYSMAN', 'WKSYS', 'WKPROXY', 'AUDSYS', 'GSMADMIN_INTERNAL', 'DBSFWUSER', 'OJVMSYS', 'APPQOSSYS', 'REMOTE_SCHEDULER_AGENT', 'DVF', 'ORACLE_OCM', 'PUBLIC')
group by t.owner,t.table_name,t.partitioned;