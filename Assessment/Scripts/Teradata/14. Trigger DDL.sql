-- Query for: 14. Trigger DDL

SELECT 'show ' || 
	CASE 
		WHEN tablekind = 'P' THEN 'procedure' 
		WHEN tablekind = 'E' THEN 'procedure' 
		WHEN tablekind = 'G' THEN 'trigger' 
	END || ' ' || TRIM(databasename) || '.' || TRIM(TABLENAME) || ';'  AS TriggerResult
FROM dbc.tablesV WHERE tablekind IN ('G')
AND databasename NOT IN ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
	'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
	'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps')
ORDER BY databasename, TABLENAME;
    

