
-- For Table Identity Columns, the generated Polybase Export Script will not execute.
-- Some manual manipulations are needed. This sample file illustrates the steps. 

-- SQL Server Table 
CREATE TABLE [dbo].[DimAccount](
	[AccountKey] [int] IDENTITY(1,1) NOT NULL, -- This will not work for Polybase Export 
	[ParentAccountKey] [int] NULL,
	[AccountCodeAlternateKey] [int] NULL,
	[ParentAccountCodeAlternateKey] [int] NULL,
	[AccountDescription] [nvarchar](50) NULL,
	[AccountType] [nvarchar](50) NULL,
	[Operator] [nvarchar](50) NULL,
	[CustomMembers] [nvarchar](300) NULL,
	[ValueType] [nvarchar](50) NULL,
	[CustomMemberOptions] [nvarchar](200) NULL,
 
) 



-- Polybase Export Script
CREATE EXTERNAL TABLE [AdventureWorksDW2016].[ext_dbo].[DimAccount]
(
    [AccountKey] INT NOT NULL  -- Change this column from Identity to Int. 
    ,[ParentAccountKey] INT NULL 
    ,[AccountCodeAlternateKey] INT NULL 
    ,[ParentAccountCodeAlternateKey] INT NULL 
    ,[AccountDescription] NVARCHAR (50) NULL 
    ,[AccountType] NVARCHAR (50) NULL 
    ,[Operator] NVARCHAR (50) NULL 
    ,[CustomMembers] NVARCHAR (300) NULL 
    ,[ValueType] NVARCHAR (50) NULL 
    ,[CustomMemberOptions] NVARCHAR (200) NULL 
)
WITH 
( 
       LOCATION = '/CsvNoCompression/AdventureWorksDW2016/dbo_DimAccount',
       DATA_SOURCE = External_DataSource_Name,
       FILE_FORMAT = CsvNoCompression
)

-- Need to perform this additional step to export data. 
INSERT INTO [AdventureWorksDW2016].[ext_dbo].[DimAccount]
  SELECT * FROM [AdventureWorksDW2016].[dbo].[DimAccount]
	