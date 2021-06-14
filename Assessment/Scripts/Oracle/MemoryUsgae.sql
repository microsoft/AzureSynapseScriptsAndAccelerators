select SYS_CONTEXT ('USERENV','DB_NAME') AS INSTANCE_NAME,
	value as MEMORYUSAGE
FROM v$pgastat 
where name='maximum PGA allocated';