SELECT sess.sid,
       sess.username,
       sqla.optimizer_mode,
       sqla.hash_value,
       sqla.address,
       sqla.cpu_time,
       sqla.elapsed_time,
       sqla.sql_text
  FROM v$sqlarea sqla, v$session sess
 WHERE sess.sql_hash_value = sqla.hash_value
   AND sess.sql_address = sqla.address 
ORDER BY sess.username;