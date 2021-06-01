SELECT SYS_CONTEXT('USERENV','INSTANCE_NAME') AS INSTANCE_NAME, 
	TO_CHAR(SAMPLE_TIME, 'HH24:MI ') AS SAMPLE_TIME,
	ROUND(OTHER / 720, 3) AS OTHER,
	ROUND(CLUST / 720, 3) AS CLUST,
	ROUND(QUEUEING / 720, 3) AS QUEUEING,
	ROUND(NETWORK / 720, 3) AS NETWORK,
	ROUND(ADMINISTRATIVE / 720, 3) AS ADMINISTRATIVE,
	ROUND(CONFIGURATION / 720, 3) AS CONFIGURATION,
	ROUND(COMMIT / 720, 3) AS COMMIT,
	ROUND(APPLICATION / 720, 3) AS APPLICATION,
	ROUND(CONCURRENCY / 720, 3) AS CONCURRENCY,
	ROUND(SIO / 720, 3) AS SYSTEM_IO,
	ROUND(UIO / 720, 3) AS USER_IO,
	ROUND(SCHEDULER / 720, 3) AS SCHEDULER,
	ROUND(CPU / 720, 3) AS CPU,
	ROUND(BCPU / 720, 3) AS BACKGROUND_CPU
FROM (
	SELECT TRUNC(SAMPLE_TIME, 'MI') AS SAMPLE_TIME,
		DECODE(SESSION_STATE, 'ON CPU', DECODE(SESSION_TYPE, 'BACKGROUND', 'BCPU', 'ON CPU'), WAIT_CLASS) AS WAIT_CLASS
	FROM V$ACTIVE_SESSION_HISTORY
	WHERE SAMPLE_TIME > SYSDATE - INTERVAL '5' HOUR
		AND SAMPLE_TIME <= TRUNC(SYSDATE, 'MI'))
ASH PIVOT(
	COUNT(*) FOR WAIT_CLASS IN('ON CPU' AS CPU,'BCPU' AS BCPU,
	'Scheduler' AS SCHEDULER,
	'User I/O' AS UIO,
	'System I/O' AS SIO, 
	'Concurrency' AS CONCURRENCY,                                                                               
	'Application' AS  APPLICATION,                                                                                  
	'Commit' AS  COMMIT,                                                                             
	'Configuration' AS CONFIGURATION,                     
	'Administrative' AS   ADMINISTRATIVE,                                                                                 
	'Network' AS  NETWORK,                                                                                 
	'Queueing' AS   QUEUEING,                                                                                  
	'Cluster' AS   CLUST,                                                                                      
	'Other' AS  OTHER))
;