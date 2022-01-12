--
-- Db2 Discovery
-- Version 0.2
--
-- Tested on IBM DB2 version 10.5 on AIX
--
-- DIRECTIONS:
-- To run script, use the following command using the 'db2' command:
--
-- Where 'db2output.csv' is the name of the output file
-- 'DB2_Discovery_Script_Master_v0.2' is the name of the input script
--
-- [db2user@host ~]$ db2 -txf DB2_Discovery_Script_Master_v0.2.sql -z db2output1.csv
--
;
select
	trim(e.OS_NAME) CONCAT ',' CONCAT
	trim(e.HOST_NAME) CONCAT ',' CONCAT
	trim(i.INST_NAME) CONCAT ',' CONCAT
	trim(i.SERVICE_LEVEL) CONCAT ',' CONCAT
	trim((SELECT CURRENT SERVER FROM SYSIBM.SYSDUMMY1)) CONCAT ',' CONCAT
	trim(v.TABSCHEMA) CONCAT ',' CONCAT 'Data Type '
	CONCAT v.typename CONCAT ',' CONCAT
	COALESCE(count(v.typename), 1) CONCAT ','

from syscat.columns as v, TABLE(SYSPROC.ENV_GET_SYS_INFO()) as e, TABLE(SYSPROC.ENV_GET_INST_INFO()) as i
group by e.OS_NAME, i.SERVICE_LEVEL, i.INST_NAME, e.HOST_NAME, v.TABSCHEMA, v.typename 

UNION ALL
--
-- TABLE PARTITIONS
--

select
	trim(e.OS_NAME) CONCAT ',' CONCAT
	trim(e.HOST_NAME) CONCAT ',' CONCAT
	trim(i.INST_NAME) CONCAT ',' CONCAT
	trim(i.SERVICE_LEVEL) CONCAT ',' CONCAT
	trim((SELECT CURRENT SERVER FROM SYSIBM.SYSDUMMY1)) CONCAT ',' CONCAT
	trim(v.TABSCHEMA) CONCAT ',' CONCAT	
	'TABLE PARTITION' CONCAT ',' CONCAT	
	COALESCE(count(v.TABNAME), 1)  CONCAT ','

from syscat.TABDETACHEDDEP as v, TABLE(SYSPROC.ENV_GET_SYS_INFO()) as e, TABLE(SYSPROC.ENV_GET_INST_INFO()) as i
group by e.OS_NAME, i.SERVICE_LEVEL, i.INST_NAME, e.HOST_NAME, v.TABSCHEMA

UNION ALL
 
--
-- All Objects available in System Tables - For Ex. - Tables, MQT, Views etc.
--

select
	trim(e.OS_NAME) CONCAT ',' CONCAT
	trim(e.HOST_NAME) CONCAT ',' CONCAT
	trim(i.INST_NAME) CONCAT ',' CONCAT
	trim(i.SERVICE_LEVEL) CONCAT ',' CONCAT
	trim((SELECT CURRENT SERVER FROM SYSIBM.SYSDUMMY1)) CONCAT ',' CONCAT
	trim(v.TABSCHEMA)  CONCAT ',' CONCAT
	case when v.TYPE = 'A' then 'ALIAS'
	     when v.TYPE = 'G' then 'TABLE - TEMPORARY'
	     when v.TYPE = 'H' then 'TABLE - HIERARCHY'
	     when v.TYPE = 'L' then 'TABLE - DETACHED'
	     when v.TYPE = 'N' then 'ALIAS - NICKNAME'
	     when v.TYPE = 'S' then 'TABLE - MATERIALIZED QUERY'
	     when v.TYPE = 'T' then 'TABLE'
	     when v.TYPE = 'U' then 'TABLE - TYPED'
	     when v.TYPE = 'V' then 'VIEW'
	     when v.TYPE = 'W' then 'VIEW - TYPED'
    else v.type
    end
	CONCAT ',' CONCAT COALESCE(count(v.TABNAME), 1) CONCAT ','

from syscat.tables as v, TABLE(SYSPROC.ENV_GET_SYS_INFO()) as e, TABLE(SYSPROC.ENV_GET_INST_INFO()) as i
group by e.OS_NAME, i.SERVICE_LEVEL, i.INST_NAME, e.HOST_NAME, v.TABSCHEMA, v.type

