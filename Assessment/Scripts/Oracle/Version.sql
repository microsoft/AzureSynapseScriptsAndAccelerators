SELECT SYS_CONTEXT ('USERENV','DB_NAME') AS INSTANCE_NAME, 
	BANNER AS VERSION 
FROM V$VERSION;

