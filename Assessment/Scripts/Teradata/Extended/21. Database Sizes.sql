-- Query for: 21. Database Sizes

SELECT d.DatabaseName, PermSpace/1024.0/1024.0 SpaceMB, CreateTimeStamp, LastAlterTimeStamp, CurrentSizeGB, MaxSizeGB, PercentUsed
FROM DBC.DatabasesV d
	JOIN (SELECT  DatabaseName, SUM(CurrentPerm)/1024.0/1024.0/1024 CurrentSizeGB, SUM(MaxPerm)/1024.0/1024.0/1024 MaxSizeGB, cast(cast(SUM(CurrentPerm) as float)/NULLIFZERO(cast(SUM(MaxPerm) as float))*100 as int) PercentUsed 
			FROM DBC.DiskSpaceV
			GROUP BY DatabaseName) s on (d.DatabaseName = s.DatabaseName)
WHERE dbkind = 'D'
	  AND d.DatabaseName not in ('console', 'DBC', 'dbcmngr', 'LockLogShredder', 'SQLJ', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 'SYSSPATIAL', 
'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'Sys_Calendar', 'TDQCD', 'TDStats', 'tdwm', 'TD_SERVER_DB', 'TD_SYSFNLIB', 'TD_SYSGPL','TD_SYSXML',
'PDCRAdmin','PDCRCanary1M','PDCRINFO','PDCRSTG','PDCRCanary0M','PDCRCanary2M','PDCRCanary3M','PDCRADM','PDCRAccess','PDCRTPCD','PDCRCanary4M','PDCRDATA','TDMaps')
ORDER BY d.DatabaseName;
    

