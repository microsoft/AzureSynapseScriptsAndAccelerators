SELECT tab.database DBName , tab.Owner SchemaName, tab.tablename TableName
          ,case when map.attname is null then 'RANDOM' else 'HASH' end distribution_policy_desc
           ,case when max(org.attname) is null then '0' else '1' end "is_Partitioned(Organized)"
           --COALESCE(map.attname,'RANDOM') AS distribution_key
           --,map.attname
           , COALESCE(max(map.distseqno), 0) AS dist_Column_cnt 
 FROM _v_table tab  
           LEFT OUTER JOIN _v_table_dist_map map  ON map.objid = tab.objid 
           LEFT OUTER JOIN _V_TABLE_ORGANIZE_COLUMN org ON org.objid = tab.objid
WHERE UPPER(objtype) IN ('TABLE','SECURE TABLE') 
 group by tab.database, tab.Owner, tab.tablename , distribution_policy_desc
ORDER BY tab.database, tab.Owner, tab.tablename
 ;