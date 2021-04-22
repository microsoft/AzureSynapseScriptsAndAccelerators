select
( select sum(bytes)/1024/1024/1024 data_size from sys.dba_data_files ) +
( select nvl(sum(bytes),0)/1024/1024/1024 temp_size from sys.dba_temp_files ) +
( select sum(bytes)/1024/1024/1024 redo_size from sys.v_$log ) +
( select sum(BLOCK_SIZE*FILE_SIZE_BLKS)/1024/1024/1024 controlfile_size from v$controlfile) "Total DB Size (GB)"
from
dual;