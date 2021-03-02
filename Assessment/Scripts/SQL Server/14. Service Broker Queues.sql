-- Query for: 14. Service Broker Queues

    SELECT name, type_desc, count(*) as COUNT 
    FROM sys.service_queues 
    WHERE is_ms_shipped <> 1
    GROUP BY name, type_desc
    

