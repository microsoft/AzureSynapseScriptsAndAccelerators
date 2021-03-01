-- Query for: 20. Overall Teradata Size

SELECT DatabaseName, PermSpace/1024.0/1024.0/1024.0 SpaceGB, CreateTimeStamp, LastAlterTimeStamp
FROM DBC.DatabasesV 
WHERE DatabaseName = 'DBC';
    

