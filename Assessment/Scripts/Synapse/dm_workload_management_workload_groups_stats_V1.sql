select 
	effective_min_percentage_resource, 
	effective_Cap_Percentage_resource, 
	effective_request_min_resource_grant_percent, 
	effective_request_max_resource_grant_percent, * 
from sys.dm_workload_management_workload_groups_stats
order by group_id;