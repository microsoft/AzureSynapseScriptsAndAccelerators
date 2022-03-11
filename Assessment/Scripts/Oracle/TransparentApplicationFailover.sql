select
   username,    sid,    serial#,    failover_type,    failover_method,    failed_over
from   v$session where    username not in ('SYS','SYSTEM','PERFSTAT')
and    failed_over = 'YES';