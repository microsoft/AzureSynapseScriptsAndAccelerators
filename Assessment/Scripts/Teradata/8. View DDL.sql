-- Query for: 8. View DDL

SELECT 'show ' || 
	CASE 
		WHEN tablekind = 'M' THEN 'macro' 
		WHEN tablekind = 'T' THEN 'table' 
		WHEN tablekind = 'V' THEN 'view' 
	END || ' ' || TRIM(databasename) || '.' || TRIM(TABLENAME) || ';' AS ViewResult
FROM dbc.tablesV WHERE tablekind IN ('V')
AND databasename NOT IN ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
	'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
	'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps')
ORDER BY databasename, TABLENAME; 
    

