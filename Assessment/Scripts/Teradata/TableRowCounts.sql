-- Query for: Table Row Counts. Relies on Statistics.
SELECT  DatabaseName,
        TableName,
        RowCount,
        LastCollectTimeStamp
FROM    DBC.TableStatsV
WHERE   IndexNumber = 1
AND DataBaseName NOT IN ('All', 'Crashdumps', 'DBC', 'dbcmngr', 
    'Default', 'External_AP', 'EXTUSER', 'LockLogShredder', 'PUBLIC',
    'Sys_Calendar', 'SysAdmin', 'SYSBAR', 'SYSJDBC', 'SYSLIB', 
    'SystemFe', 'SYSUDTLIB', 'SYSUIF', 'TD_SERVER_DB',  'TDStats',
    'TD_SYSGPL', 'TD_SYSXML', 'TDMaps', 'TDPUSER', 'TDQCD',
    'tdwm',  'SQLJ', 'TD_SYSFNLIB',  'SYSSPATIAL')
ORDER BY    RowCount DESC;


