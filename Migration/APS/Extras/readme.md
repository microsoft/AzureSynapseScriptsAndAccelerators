
# **Extras**
This folder contains extra files which might be used for learning the process.

- [**AdventureWorksDW.sql**](AdventureWorksDW.sql) - this is SQL-script to create sample AdventureWorksDW database in APS/PDW appliance.

    > Before running the script, make sure that the database exists and used in the current context.

- [**ContosoDW.sql**](ContosoDW.sql) - this is SQL-script to create sample AdventureWorksDW ContosoDW in APS/PDW appliance. 

    > Before running the script, make sure that the database exists and used in the current context.

- [**CreateExternalObjects.sql**](CreateExternalObjects.sql) - this is SQL-script to create external objects in APS/PDW database and/or Azure Synapse Dedicated SQL Pool database, incl.

    - MASTER KEY 
    - DATABASE SCOPED CREDENTIAL
    - EXTERNAL DATA SOURCE
    - EXTERNAL FILE FORMAT
    
> Before running the script, replace the following snippets by actual values in your environment:
    >
    > - <EnterStrongPasswordHere>  - the password to secure MASTER KEY.
    > - <storageaccountname> - the name of Azure Storage Account to be used for importing or exporting data.
    > - <storageaccountkey> - the key to access Azure Storage Account
    > - <containername> - the name of a container in Azure Storage Account
    
