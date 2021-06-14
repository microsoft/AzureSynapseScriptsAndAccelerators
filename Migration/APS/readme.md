
# **Table Of Contents**
 - [Overview](#overview) 
 - [Migration Tool Processflow](#migration-tool-processflow)
 - [What does the Migration Utilities do](#what-does-the-migration-utilities-do)
 - [What are in the Migration Utilities](#what-are-in-the-migration-utilities)
  - [Contact Information](#contact-information)

## Overview

This directory contains APS to Azure Synapse migration toolkit. It includes the processflow,powershell script modules and configuration required in each module.

Below documents provide detailed information to help you get started.

- [**APS2Synapse_Migration.pptx**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/blob/main/Migration/APS/APS2Synapse_Migration.pptx) 
- [**Migration/APS/APS_Migration_Considerations_Github.pptx**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/blob/main/Migration/APS/Migration/APS/APS_Migration_Considerations_Github.pptx) 
- [**APS-to-Azure-Synapse-Analytics-Migration-Guide-Draft-V1.2.docx**](https://github.com/microsoft/AzureSynapseScriptsAndAccelerators/blob/main/Migration/APS/APS-to-Azure-Synapse-Analytics-Migration-Guide-Draft-V1.2.docx) 


## Migration Tool Processflow

![Tool Processflow](Images/ProcessFlow.PNG)

## What does the Migration Utilities do

The set of PowerShell Scripts performs below functions:

- Generates object creation scripts from source APS environment
- Translates APS object creation scripts to the Azure Synapse designs
- Generates APS export scripts to create the APS external tables to write data to Azure blob storage.
- Generates Synapse import scripts to load data from Azure blob storage to Synapse environment.
- Generates Synapse external table scripts
- Deploy/Execute the scripts to Synapse environment.

## What are in the Migration Utilities

There are 5 modules that contain Powershell scripts and T-SQL scripts designed to accomplish key tasks that relavant to APS to Azure Synapse migration.

Five modules are summarized below.

- **1_CreateDDLScripts:** Generates the APS objects creation scripts.
- **2_ConvertDDLScripts:** Translates/generates the Synapse objects creation scripts from the objects listed from the step 1
- **3_CreateAPSExportScriptSynapseImportScript:** 
    - Generates APS export or external table scripts to write data to Azure blob storage
    - Generates copyinto scripts to load data to Azure Synapse tables 
    - Generates import scripts to load data from Azure external tables to the Azure internal tables
- **4_CreateExternalTablesSynapse:** Generates scripts to create Azure Synpase external tables

- **5_DeployScriptsToSynapse:** 
    This module can be used to execute/deploy any scripts to the Synapse environment.
    - To execute Synapse external tables
    - To import data from Azure blob storage to Azure Synapse tables.
    - To import data from Azure external tables to Azure Synapse internal tables.

## Contact Information

Please send an email to AMA architects at <AMAArchitects@service.microsoft.com> for any issues regarding this tool.
