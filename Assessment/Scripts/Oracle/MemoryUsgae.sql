select sys_context('USERENV','INSTANCE_NAME') AS INSTANCE_NAME,
	value as MEMORYUSAGE
FROM v$pgastat 
where name='maximum PGA allocated';