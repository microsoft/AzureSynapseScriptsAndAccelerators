-- Query for: 17. Role Members

SELECT RoleName, Grantee FROM DBC.RoleMembers 
WHERE Grantee NOT IN ('DBC');
    

