
# **Table Of Contents**
 - [Overview](#overview) 
 - [Migration Tool Process Flow](#migration-tools-process-flow)
 - [What does the Migration Utilities do?](#what-do-the-migration-tools-do?)
 - [What is in the Migration Tools?](#what-is-in-the-migration-tools?)
 - [Contact Information](#contact-information)



## Overview

This directory contains APS to Azure Synapse migration toolkit. It includes the process flow, PowerShell script modules and configuration required in each module.

Below documents provide detailed information to help you get started.

- [**APS2Synapse_Migration.pptx**](APS2Synapse_Migration.pptx) 
- [**Migration/APS/APS_Migration_Considerations_Github.pptx**](APS_Migration_Considerations_Github.pptx) 
- [**APS-to-Azure-Synapse-Analytics-Migration-Guide.docx**](APS-to-Azure-Synapse-Analytics-Migration-Guide.docx) 




## Migration Tools Process Flow

![Tool Processflow](Images/ProcessFlow_v2.PNG)

## What do the Migration Tools do?

The set of PowerShell Scripts performs below functions:

- Generates object creation scripts from source APS environment
- Translates APS object creation scripts to the Azure Synapse designs
- Generates APS export scripts to create the APS external tables to write data to Azure blob storage.
- Generates Synapse import scripts to load data from Azure blob storage to Synapse environment.
- Generates Synapse external table scripts
- Deploy/Execute the scripts to Synapse environment.



## What is in the Migration Tools?

There are 5 modules that contain PowerShell scripts and T-SQL scripts designed to accomplish key tasks that are relevant to APS to Azure Synapse migration.

Five modules are summarized below.

- [**1_CreateDDLScripts**](1_CreateDDLScripts) - Generates the APS objects creation scripts.

- [**2_ConvertDDLScripts:**](2_ConvertDDLScripts) Translates/generates the Synapse objects creation scripts from the objects listed from the step 1

- [**3_CreateAPSExportScriptSynapseImportScript:**](3_CreateAPSExportScriptSynapseImportScript) 
  
    - Generates APS external table scripts to write data to Azure blob storage
    - Generates COPY INTO scripts to load data into Azure Synapse tables 
    - Generates import scripts to load data from Azure external tables into Azure Synapse tables.
    
- [**4_CreateExternalTablesSynapse:**](4_CreateExternalTablesSynapse) Generates scripts to create Azure Synapse external tables

- [**5_DeployScriptsToSynapse:**](5_DeployScriptsToSynapse) 
    This module can be used to execute/deploy any scripts to the Synapse environment.
    - To create Synapse schema objects (tables, views, stored procedures, indexes, roles, users, statistics)
    - To create Synapse external tables
    - To import data from Azure external tables into Azure Synapse user tables.
    

> Under [**Extras**](Extras) folder you can find scripts to re-create sample databases AdventureWorksDW and ContosoDW which you can use for learning, demos, and experimenting with migration tools.



## Contact Information

Please send an email to AMA architects at <AMAArchitects@service.microsoft.com> for any issues regarding this tool.
