 select
 SYS_CONTEXT ('USERENV','DB_NAME') AS INSTANCE_NAME, 
	ROUND(( select sum(bytes)/1024/1024/1024 data_size from sys.dba_data_files ) +
	( select nvl(sum(bytes),0)/1024/1024/1024 temp_size from sys.dba_temp_files ) +
	( select sum(bytes)/1024/1024/1024 redo_size from sys.v_$log ) +
	( select sum(BLOCK_SIZE*FILE_SIZE_BLKS)/1024/1024/1024 controlfile_size from v$controlfile),2) TOTAL_DB_SIZE_GB,
	ROUND(( select sum(bytes)/1024/1024/1024/1024 data_size from sys.dba_data_files ) +
	( select nvl(sum(bytes),0)/1024/1024/1024/1024 temp_size from sys.dba_temp_files ) +
	( select sum(bytes)/1024/1024/1024/1024 redo_size from sys.v_$log ) +
	( select sum(BLOCK_SIZE*FILE_SIZE_BLKS)/1024/1024/1024/1024 controlfile_size from v$controlfile),5) TOTAL_DB_SIZE_TB
from
dual;