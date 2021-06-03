
-- Set Up Polybase Export 
EXEC sp_configure @configname = 'hadoop connectivity', @configvalue = 7;

--EXEC sp_configure 'polybase enabled' --for SQL Server 2016

-- For SQL Server 2017 
EXEC sp_configure 'allow polybase export', 1; -- for SQL Server 2017 

RECONFIGURE WITH OVERRIDE;
GO
RECONFIGURE;
GO

-- Check for Polybase
SELECT SERVERPROPERTY ('IsPolyBaseInstalled') AS IsPolyBaseInstalled; 
