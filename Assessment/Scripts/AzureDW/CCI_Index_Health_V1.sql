select schema_name(t.schema_id) [schema_name], t.name, 
	Partition_number, state_description, total_rows, 
	deleted_rows, size_in_bytes, pt.pdw_node_id, pt.distribution_id,
	Case when state_description = 'COMPRESSED' and total_rows < 1048576 then 'Not Optimized' 
	     when state_description <> 'COMPRESSED' then State_description else 'Optimized' end 
FROM sys.pdw_nodes_column_store_row_groups rg
JOIN sys.pdw_nodes_tables pt
ON rg.object_id = pt.object_id AND rg.pdw_node_id = pt.pdw_node_id AND pt.distribution_id = rg.distribution_id
JOIN sys.pdw_table_mappings tm
ON pt.name = tm.physical_name
INNER JOIN sys.tables t
ON tm.object_id = t.object_id
INNER JOIN sys.schemas s
ON t.schema_id = s.schema_id
order by 1, 2