
# Netezza Schema Export

## Purpose

The Netezza Schema Export is part of the Assessment tool.  It's purpose is to help automate the extraction of the Netezza database schemas.  The extracted database schema can then be translated into a format for Azure SQL Data Warehouse.

## Process

Execute the Powershell script on the Windows machine.   The Powershell script connects to the Netezza system and gathers the names of the tables, views and generates an extract script of nz_ddl commands to be executed on the Netezza system.

The extract script needs to be copied to the Netezza system/appliance (or a machine with the Netezza client binaries) and executed.  Currently the script only works with a local Netezza instance, if you wish to connect to a remote appliance you will need to add the -u -w -host and -port options to the 'nz_ddl_table' and 'nz_ddl_view' commands in the file.

The output from the extract script is a series of create table and view scripts in a predefined structure.
"SchemaExportFolder"/"DATABASE"/"OBJECT_TYPE"/"OBJECT".sql


## Steps to Export Schema from Netezza

To export the schema from Netezza follow the steps below.

Update the following enteries in the PreAssessmentDriverFile.json

	"nzBinaryFolder":"/nz/support/bin",   -- The localation the nz_dll_table binaries.
	"SchemaExportFolder":"~/schema",   -- Location on the Netezza system for the output schema files.
	"SchemaExportObjects":"TABLE,VIEW", -- The objects which will be exported. Only Table and View are currently supported.
	"SchemaExportFile":"netezza.sh",  -- unix script to extract the schema. 
	"DatabasesForSchemaExport":"ALL" --- replace with the databases you want to extract the schema for.  Pick 'ALL' for all the databases.
	"PrefixDatabaseNameToSchema":"Yes" -- Adds the database name to the filename of the objects.


**Step 1:**
Enable the schema extract in PreAssessmentDriverFile.json
Change the leading Zero on the line from 0 to 1.  This will enable the script for the next time its run.

	0,Netezza,DB,ALL,SCHEMA,..... 
	to
	1,Netezza,DB,ALL,SCHEMA,.....

If you are just extracting the schema, it would be advisable to disable the other scripts in the PreAssessmentDriverFile.json file

**Step 2:**
Execute the PreAssessmentDriver_V2.ps1 Powershell script.

	./PreAssessmentDriver_V2.ps1

**Step 3:**
Copy the bash script to a Netezza/Unix system with the Netezza client binaries. 

	For Example:
	scp DATABASENAME_netezza.sh nz@IP_ADDRESS:~/DATABASENAME_netezza.sh

(Replace the above values NZ for the Netezza Appliance login, IP_ADDRESS for the IP Address of the Netezza Appliance)

**Step 4:**
Make the shell script executable.

	For Example:
	CHMOD u+x DATABASENAE_netezza.sh

**Step 5:**
Execute Unix2DOS on the shell script.

	For Example:
	dos2unix DATABASENAE_netezza.sh

**Step 6:**
Exectue the bash script.  The database schema will be created in a schema export folder. ( "SchemaExportFolder" from the PreAssessmentDriverFile.json)

	./DATABASENAME_netezza.sh


**Step 7:**
Zip or Tar/Gzip the schema sub-folder

	zip schema.zip -r schema/*
	or
	tar -cvzf schema.tar.gz schema/

**Step 8:**
Copy the zip or gz file to the windows enviroment

	scp nz@IP_ADDRESS:~/schema.zip schema.zip
	or
	scp nz@IP_ADDRESS:~/schema.tar.gz schema.tar.gz

**Step 9:**
Decompress the file.  This can be done with windows for a ZIP file.



