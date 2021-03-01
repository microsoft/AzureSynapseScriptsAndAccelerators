-- Query for: 3. Table Size

SELECT a.databasename AS DATABASENAME,      
	TABLENAME,     
	SUM(currentperm /1024/1024) AS USEDSPACEINMB     
FROM dbc.tablesize a  
INNER JOIN DBC.Databases d ON a.databasename  = d.databasename     
WHERE EXISTS(SELECT 1 FROM dbc.tables b 
			WHERE a.databasename = b.databasename 
			AND a.TABLENAME = b.TABLENAME 
			AND b.tablekind = 'T'  
)
AND a.databasename NOT IN ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps')
GROUP BY 1, 2
    

