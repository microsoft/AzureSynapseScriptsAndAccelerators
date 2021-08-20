-- Query for: AMPs per Node

SELECT
	nodeid,
	COUNT(DISTINCT vproc) number_of_amps 
FROM dbc.ResCpuUsageByAmpView 
GROUP BY nodeid;
    

