--#======================================================================================================================#
--#                                                                                                                      #
--#  AzureSynapseScriptsAndAccelerators - PowerShell and T-SQL Utilities                                                 #
--#                                                                                                                      #
--#  This utility was developed to aid SMP/MPP migrations to Azure Synapse Migration Practitioners.                      #
--#  It is not an officially supported Microsoft application or tool.                                                    #
--#                                                                                                                      #
--#  The utility and any script outputs are provided on "AS IS" basis and                                                #
--#  there are no warranties, express or implied, including, but not limited to implied warranties of merchantability    #
--#  or fitness for a particular purpose.                                                                                #
--#                                                                                                                      #                    
--#  The utility is therefore not guaranteed to generate perfect code or output. The output needs carefully reviewed.    #
--#                                                                                                                      #
--#                                       USE AT YOUR OWN RISK.                                                          #
--#                                                                                                                      #
--#======================================================================================================================#

/***************************************************************************************/
/*           T-SQL Script to test important and relevant database information          */ 
/*                          Gaiye "Gail" Zhou, Architect                               */
/*                               May 2017                                              */
/***************************************************************************************/
-- (1)
-- Use below SP to get DB size in particular DB
-- Use AdventureWorks2017
-- Exec sp_spaceused


--(2) Use below Scripts to get all DB Sizes 
SELECT      sdb.name,  
            CONVERT(VARCHAR,SUM(smf.size)*8.0/1024.0) AS [SizeMB],
			CONVERT(VARCHAR,SUM(smf.size)*8.0/1024/1024.0) AS [SizeGB], 
			CONVERT(VARCHAR,SUM(smf.size)*8.0/1024/1024.0/1024.0) AS [SizeTB]  
FROM        sys.databases sdb  
JOIN        sys.master_files smf
ON          sdb.database_id=smf.database_id
where  sdb.name not in ('master','tempdb','msdb','model') and sdb.state = 0 
GROUP BY    sdb.name  
ORDER BY    sdb.name 