UNION ALL

--
-- INDEXES
--

select
	trim(e.OS_NAME) CONCAT ',' CONCAT
	trim(e.HOST_NAME) CONCAT ',' CONCAT
	trim(i.INST_NAME) CONCAT ',' CONCAT
	trim(i.SERVICE_LEVEL) CONCAT ',' CONCAT
	trim((SELECT CURRENT SERVER FROM SYSIBM.SYSDUMMY1)) CONCAT ',' CONCAT
	trim(v.INDSCHEMA) CONCAT ',' CONCAT	
	'INDEX' CONCAT ',' CONCAT	
	COALESCE(count(v.INDNAME), 1) CONCAT ','

from syscat.indexes as v, TABLE(SYSPROC.ENV_GET_SYS_INFO()) as e, TABLE(SYSPROC.ENV_GET_INST_INFO()) as i
group by e.OS_NAME, i.SERVICE_LEVEL, i.INST_NAME, e.HOST_NAME, v.INDSCHEMA

UNION ALL

--
-- SEQUENCES
--

select
	trim(e.OS_NAME) CONCAT ',' CONCAT
	trim(e.HOST_NAME) CONCAT ',' CONCAT
	trim(i.INST_NAME) CONCAT ',' CONCAT
	trim(i.SERVICE_LEVEL) CONCAT ',' CONCAT
	trim((SELECT CURRENT SERVER FROM SYSIBM.SYSDUMMY1)) CONCAT ',' CONCAT
	trim(v.SEQSCHEMA) CONCAT ',' CONCAT
	'SEQUENCE' CONCAT ',' CONCAT
	COALESCE(count(v.SEQNAME), 1) CONCAT ','

from syscat.sequences as v, TABLE(SYSPROC.ENV_GET_SYS_INFO()) as e, TABLE(SYSPROC.ENV_GET_INST_INFO()) as i
group by e.OS_NAME, i.SERVICE_LEVEL, i.INST_NAME, e.HOST_NAME, v.SEQSCHEMA

UNION ALL

--
-- TRIGGERS
--

select
	trim(e.OS_NAME) CONCAT ',' CONCAT
	trim(e.HOST_NAME) CONCAT ',' CONCAT
	trim(i.INST_NAME) CONCAT ',' CONCAT
	trim(i.SERVICE_LEVEL) CONCAT ',' CONCAT
	trim((SELECT CURRENT SERVER FROM SYSIBM.SYSDUMMY1)) CONCAT ',' CONCAT
	trim(v.TRIGSCHEMA) CONCAT ',' CONCAT
	'TRIGGER' CONCAT ',' CONCAT
	COALESCE(count(v.TRIGNAME), 1) CONCAT ','
from syscat.triggers as v, TABLE(SYSPROC.ENV_GET_SYS_INFO()) as e, TABLE(SYSPROC.ENV_GET_INST_INFO()) as i
group by e.OS_NAME, i.SERVICE_LEVEL, i.INST_NAME, e.HOST_NAME, v.TRIGSCHEMA

UNION ALL

--
--  PROCEDURES, FUNCTIONS, METHODS
--

select
	trim(e.OS_NAME) CONCAT ',' CONCAT	
	trim(e.HOST_NAME) CONCAT ',' CONCAT
	trim(i.INST_NAME) CONCAT ',' CONCAT
	trim(i.SERVICE_LEVEL) CONCAT ',' CONCAT
	trim((SELECT CURRENT SERVER FROM SYSIBM.SYSDUMMY1)) CONCAT ',' CONCAT
	trim(v.ROUTINESCHEMA) CONCAT ',' CONCAT
	case when v.ROUTINETYPE = 'P' then 'PROCEDURE'
		 when v.ROUTINETYPE = 'F' then 'FUNCTION'
		 when v.ROUTINETYPE = 'M' then 'METHOD'
	end CONCAT ',' CONCAT
	COALESCE(count(v.ROUTINENAME), 1) CONCAT ','

from syscat.routines as v, TABLE(SYSPROC.ENV_GET_SYS_INFO()) as e, TABLE(SYSPROC.ENV_GET_INST_INFO()) as i
group by e.OS_NAME, i.SERVICE_LEVEL, i.INST_NAME, e.HOST_NAME, v.ROUTINESCHEMA, v.ROUTINETYPE;