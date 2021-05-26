#======================================================================================================================#
#                                                                                                                      #
#  AzureSynapseScriptsAndAccelerators - PowerShell and T-SQL Utilities                                                 #
#                                                                                                                      #
#  This utility was developed to aid SMP/MPP migrations to Azure Synapse Migration Practitioners.                      #
#  It is not an officially supported Microsoft application or tool.                                                    #
#                                                                                                                      #
#  The utility and any script outputs are provided on "AS IS" basis and                                                #
#  there are no warranties, express or implied, including, but not limited to implied warranties of merchantability    #
#  or fitness for a particular purpose.                                                                                #
#                                                                                                                      #                    
#  The utility is therefore not guaranteed to generate perfect code or output. The output needs carefully reviewed.    #
#                                                                                                                      #
#                                       USE AT YOUR OWN RISK.                                                          #
#                                                                                                                      #
#======================================================================================================================#
#
# COPY Into Doc 
# https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/quickstart-bulk-load-copy-tsql-examples


# If you have a standalone dedicated SQL pool, register your SQL server with Azure Active Directory (AAD) using PowerShell:

<#

# Fill in the value inside <> without <>, and no quotes arount it! 

Connect-AzAccount
Select-AzSubscription -SubscriptionId <subscriptionId>
Set-AzSqlServer -ResourceGroupName your-database-server-resourceGroup -ServerName your-SQL-servername -AssignIdentity

#>

# Sample 
Connect-AzAccount
Select-AzSubscription -SubscriptionId xsddddd-2b78-4xxx-dddd-23456x12345
Set-AzSqlServer -ResourceGroupName myresourcename -ServerName mysynapseworkspacename.sql.azuresynapse.net -AssignIdentity

Write-Output "Done"


#If you have a Synapse workspace, register your workspace's system-managed identity:

#Go to your Synapse workspace in the Azure portal
#Go to the Managed identities blade
#Make sure the "Allow Pipelines" option is enabled