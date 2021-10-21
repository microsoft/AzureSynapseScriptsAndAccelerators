/*
USE master
GO

SELECT  * FROM sys.databases
GO

DROP DATABASE ContosoDW
GO

CREATE DATABASE ContosoDW WITH (autogrow = on, replicated_size = 0.0625, distributed_size = 1, log_size = 0.2);
GO
*/

-- CREATE an external data source
-- TYPE: HADOOP - PolyBase uses Hadoop APIs to access data in Azure blob storage.
-- LOCATION: Provide Azure storage account name and blob container name.
-- CREDENTIAL: Provide the credential created in the previous step.

CREATE EXTERNAL DATA SOURCE AzureStorageImport
WITH 
(  
    TYPE = Hadoop 
,   LOCATION = 'wasbs://contosoretaildw-tables@contosoretaildw.blob.core.windows.net/'
); 
GO

-- The data is stored in text files in Azure blob storage, and each field is separated with a delimiter. 
-- Run this [CREATE EXTERNAL FILE FORMAT] command to specify the format of the data in the text files. 
-- he Contoso data is uncompressed and pipe delimited.

CREATE EXTERNAL FILE FORMAT TextFileFormat 
WITH 
(   FORMAT_TYPE = DELIMITEDTEXT
,	FORMAT_OPTIONS	(   FIELD_TERMINATOR = '|'
					,	STRING_DELIMITER = ''
					,	DATE_FORMAT		 = 'yyyy-MM-dd HH:mm:ss.fff'
					,	USE_TYPE_DEFAULT = FALSE 
					)
);
GO

-- To CREATE a place to store the Contoso data in your database, CREATE a schema.

CREATE SCHEMA [asb];
GO


-- Now let's CREATE the external tables. All we are doing here is defining column names and data types, 
-- and binding them to the location and format of the Azure blob storage files. The location is the folder 
-- under the root directory of the Azure Storage Blob.

--DimAccount
CREATE EXTERNAL TABLE [asb].DimAccount 
(
	[AccountKey] [int] NOT NULL,
	[ParentAccountKey] [int] NULL,
	[AccountLabel] [nvarchar](100) NULL,
	[AccountName] [nvarchar](50) NULL,
	[AccountDescription] [nvarchar](50) NULL,
	[AccountType] [nvarchar](50) NULL,
	[Operator] [nvarchar](50) NULL,
	[CustomMembers] [nvarchar](300) NULL,
	[ValueType] [nvarchar](50) NULL,
	[CustomMemberOptions] [nvarchar](200) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH 
(
    LOCATION='/DimAccount/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimChannel
CREATE EXTERNAL TABLE [asb].DimChannel 
(
	[ChannelKey] [int] NOT NULL,
	[ChannelLabel] [nvarchar](100) NOT NULL,
	[ChannelName] [nvarchar](20) NULL,
	[ChannelDescription] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimChannel/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimCurrency
CREATE EXTERNAL TABLE [asb].DimCurrency 
(
	[CurrencyKey] [int] NOT NULL,
	[CurrencyLabel] [nvarchar](10) NOT NULL,
	[CurrencyName] [nvarchar](20) NOT NULL,
	[CurrencyDescription] [nvarchar](50) NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimCurrency/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--DimCustomer
CREATE EXTERNAL TABLE [asb].DimCustomer 
(
	[CustomerKey] [int]  NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[CustomerLabel] [nvarchar](100) NOT NULL,
	[Title] [nvarchar](8) NULL,
	[FirstName] [nvarchar](50) NULL,
	[MiddleName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[NameStyle] [bit] NULL,
	[BirthDate] [datetime] NULL,
	[MaritalStatus] [nchar](1) NULL,
	[Suffix] [nvarchar](10) NULL,
	[Gender] [nvarchar](1) NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[YearlyIncome] [money] NULL,
	[TotalChildren] [tinyint] NULL,
	[NumberChildrenAtHome] [tinyint] NULL,
	[Education] [nvarchar](40) NULL,
	[Occupation] [nvarchar](100) NULL,
	[HouseOwnerFlag] [nchar](1) NULL,
	[NumberCarsOwned] [tinyint] NULL,
	[AddressLine1] [nvarchar](120) NULL,
	[AddressLine2] [nvarchar](120) NULL,
	[Phone] [nvarchar](20) NULL,
	[DateFirstPurchase] [datetime] NULL,
	[CustomerType] [nvarchar](15) NULL,
	[CompanyName] [nvarchar](100) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimCustomer/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--DimDate
CREATE EXTERNAL TABLE [asb].DimDate
(
	[Datekey] [datetime] NOT NULL,
	[FullDateLabel] [nvarchar](20) NOT NULL,
	[DateDescription] [nvarchar](20) NOT NULL,
	[CalendarYear] [int] NOT NULL,
	[CalendarYearLabel] [nvarchar](20) NOT NULL,
	[CalendarHalfYear] [int] NOT NULL,
	[CalendarHalfYearLabel] [nvarchar](20) NOT NULL,
	[CalendarQuarter] [int] NOT NULL,
	[CalendarQuarterLabel] [nvarchar](20) NULL,
	[CalendarMonth] [int] NOT NULL,
	[CalendarMonthLabel] [nvarchar](20) NOT NULL,
	[CalendarWeek] [int] NOT NULL,
	[CalendarWeekLabel] [nvarchar](20) NOT NULL,
	[CalendarDayOfWeek] [int] NOT NULL,
	[CalendarDayOfWeekLabel] [nvarchar](10) NOT NULL,
	[FiscalYear] [int] NOT NULL,
	[FiscalYearLabel] [nvarchar](20) NOT NULL,
	[FiscalHalfYear] [int] NOT NULL,
	[FiscalHalfYearLabel] [nvarchar](20) NOT NULL,
	[FiscalQuarter] [int] NOT NULL,
	[FiscalQuarterLabel] [nvarchar](20) NOT NULL,
	[FiscalMonth] [int] NOT NULL,
	[FiscalMonthLabel] [nvarchar](20) NOT NULL,
	[IsWorkDay] [nvarchar](20) NOT NULL,
	[IsHoliday] [int] NOT NULL,
	[HolidayName] [nvarchar](20) NOT NULL,
	[EuropeSeason] [nvarchar](50) NULL,
	[NorthAmericaSeason] [nvarchar](50) NULL,
	[AsiaSeason] [nvarchar](50) NULL
)
WITH
(
    LOCATION='/DimDate/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimEmployee
CREATE EXTERNAL TABLE [asb].DimEmployee 
(
	[EmployeeKey] [int]  NOT NULL,
	[ParentEmployeeKey] [int] NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[MiddleName] [nvarchar](50) NULL,
	[Title] [nvarchar](50) NULL,
	[HireDate] [datetime] NULL,
	[BirthDate] [datetime] NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[Phone] [nvarchar](25) NULL,
	[MaritalStatus] [nchar](1) NULL,
	[EmergencyContactName] [nvarchar](50) NULL,
	[EmergencyContactPhone] [nvarchar](25) NULL,
	[SalariedFlag] [bit] NULL,
	[Gender] [nchar](1) NULL,
	[PayFrequency] [tinyint] NULL,
	[BaseRate] [money] NULL,
	[VacationHours] [smallint] NULL,
	[CurrentFlag] [bit] NOT NULL,
	[SalesPersonFlag] [bit] NOT NULL,
	[DepartmentName] [nvarchar](50) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimEmployee/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimEntity
CREATE EXTERNAL TABLE [asb].DimEntity 
(
	[EntityKey] [int] NOT NULL,
	[EntityLabel] [nvarchar](100) NULL,
	[ParentEntityKey] [int] NULL,
	[ParentEntityLabel] [nvarchar](100) NULL,
	[EntityName] [nvarchar](50) NULL,
	[EntityDescription] [nvarchar](100) NULL,
	[EntityType] [nvarchar](100) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimEntity/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimGeography
CREATE EXTERNAL TABLE [asb].DimGeography 
(
	[GeographyKey] [int] NOT NULL,
	[GeographyType] [nvarchar](50) NOT NULL,
	[ContinentName] [nvarchar](50) NOT NULL,
	[CityName] [nvarchar](100) NULL,
	[StateProvinceName] [nvarchar](100) NULL,
	[RegionCountryName] [nvarchar](100) NULL,
--	[Geometry] [geometry] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimGeography/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimMachine
CREATE EXTERNAL TABLE [asb].DimMachine 
(
	[MachineKey] [int] NOT NULL,
	[MachineLabel] [nvarchar](100) NULL,
	[StoreKey] [int] NOT NULL,
	[MachineType] [nvarchar](50) NOT NULL,
	[MachineName] [nvarchar](100) NOT NULL,
	[MachineDescription] [nvarchar](200) NOT NULL,
	[VendorName] [nvarchar](50) NOT NULL,
	[MachineOS] [nvarchar](50) NOT NULL,
	[MachineSource] [nvarchar](100) NOT NULL,
	[MachineHardware] [nvarchar](100) NULL,
	[MachineSoftware] [nvarchar](100) NOT NULL,
	[Status] [nvarchar](50) NOT NULL,
	[ServiceStartDate] [datetime] NOT NULL,
	[DecommissionDate] [datetime] NULL,
	[LastModifiedDate] [datetime] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimMachine/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimOutage
CREATE EXTERNAL TABLE [asb].DimOutage (
	[OutageKey] [int]  NOT NULL,
	[OutageLabel] [nvarchar](100) NOT NULL,
	[OutageName] [nvarchar](50) NOT NULL,
	[OutageDescription] [nvarchar](200) NOT NULL,
	[OutageType] [nvarchar](50) NOT NULL,
	[OutageTypeDescription] [nvarchar](200) NOT NULL,
	[OutageSubType] [nvarchar](50) NOT NULL,
	[OutageSubTypeDescription] [nvarchar](200) NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimOutage/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimProduct
CREATE EXTERNAL TABLE [asb].DimProduct (
	[ProductKey] [int] NOT NULL,
	[ProductLabel] [nvarchar](255) NULL,
	[ProductName] [nvarchar](500) NULL,
	[ProductDescription] [nvarchar](400) NULL,
	[ProductSubcategoryKey] [int] NULL,
	[Manufacturer] [nvarchar](50) NULL,
	[BrandName] [nvarchar](50) NULL,
	[ClassID] [nvarchar](10) NULL,
	[ClassName] [nvarchar](20) NULL,
	[StyleID] [nvarchar](10) NULL,
	[StyleName] [nvarchar](20) NULL,
	[ColorID] [nvarchar](10) NULL,
	[ColorName] [nvarchar](20) NOT NULL,
	[Size] [nvarchar](50) NULL,
	[SizeRange] [nvarchar](50) NULL,
	[SizeUnitMeasureID] [nvarchar](20) NULL,
	[Weight] [float] NULL,
	[WeightUnitMeasureID] [nvarchar](20) NULL,
	[UnitOfMeasureID] [nvarchar](10) NULL,
	[UnitOfMeasureName] [nvarchar](40) NULL,
	[StockTypeID] [nvarchar](10) NULL,
	[StockTypeName] [nvarchar](40) NULL,
	[UnitCost] [money] NULL,
	[UnitPrice] [money] NULL,
	[AvailableForSaleDate] [datetime] NULL,
	[StopSaleDate] [datetime] NULL,
	[Status] [nvarchar](7) NULL,
	[ImageURL] [nvarchar](150) NULL,
	[ProductURL] [nvarchar](150) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimProduct/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimProductCategory
CREATE EXTERNAL TABLE [asb].DimProductCategory (
	[ProductCategoryKey] [int]  NOT NULL,
	[ProductCategoryLabel] [nvarchar](100) NULL,
	[ProductCategoryName] [nvarchar](30) NOT NULL,
	[ProductCategoryDescription] [nvarchar](50) NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimProductCategory/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--DimProductSubcategory
CREATE EXTERNAL TABLE [asb].DimProductSubcategory (
	[ProductSubcategoryKey] [int]  NOT NULL,
	[ProductSubcategoryLabel] [nvarchar](100) NULL,
	[ProductSubcategoryName] [nvarchar](50) NOT NULL,
	[ProductSubcategoryDescription] [nvarchar](100) NULL,
	[ProductCategoryKey] [int] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimProductSubcategory/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimPromotion
CREATE EXTERNAL TABLE [asb].DimPromotion (
	[PromotionKey] [int]  NOT NULL,
	[PromotionLabel] [nvarchar](100) NULL,
	[PromotionName] [nvarchar](100) NULL,
	[PromotionDescription] [nvarchar](255) NULL,
	[DiscountPercent] [float] NULL,
	[PromotionType] [nvarchar](50) NULL,
	[PromotionCategory] [nvarchar](50) NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[MinQuantity] [int] NULL,
	[MaxQuantity] [int] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimPromotion/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO 
 
--DimSalesTerritory
CREATE EXTERNAL TABLE [asb].DimSalesTerritory (
	[SalesTerritoryKey] [int]  NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[SalesTerritoryLabel] [nvarchar](100) NULL,
	[SalesTerritoryName] [nvarchar](50) NOT NULL,
	[SalesTerritoryRegion] [nvarchar](50) NOT NULL,
	[SalesTerritoryCountry] [nvarchar](50) NOT NULL,
	[SalesTerritoryGroup] [nvarchar](50) NULL,
	[SalesTerritoryLevel] [nvarchar](10) NULL,
	[SalesTerritoryManager] [int] NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimSalesTerritory/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--DimScenario
CREATE EXTERNAL TABLE [asb].DimScenario (
	[ScenarioKey] [int] NOT NULL,
	[ScenarioLabel] [nvarchar](100) NOT NULL,
	[ScenarioName] [nvarchar](20) NULL,
	[ScenarioDescription] [nvarchar](50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimScenario/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--DimStore
CREATE EXTERNAL TABLE [asb].DimStore 
(
	[StoreKey] [int] NOT NULL,
	[GeographyKey] [int] NOT NULL,
	[StoreManager] [int] NULL,
	[StoreType] [nvarchar](15) NULL,
	[StoreName] [nvarchar](100) NOT NULL,
	[StoreDescription] [nvarchar](300) NOT NULL,
	[Status] [nvarchar](20) NOT NULL,
	[OpenDate] [datetime] NOT NULL,
	[CloseDate] [datetime] NULL,
	[EntityKey] [int] NULL,
	[ZipCode] [nvarchar](20) NULL,
	[ZipCodeExtension] [nvarchar](10) NULL,
	[StorePhone] [nvarchar](15) NULL,
	[StoreFax] [nvarchar](14) NULL,
	[AddressLine1] [nvarchar](100) NULL,
	[AddressLine2] [nvarchar](100) NULL,
	[CloseReason] [nvarchar](20) NULL,
	[EmployeeCount] [int] NULL,
	[SellingAreaSize] [float] NULL,
	[LastRemodelDate] [datetime] NULL,
	[GeoLocation]	NVARCHAR(50)  NULL,
	[Geometry]		NVARCHAR(50) NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/DimStore/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--FactExchangeRate
CREATE EXTERNAL TABLE [asb].FactExchangeRate 
(
	[ExchangeRateKey] [int]  NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[AverageRate] [float] NOT NULL,
	[EndOfDayRate] [float] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactExchangeRate/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--FactInventory
CREATE EXTERNAL TABLE [asb].FactInventory (
	[InventoryKey] [int]  NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[ProductKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[OnHandQuantity] [int] NOT NULL,
	[OnOrderQuantity] [int] NOT NULL,
	[SafetyStockQuantity] [int] NULL,
	[UnitCost] [money] NOT NULL,
	[DaysInStock] [int] NULL,
	[MinDayInStock] [int] NULL,
	[MaxDayInStock] [int] NULL,
	[Aging] [int] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactInventory/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--FactITMachine
CREATE EXTERNAL TABLE [asb].FactITMachine (
	[ITMachinekey] [int] NOT NULL,
	[MachineKey] [int] NOT NULL,
	[Datekey] [datetime] NOT NULL,
	[CostAmount] [money] NULL,
	[CostType] [nvarchar](200) NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactITMachine/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--FactITSLA
CREATE EXTERNAL TABLE [asb].FactITSLA 
(
	[ITSLAkey] [int]  NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[MachineKey] [int] NOT NULL,
	[OutageKey] [int] NOT NULL,
	[OutageStartTime] [datetime] NOT NULL,
	[OutageEndTime] [datetime] NOT NULL,
	[DownTime] [int] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactITSLA/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--FactOnlineSales
CREATE EXTERNAL TABLE [asb].FactOnlineSales 
(
	[OnlineSalesKey] [int]  NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[ProductKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[CustomerKey] [int] NOT NULL,
	[SalesOrderNumber] [nvarchar](20) NOT NULL,
	[SalesOrderLineNumber] [int] NULL,
	[SalesQuantity] [int] NOT NULL,
	[SalesAmount] [money] NOT NULL,
	[ReturnQuantity] [int] NOT NULL,
	[ReturnAmount] [money] NULL,
	[DiscountQuantity] [int] NULL,
	[DiscountAmount] [money] NULL,
	[TotalCost] [money] NOT NULL,
	[UnitCost] [money] NULL,
	[UnitPrice] [money] NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactOnlineSales/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--FactSales
CREATE EXTERNAL TABLE [asb].FactSales 
(
	[SalesKey] [int]  NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[channelKey] [int] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[ProductKey] [int] NOT NULL,
	[PromotionKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[UnitCost] [money] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[SalesQuantity] [int] NOT NULL,
	[ReturnQuantity] [int] NOT NULL,
	[ReturnAmount] [money] NULL,
	[DiscountQuantity] [int] NULL,
	[DiscountAmount] [money] NULL,
	[TotalCost] [money] NOT NULL,
	[SalesAmount] [money] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactSales/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

--FactSalesQuota
CREATE EXTERNAL TABLE [asb].FactSalesQuota (
	[SalesQuotaKey] [int]  NOT NULL,
	[ChannelKey] [int] NOT NULL,
	[StoreKey] [int] NOT NULL,
	[ProductKey] [int] NOT NULL,
	[DateKey] [datetime] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[ScenarioKey] [int] NOT NULL,
	[SalesQuantityQuota] [money] NOT NULL,
	[SalesAmountQuota] [money] NOT NULL,
	[GrossMarginQuota] [money] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactSalesQuota/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO
 
--FactStrategyPlan
CREATE EXTERNAL TABLE [asb].FactStrategyPlan 
(
	[StrategyPlanKey] [int]  NOT NULL,
	[Datekey] [datetime] NOT NULL,
	[EntityKey] [int] NOT NULL,
	[ScenarioKey] [int] NOT NULL,
	[AccountKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[ProductCategoryKey] [int] NULL,
	[Amount] [money] NOT NULL,
	[ETLLoadID] [int] NULL,
	[LoadDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
    LOCATION='/FactStrategyPlan/' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO


-- Load the data
-- To load the data we use one CTAS statement per table.

CREATE TABLE [dbo].[DimAccount]            WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimAccount]             OPTION (LABEL = 'CTAS : Load [asb].[DimAccount]             ');
CREATE TABLE [dbo].[DimChannel]            WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimChannel]             OPTION (LABEL = 'CTAS : Load [asb].[DimChannel]             ');
CREATE TABLE [dbo].[DimCurrency]           WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimCurrency]            OPTION (LABEL = 'CTAS : Load [asb].[DimCurrency]            ');
CREATE TABLE [dbo].[DimCustomer]           WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimCustomer]            OPTION (LABEL = 'CTAS : Load [asb].[DimCustomer]            ');
CREATE TABLE [dbo].[DimDate]               WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimDate]                OPTION (LABEL = 'CTAS : Load [asb].[DimDate]                ');
CREATE TABLE [dbo].[DimEmployee]           WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimEmployee]            OPTION (LABEL = 'CTAS : Load [asb].[DimEmployee]            ');
CREATE TABLE [dbo].[DimEntity]             WITH (DISTRIBUTION = HASH([EntityKey]   ) ) AS SELECT * FROM [asb].[DimEntity]              OPTION (LABEL = 'CTAS : Load [asb].[DimEntity]              ');
CREATE TABLE [dbo].[DimGeography]          WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimGeography]           OPTION (LABEL = 'CTAS : Load [asb].[DimGeography]           ');
CREATE TABLE [dbo].[DimMachine]            WITH (DISTRIBUTION = HASH([MachineKey]  ) ) AS SELECT * FROM [asb].[DimMachine]             OPTION (LABEL = 'CTAS : Load [asb].[DimMachine]             ');
CREATE TABLE [dbo].[DimOutage]             WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimOutage]              OPTION (LABEL = 'CTAS : Load [asb].[DimOutage]              ');
CREATE TABLE [dbo].[DimProduct]            WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[DimProduct]             OPTION (LABEL = 'CTAS : Load [asb].[DimProduct]             ');
CREATE TABLE [dbo].[DimProductCategory]    WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimProductCategory]     OPTION (LABEL = 'CTAS : Load [asb].[DimProductCategory]     ');
CREATE TABLE [dbo].[DimScenario]           WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimScenario]            OPTION (LABEL = 'CTAS : Load [asb].[DimScenario]            ');
CREATE TABLE [dbo].[DimPromotion]          WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimPromotion]           OPTION (LABEL = 'CTAS : Load [asb].[DimPromotion]           ');
CREATE TABLE [dbo].[DimProductSubcategory] WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimProductSubcategory]  OPTION (LABEL = 'CTAS : Load [asb].[DimProductSubcategory]  ');
CREATE TABLE [dbo].[DimSalesTerritory]     WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimSalesTerritory]      OPTION (LABEL = 'CTAS : Load [asb].[DimSalesTerritory]      ');
CREATE TABLE [dbo].[DimStore]              WITH (DISTRIBUTION = ROUND_ROBIN        )   AS SELECT * FROM [asb].[DimStore]               OPTION (LABEL = 'CTAS : Load [asb].[DimStore]               ');
CREATE TABLE [dbo].[FactITMachine]         WITH (DISTRIBUTION = HASH([MachineKey]  ) ) AS SELECT * FROM [asb].[FactITMachine]          OPTION (LABEL = 'CTAS : Load [asb].[FactITMachine]          ');
CREATE TABLE [dbo].[FactITSLA]             WITH (DISTRIBUTION = HASH([MachineKey]  ) ) AS SELECT * FROM [asb].[FactITSLA]              OPTION (LABEL = 'CTAS : Load [asb].[FactITSLA]              ');
CREATE TABLE [dbo].[FactInventory]         WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[FactInventory]          OPTION (LABEL = 'CTAS : Load [asb].[FactInventory]          ');
CREATE TABLE [dbo].[FactOnlineSales]       WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[FactOnlineSales]        OPTION (LABEL = 'CTAS : Load [asb].[FactOnlineSales]        ');
CREATE TABLE [dbo].[FactSales]             WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[FactSales]              OPTION (LABEL = 'CTAS : Load [asb].[FactSales]              ');
CREATE TABLE [dbo].[FactSalesQuota]        WITH (DISTRIBUTION = HASH([ProductKey]  ) ) AS SELECT * FROM [asb].[FactSalesQuota]         OPTION (LABEL = 'CTAS : Load [asb].[FactSalesQuota]         ');
CREATE TABLE [dbo].[FactStrategyPlan]      WITH (DISTRIBUTION = HASH([EntityKey])  )   AS SELECT * FROM [asb].[FactStrategyPlan]       OPTION (LABEL = 'CTAS : Load [asb].[FactStrategyPlan]       ');
GO

-- To optimize query performance and columnstore compression after a load, rebuild the table to force
-- the columnstore index to compress all the rows. 

-- ALTER INDEX ALL ON [dbo].[FactStrategyPlan]         REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimAccount]               REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimChannel]               REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimCurrency]              REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimCustomer]              REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimDate]                  REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimEmployee]              REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimEntity]                REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimGeography]             REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimMachine]               REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimOutage]                REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimProduct]               REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimProductCategory]       REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimScenario]              REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimPromotion]             REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimProductSubcategory]    REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimSalesTerritory]        REBUILD;
-- ALTER INDEX ALL ON [dbo].[DimStore]                 REBUILD;
-- ALTER INDEX ALL ON [dbo].[FactITMachine]            REBUILD;
-- ALTER INDEX ALL ON [dbo].[FactITSLA]                REBUILD;
-- ALTER INDEX ALL ON [dbo].[FactInventory]            REBUILD;
-- ALTER INDEX ALL ON [dbo].[FactOnlineSales]          REBUILD;
-- ALTER INDEX ALL ON [dbo].[FactSales]                REBUILD;
-- ALTER INDEX ALL ON [dbo].[FactSalesQuota]           REBUILD;
-- GO

-- Optimize statistics

-- CREATE STATISTICS [stat_cso_DimMachine_DecommissionDate] ON [dbo].[DimMachine]([DecommissionDate]);
-- CREATE STATISTICS [stat_cso_DimMachine_ETLLoadID] ON [dbo].[DimMachine]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimMachine_LastModifiedDate] ON [dbo].[DimMachine]([LastModifiedDate]);
-- CREATE STATISTICS [stat_cso_DimMachine_LoadDate] ON [dbo].[DimMachine]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineDescription] ON [dbo].[DimMachine]([MachineDescription]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineHardware] ON [dbo].[DimMachine]([MachineHardware]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineKey] ON [dbo].[DimMachine]([MachineKey]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineLabel] ON [dbo].[DimMachine]([MachineLabel]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineName] ON [dbo].[DimMachine]([MachineName]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineOS] ON [dbo].[DimMachine]([MachineOS]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineSoftware] ON [dbo].[DimMachine]([MachineSoftware]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineSource] ON [dbo].[DimMachine]([MachineSource]);
-- CREATE STATISTICS [stat_cso_DimMachine_MachineType] ON [dbo].[DimMachine]([MachineType]);
-- CREATE STATISTICS [stat_cso_DimMachine_ServiceStartDate] ON [dbo].[DimMachine]([ServiceStartDate]);
-- CREATE STATISTICS [stat_cso_DimMachine_Status] ON [dbo].[DimMachine]([Status]);
-- CREATE STATISTICS [stat_cso_DimMachine_StoreKey] ON [dbo].[DimMachine]([StoreKey]);
-- CREATE STATISTICS [stat_cso_DimMachine_UpdateDate] ON [dbo].[DimMachine]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimMachine_VendorName] ON [dbo].[DimMachine]([VendorName]);
-- CREATE STATISTICS [stat_cso_DimOutage_ETLLoadID] ON [dbo].[DimOutage]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimOutage_LoadDate] ON [dbo].[DimOutage]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimOutage_OutageDescription] ON [dbo].[DimOutage]([OutageDescription]);
-- CREATE STATISTICS [stat_cso_DimOutage_OutageKey] ON [dbo].[DimOutage]([OutageKey]);
-- CREATE STATISTICS [stat_cso_DimOutage_OutageLabel] ON [dbo].[DimOutage]([OutageLabel]);
-- CREATE STATISTICS [stat_cso_DimOutage_OutageName] ON [dbo].[DimOutage]([OutageName]);
-- CREATE STATISTICS [stat_cso_DimOutage_OutageSubType] ON [dbo].[DimOutage]([OutageSubType]);
-- CREATE STATISTICS [stat_cso_DimOutage_OutageSubTypeDescription] ON [dbo].[DimOutage]([OutageSubTypeDescription]);
-- CREATE STATISTICS [stat_cso_DimOutage_OutageType] ON [dbo].[DimOutage]([OutageType]);
-- CREATE STATISTICS [stat_cso_DimOutage_OutageTypeDescription] ON [dbo].[DimOutage]([OutageTypeDescription]);
-- CREATE STATISTICS [stat_cso_DimOutage_UpdateDate] ON [dbo].[DimOutage]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimProductCategory_ETLLoadID] ON [dbo].[DimProductCategory]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimProductCategory_LoadDate] ON [dbo].[DimProductCategory]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimProductCategory_ProductCategoryDescription] ON [dbo].[DimProductCategory]([ProductCategoryDescription]);
-- CREATE STATISTICS [stat_cso_DimProductCategory_ProductCategoryKey] ON [dbo].[DimProductCategory]([ProductCategoryKey]);
-- CREATE STATISTICS [stat_cso_DimProductCategory_ProductCategoryLabel] ON [dbo].[DimProductCategory]([ProductCategoryLabel]);
-- CREATE STATISTICS [stat_cso_DimProductCategory_ProductCategoryName] ON [dbo].[DimProductCategory]([ProductCategoryName]);
-- CREATE STATISTICS [stat_cso_DimProductCategory_UpdateDate] ON [dbo].[DimProductCategory]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimScenario_ETLLoadID] ON [dbo].[DimScenario]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimScenario_LoadDate] ON [dbo].[DimScenario]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimScenario_ScenarioDescription] ON [dbo].[DimScenario]([ScenarioDescription]);
-- CREATE STATISTICS [stat_cso_DimScenario_ScenarioKey] ON [dbo].[DimScenario]([ScenarioKey]);
-- CREATE STATISTICS [stat_cso_DimScenario_ScenarioLabel] ON [dbo].[DimScenario]([ScenarioLabel]);
-- CREATE STATISTICS [stat_cso_DimScenario_ScenarioName] ON [dbo].[DimScenario]([ScenarioName]);
-- CREATE STATISTICS [stat_cso_DimScenario_UpdateDate] ON [dbo].[DimScenario]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimPromotion_DiscountPercent] ON [dbo].[DimPromotion]([DiscountPercent]);
-- CREATE STATISTICS [stat_cso_DimPromotion_EndDate] ON [dbo].[DimPromotion]([EndDate]);
-- CREATE STATISTICS [stat_cso_DimPromotion_ETLLoadID] ON [dbo].[DimPromotion]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimPromotion_LoadDate] ON [dbo].[DimPromotion]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimPromotion_MaxQuantity] ON [dbo].[DimPromotion]([MaxQuantity]);
-- CREATE STATISTICS [stat_cso_DimPromotion_MinQuantity] ON [dbo].[DimPromotion]([MinQuantity]);
-- CREATE STATISTICS [stat_cso_DimPromotion_PromotionCategory] ON [dbo].[DimPromotion]([PromotionCategory]);
-- CREATE STATISTICS [stat_cso_DimPromotion_PromotionDescription] ON [dbo].[DimPromotion]([PromotionDescription]);
-- CREATE STATISTICS [stat_cso_DimPromotion_PromotionKey] ON [dbo].[DimPromotion]([PromotionKey]);
-- CREATE STATISTICS [stat_cso_DimPromotion_PromotionLabel] ON [dbo].[DimPromotion]([PromotionLabel]);
-- CREATE STATISTICS [stat_cso_DimPromotion_PromotionName] ON [dbo].[DimPromotion]([PromotionName]);
-- CREATE STATISTICS [stat_cso_DimPromotion_PromotionType] ON [dbo].[DimPromotion]([PromotionType]);
-- CREATE STATISTICS [stat_cso_DimPromotion_StartDate] ON [dbo].[DimPromotion]([StartDate]);
-- CREATE STATISTICS [stat_cso_DimPromotion_UpdateDate] ON [dbo].[DimPromotion]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_EndDate] ON [dbo].[DimSalesTerritory]([EndDate]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_ETLLoadID] ON [dbo].[DimSalesTerritory]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_GeographyKey] ON [dbo].[DimSalesTerritory]([GeographyKey]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_LoadDate] ON [dbo].[DimSalesTerritory]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryCountry] ON [dbo].[DimSalesTerritory]([SalesTerritoryCountry]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryGroup] ON [dbo].[DimSalesTerritory]([SalesTerritoryGroup]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryKey] ON [dbo].[DimSalesTerritory]([SalesTerritoryKey]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryLabel] ON [dbo].[DimSalesTerritory]([SalesTerritoryLabel]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryLevel] ON [dbo].[DimSalesTerritory]([SalesTerritoryLevel]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryManager] ON [dbo].[DimSalesTerritory]([SalesTerritoryManager]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryName] ON [dbo].[DimSalesTerritory]([SalesTerritoryName]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_SalesTerritoryRegion] ON [dbo].[DimSalesTerritory]([SalesTerritoryRegion]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_StartDate] ON [dbo].[DimSalesTerritory]([StartDate]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_Status] ON [dbo].[DimSalesTerritory]([Status]);
-- CREATE STATISTICS [stat_cso_DimSalesTerritory_UpdateDate] ON [dbo].[DimSalesTerritory]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimProductSubcategory_ETLLoadID] ON [dbo].[DimProductSubcategory]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimProductSubcategory_LoadDate] ON [dbo].[DimProductSubcategory]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductCategoryKey] ON [dbo].[DimProductSubcategory]([ProductCategoryKey]);
-- CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductSubcategoryDescription] ON [dbo].[DimProductSubcategory]([ProductSubcategoryDescription]);
-- CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductSubcategoryKey] ON [dbo].[DimProductSubcategory]([ProductSubcategoryKey]);
-- CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductSubcategoryLabel] ON [dbo].[DimProductSubcategory]([ProductSubcategoryLabel]);
-- CREATE STATISTICS [stat_cso_DimProductSubcategory_ProductSubcategoryName] ON [dbo].[DimProductSubcategory]([ProductSubcategoryName]);
-- CREATE STATISTICS [stat_cso_DimProductSubcategory_UpdateDate] ON [dbo].[DimProductSubcategory]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimCustomer_AddressLine1] ON [dbo].[DimCustomer]([AddressLine1]);
-- CREATE STATISTICS [stat_cso_DimCustomer_AddressLine2] ON [dbo].[DimCustomer]([AddressLine2]);
-- CREATE STATISTICS [stat_cso_DimCustomer_BirthDate] ON [dbo].[DimCustomer]([BirthDate]);
-- CREATE STATISTICS [stat_cso_DimCustomer_CompanyName] ON [dbo].[DimCustomer]([CompanyName]);
-- CREATE STATISTICS [stat_cso_DimCustomer_CustomerKey] ON [dbo].[DimCustomer]([CustomerKey]);
-- CREATE STATISTICS [stat_cso_DimCustomer_CustomerLabel] ON [dbo].[DimCustomer]([CustomerLabel]);
-- CREATE STATISTICS [stat_cso_DimCustomer_CustomerType] ON [dbo].[DimCustomer]([CustomerType]);
-- CREATE STATISTICS [stat_cso_DimCustomer_DateFirstPurchase] ON [dbo].[DimCustomer]([DateFirstPurchase]);
-- CREATE STATISTICS [stat_cso_DimCustomer_Education] ON [dbo].[DimCustomer]([Education]);
-- CREATE STATISTICS [stat_cso_DimCustomer_EmailAddress] ON [dbo].[DimCustomer]([EmailAddress]);
-- CREATE STATISTICS [stat_cso_DimCustomer_ETLLoadID] ON [dbo].[DimCustomer]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimCustomer_FirstName] ON [dbo].[DimCustomer]([FirstName]);
-- CREATE STATISTICS [stat_cso_DimCustomer_Gender] ON [dbo].[DimCustomer]([Gender]);
-- CREATE STATISTICS [stat_cso_DimCustomer_GeographyKey] ON [dbo].[DimCustomer]([GeographyKey]);
-- CREATE STATISTICS [stat_cso_DimCustomer_HouseOwnerFlag] ON [dbo].[DimCustomer]([HouseOwnerFlag]);
-- CREATE STATISTICS [stat_cso_DimCustomer_LastName] ON [dbo].[DimCustomer]([LastName]);
-- CREATE STATISTICS [stat_cso_DimCustomer_LoadDate] ON [dbo].[DimCustomer]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimCustomer_MaritalStatus] ON [dbo].[DimCustomer]([MaritalStatus]);
-- CREATE STATISTICS [stat_cso_DimCustomer_MiddleName] ON [dbo].[DimCustomer]([MiddleName]);
-- CREATE STATISTICS [stat_cso_DimCustomer_NameStyle] ON [dbo].[DimCustomer]([NameStyle]);
-- CREATE STATISTICS [stat_cso_DimCustomer_NumberCarsOwned] ON [dbo].[DimCustomer]([NumberCarsOwned]);
-- CREATE STATISTICS [stat_cso_DimCustomer_NumberChildrenAtHome] ON [dbo].[DimCustomer]([NumberChildrenAtHome]);
-- CREATE STATISTICS [stat_cso_DimCustomer_Occupation] ON [dbo].[DimCustomer]([Occupation]);
-- CREATE STATISTICS [stat_cso_DimCustomer_Phone] ON [dbo].[DimCustomer]([Phone]);
-- CREATE STATISTICS [stat_cso_DimCustomer_Suffix] ON [dbo].[DimCustomer]([Suffix]);
-- CREATE STATISTICS [stat_cso_DimCustomer_Title] ON [dbo].[DimCustomer]([Title]);
-- CREATE STATISTICS [stat_cso_DimCustomer_TotalChildren] ON [dbo].[DimCustomer]([TotalChildren]);
-- CREATE STATISTICS [stat_cso_DimCustomer_UpdateDate] ON [dbo].[DimCustomer]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimCustomer_YearlyIncome] ON [dbo].[DimCustomer]([YearlyIncome]);
-- CREATE STATISTICS [stat_cso_DimEmployee_BaseRate] ON [dbo].[DimEmployee]([BaseRate]);
-- CREATE STATISTICS [stat_cso_DimEmployee_BirthDate] ON [dbo].[DimEmployee]([BirthDate]);
-- CREATE STATISTICS [stat_cso_DimEmployee_CurrentFlag] ON [dbo].[DimEmployee]([CurrentFlag]);
-- CREATE STATISTICS [stat_cso_DimEmployee_DepartmentName] ON [dbo].[DimEmployee]([DepartmentName]);
-- CREATE STATISTICS [stat_cso_DimEmployee_EmailAddress] ON [dbo].[DimEmployee]([EmailAddress]);
-- CREATE STATISTICS [stat_cso_DimEmployee_EmergencyContactName] ON [dbo].[DimEmployee]([EmergencyContactName]);
-- CREATE STATISTICS [stat_cso_DimEmployee_EmergencyContactPhone] ON [dbo].[DimEmployee]([EmergencyContactPhone]);
-- CREATE STATISTICS [stat_cso_DimEmployee_EmployeeKey] ON [dbo].[DimEmployee]([EmployeeKey]);
-- CREATE STATISTICS [stat_cso_DimEmployee_EndDate] ON [dbo].[DimEmployee]([EndDate]);
-- CREATE STATISTICS [stat_cso_DimEmployee_ETLLoadID] ON [dbo].[DimEmployee]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimEmployee_FirstName] ON [dbo].[DimEmployee]([FirstName]);
-- CREATE STATISTICS [stat_cso_DimEmployee_Gender] ON [dbo].[DimEmployee]([Gender]);
-- CREATE STATISTICS [stat_cso_DimEmployee_HireDate] ON [dbo].[DimEmployee]([HireDate]);
-- CREATE STATISTICS [stat_cso_DimEmployee_LastName] ON [dbo].[DimEmployee]([LastName]);
-- CREATE STATISTICS [stat_cso_DimEmployee_LoadDate] ON [dbo].[DimEmployee]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimEmployee_MaritalStatus] ON [dbo].[DimEmployee]([MaritalStatus]);
-- CREATE STATISTICS [stat_cso_DimEmployee_MiddleName] ON [dbo].[DimEmployee]([MiddleName]);
-- CREATE STATISTICS [stat_cso_DimEmployee_ParentEmployeeKey] ON [dbo].[DimEmployee]([ParentEmployeeKey]);
-- CREATE STATISTICS [stat_cso_DimEmployee_PayFrequency] ON [dbo].[DimEmployee]([PayFrequency]);
-- CREATE STATISTICS [stat_cso_DimEmployee_Phone] ON [dbo].[DimEmployee]([Phone]);
-- CREATE STATISTICS [stat_cso_DimEmployee_SalariedFlag] ON [dbo].[DimEmployee]([SalariedFlag]);
-- CREATE STATISTICS [stat_cso_DimEmployee_SalesPersonFlag] ON [dbo].[DimEmployee]([SalesPersonFlag]);
-- CREATE STATISTICS [stat_cso_DimEmployee_StartDate] ON [dbo].[DimEmployee]([StartDate]);
-- CREATE STATISTICS [stat_cso_DimEmployee_Status] ON [dbo].[DimEmployee]([Status]);
-- CREATE STATISTICS [stat_cso_DimEmployee_Title] ON [dbo].[DimEmployee]([Title]);
-- CREATE STATISTICS [stat_cso_DimEmployee_UpdateDate] ON [dbo].[DimEmployee]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimEmployee_VacationHours] ON [dbo].[DimEmployee]([VacationHours]);
-- CREATE STATISTICS [stat_cso_DimEntity_EndDate] ON [dbo].[DimEntity]([EndDate]);
-- CREATE STATISTICS [stat_cso_DimEntity_EntityDescription] ON [dbo].[DimEntity]([EntityDescription]);
-- CREATE STATISTICS [stat_cso_DimEntity_EntityKey] ON [dbo].[DimEntity]([EntityKey]);
-- CREATE STATISTICS [stat_cso_DimEntity_EntityLabel] ON [dbo].[DimEntity]([EntityLabel]);
-- CREATE STATISTICS [stat_cso_DimEntity_EntityName] ON [dbo].[DimEntity]([EntityName]);
-- CREATE STATISTICS [stat_cso_DimEntity_EntityType] ON [dbo].[DimEntity]([EntityType]);
-- CREATE STATISTICS [stat_cso_DimEntity_ETLLoadID] ON [dbo].[DimEntity]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimEntity_LoadDate] ON [dbo].[DimEntity]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimEntity_ParentEntityKey] ON [dbo].[DimEntity]([ParentEntityKey]);
-- CREATE STATISTICS [stat_cso_DimEntity_ParentEntityLabel] ON [dbo].[DimEntity]([ParentEntityLabel]);
-- CREATE STATISTICS [stat_cso_DimEntity_StartDate] ON [dbo].[DimEntity]([StartDate]);
-- CREATE STATISTICS [stat_cso_DimEntity_Status] ON [dbo].[DimEntity]([Status]);
-- CREATE STATISTICS [stat_cso_DimEntity_UpdateDate] ON [dbo].[DimEntity]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimProduct_AvailableForSaleDate] ON [dbo].[DimProduct]([AvailableForSaleDate]);
-- CREATE STATISTICS [stat_cso_DimProduct_BrandName] ON [dbo].[DimProduct]([BrandName]);
-- CREATE STATISTICS [stat_cso_DimProduct_ClassID] ON [dbo].[DimProduct]([ClassID]);
-- CREATE STATISTICS [stat_cso_DimProduct_ClassName] ON [dbo].[DimProduct]([ClassName]);
-- CREATE STATISTICS [stat_cso_DimProduct_ColorID] ON [dbo].[DimProduct]([ColorID]);
-- CREATE STATISTICS [stat_cso_DimProduct_ColorName] ON [dbo].[DimProduct]([ColorName]);
-- CREATE STATISTICS [stat_cso_DimProduct_ETLLoadID] ON [dbo].[DimProduct]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimProduct_ImageURL] ON [dbo].[DimProduct]([ImageURL]);
-- CREATE STATISTICS [stat_cso_DimProduct_LoadDate] ON [dbo].[DimProduct]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimProduct_Manufacturer] ON [dbo].[DimProduct]([Manufacturer]);
-- CREATE STATISTICS [stat_cso_DimProduct_ProductDescription] ON [dbo].[DimProduct]([ProductDescription]);
-- CREATE STATISTICS [stat_cso_DimProduct_ProductKey] ON [dbo].[DimProduct]([ProductKey]);
-- CREATE STATISTICS [stat_cso_DimProduct_ProductLabel] ON [dbo].[DimProduct]([ProductLabel]);
-- CREATE STATISTICS [stat_cso_DimProduct_ProductName] ON [dbo].[DimProduct]([ProductName]);
-- CREATE STATISTICS [stat_cso_DimProduct_ProductSubcategoryKey] ON [dbo].[DimProduct]([ProductSubcategoryKey]);
-- CREATE STATISTICS [stat_cso_DimProduct_ProductURL] ON [dbo].[DimProduct]([ProductURL]);
-- CREATE STATISTICS [stat_cso_DimProduct_Size] ON [dbo].[DimProduct]([Size]);
-- CREATE STATISTICS [stat_cso_DimProduct_SizeRange] ON [dbo].[DimProduct]([SizeRange]);
-- CREATE STATISTICS [stat_cso_DimProduct_SizeUnitMeasureID] ON [dbo].[DimProduct]([SizeUnitMeasureID]);
-- CREATE STATISTICS [stat_cso_DimProduct_Status] ON [dbo].[DimProduct]([Status]);
-- CREATE STATISTICS [stat_cso_DimProduct_StockTypeID] ON [dbo].[DimProduct]([StockTypeID]);
-- CREATE STATISTICS [stat_cso_DimProduct_StockTypeName] ON [dbo].[DimProduct]([StockTypeName]);
-- CREATE STATISTICS [stat_cso_DimProduct_StopSaleDate] ON [dbo].[DimProduct]([StopSaleDate]);
-- CREATE STATISTICS [stat_cso_DimProduct_StyleID] ON [dbo].[DimProduct]([StyleID]);
-- CREATE STATISTICS [stat_cso_DimProduct_StyleName] ON [dbo].[DimProduct]([StyleName]);
-- CREATE STATISTICS [stat_cso_DimProduct_UnitCost] ON [dbo].[DimProduct]([UnitCost]);
-- CREATE STATISTICS [stat_cso_DimProduct_UnitOfMeasureID] ON [dbo].[DimProduct]([UnitOfMeasureID]);
-- CREATE STATISTICS [stat_cso_DimProduct_UnitOfMeasureName] ON [dbo].[DimProduct]([UnitOfMeasureName]);
-- CREATE STATISTICS [stat_cso_DimProduct_UnitPrice] ON [dbo].[DimProduct]([UnitPrice]);
-- CREATE STATISTICS [stat_cso_DimProduct_UpdateDate] ON [dbo].[DimProduct]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimProduct_Weight] ON [dbo].[DimProduct]([Weight]);
-- CREATE STATISTICS [stat_cso_DimProduct_WeightUnitMeasureID] ON [dbo].[DimProduct]([WeightUnitMeasureID]);
-- CREATE STATISTICS [stat_cso_DimAccount_AccountDescription] ON [dbo].[DimAccount]([AccountDescription]);
-- CREATE STATISTICS [stat_cso_DimAccount_AccountKey] ON [dbo].[DimAccount]([AccountKey]);
-- CREATE STATISTICS [stat_cso_DimAccount_AccountLabel] ON [dbo].[DimAccount]([AccountLabel]);
-- CREATE STATISTICS [stat_cso_DimAccount_AccountName] ON [dbo].[DimAccount]([AccountName]);
-- CREATE STATISTICS [stat_cso_DimAccount_AccountType] ON [dbo].[DimAccount]([AccountType]);
-- CREATE STATISTICS [stat_cso_DimAccount_CustomMemberOptions] ON [dbo].[DimAccount]([CustomMemberOptions]);
-- CREATE STATISTICS [stat_cso_DimAccount_CustomMembers] ON [dbo].[DimAccount]([CustomMembers]);
-- CREATE STATISTICS [stat_cso_DimAccount_ETLLoadID] ON [dbo].[DimAccount]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimAccount_LoadDate] ON [dbo].[DimAccount]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimAccount_Operator] ON [dbo].[DimAccount]([Operator]);
-- CREATE STATISTICS [stat_cso_DimAccount_ParentAccountKey] ON [dbo].[DimAccount]([ParentAccountKey]);
-- CREATE STATISTICS [stat_cso_DimAccount_UpdateDate] ON [dbo].[DimAccount]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimAccount_ValueType] ON [dbo].[DimAccount]([ValueType]);
-- CREATE STATISTICS [stat_cso_DimChannel_ChannelDescription] ON [dbo].[DimChannel]([ChannelDescription]);
-- CREATE STATISTICS [stat_cso_DimChannel_ChannelKey] ON [dbo].[DimChannel]([ChannelKey]);
-- CREATE STATISTICS [stat_cso_DimChannel_ChannelLabel] ON [dbo].[DimChannel]([ChannelLabel]);
-- CREATE STATISTICS [stat_cso_DimChannel_ChannelName] ON [dbo].[DimChannel]([ChannelName]);
-- CREATE STATISTICS [stat_cso_DimChannel_ETLLoadID] ON [dbo].[DimChannel]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimChannel_LoadDate] ON [dbo].[DimChannel]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimChannel_UpdateDate] ON [dbo].[DimChannel]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimCurrency_CurrencyDescription] ON [dbo].[DimCurrency]([CurrencyDescription]);
-- CREATE STATISTICS [stat_cso_DimCurrency_CurrencyKey] ON [dbo].[DimCurrency]([CurrencyKey]);
-- CREATE STATISTICS [stat_cso_DimCurrency_CurrencyLabel] ON [dbo].[DimCurrency]([CurrencyLabel]);
-- CREATE STATISTICS [stat_cso_DimCurrency_CurrencyName] ON [dbo].[DimCurrency]([CurrencyName]);
-- CREATE STATISTICS [stat_cso_DimCurrency_ETLLoadID] ON [dbo].[DimCurrency]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimCurrency_LoadDate] ON [dbo].[DimCurrency]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimCurrency_UpdateDate] ON [dbo].[DimCurrency]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimDate_AsiaSeason] ON [dbo].[DimDate]([AsiaSeason]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarDayOfWeek] ON [dbo].[DimDate]([CalendarDayOfWeek]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarDayOfWeekLabel] ON [dbo].[DimDate]([CalendarDayOfWeekLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarHalfYear] ON [dbo].[DimDate]([CalendarHalfYear]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarHalfYearLabel] ON [dbo].[DimDate]([CalendarHalfYearLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarMonth] ON [dbo].[DimDate]([CalendarMonth]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarMonthLabel] ON [dbo].[DimDate]([CalendarMonthLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarQuarter] ON [dbo].[DimDate]([CalendarQuarter]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarQuarterLabel] ON [dbo].[DimDate]([CalendarQuarterLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarWeek] ON [dbo].[DimDate]([CalendarWeek]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarWeekLabel] ON [dbo].[DimDate]([CalendarWeekLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarYear] ON [dbo].[DimDate]([CalendarYear]);
-- CREATE STATISTICS [stat_cso_DimDate_CalendarYearLabel] ON [dbo].[DimDate]([CalendarYearLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_DateDescription] ON [dbo].[DimDate]([DateDescription]);
-- CREATE STATISTICS [stat_cso_DimDate_Datekey] ON [dbo].[DimDate]([Datekey]);
-- CREATE STATISTICS [stat_cso_DimDate_EuropeSeason] ON [dbo].[DimDate]([EuropeSeason]);
-- CREATE STATISTICS [stat_cso_DimDate_FiscalHalfYear] ON [dbo].[DimDate]([FiscalHalfYear]);
-- CREATE STATISTICS [stat_cso_DimDate_FiscalHalfYearLabel] ON [dbo].[DimDate]([FiscalHalfYearLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_FiscalMonth] ON [dbo].[DimDate]([FiscalMonth]);
-- CREATE STATISTICS [stat_cso_DimDate_FiscalMonthLabel] ON [dbo].[DimDate]([FiscalMonthLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_FiscalQuarter] ON [dbo].[DimDate]([FiscalQuarter]);
-- CREATE STATISTICS [stat_cso_DimDate_FiscalQuarterLabel] ON [dbo].[DimDate]([FiscalQuarterLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_FiscalYear] ON [dbo].[DimDate]([FiscalYear]);
-- CREATE STATISTICS [stat_cso_DimDate_FiscalYearLabel] ON [dbo].[DimDate]([FiscalYearLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_FullDateLabel] ON [dbo].[DimDate]([FullDateLabel]);
-- CREATE STATISTICS [stat_cso_DimDate_HolidayName] ON [dbo].[DimDate]([HolidayName]);
-- CREATE STATISTICS [stat_cso_DimDate_IsHoliday] ON [dbo].[DimDate]([IsHoliday]);
-- CREATE STATISTICS [stat_cso_DimDate_IsWorkDay] ON [dbo].[DimDate]([IsWorkDay]);
-- CREATE STATISTICS [stat_cso_DimDate_NorthAmericaSeason] ON [dbo].[DimDate]([NorthAmericaSeason]);
-- CREATE STATISTICS [stat_cso_DimStore_AddressLine1] ON [dbo].[DimStore]([AddressLine1]);
-- CREATE STATISTICS [stat_cso_DimStore_AddressLine2] ON [dbo].[DimStore]([AddressLine2]);
-- CREATE STATISTICS [stat_cso_DimStore_CloseDate] ON [dbo].[DimStore]([CloseDate]);
-- CREATE STATISTICS [stat_cso_DimStore_CloseReason] ON [dbo].[DimStore]([CloseReason]);
-- CREATE STATISTICS [stat_cso_DimStore_EmployeeCount] ON [dbo].[DimStore]([EmployeeCount]);
-- CREATE STATISTICS [stat_cso_DimStore_EntityKey] ON [dbo].[DimStore]([EntityKey]);
-- CREATE STATISTICS [stat_cso_DimStore_ETLLoadID] ON [dbo].[DimStore]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimStore_GeographyKey] ON [dbo].[DimStore]([GeographyKey]);
-- CREATE STATISTICS [stat_cso_DimStore_GeoLocation] ON [dbo].[DimStore]([GeoLocation]);
-- CREATE STATISTICS [stat_cso_DimStore_Geometry] ON [dbo].[DimStore]([Geometry]);
-- CREATE STATISTICS [stat_cso_DimStore_LastRemodelDate] ON [dbo].[DimStore]([LastRemodelDate]);
-- CREATE STATISTICS [stat_cso_DimStore_LoadDate] ON [dbo].[DimStore]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimStore_OpenDate] ON [dbo].[DimStore]([OpenDate]);
-- CREATE STATISTICS [stat_cso_DimStore_SellingAreaSize] ON [dbo].[DimStore]([SellingAreaSize]);
-- CREATE STATISTICS [stat_cso_DimStore_Status] ON [dbo].[DimStore]([Status]);
-- CREATE STATISTICS [stat_cso_DimStore_StoreDescription] ON [dbo].[DimStore]([StoreDescription]);
-- CREATE STATISTICS [stat_cso_DimStore_StoreFax] ON [dbo].[DimStore]([StoreFax]);
-- CREATE STATISTICS [stat_cso_DimStore_StoreKey] ON [dbo].[DimStore]([StoreKey]);
-- CREATE STATISTICS [stat_cso_DimStore_StoreManager] ON [dbo].[DimStore]([StoreManager]);
-- CREATE STATISTICS [stat_cso_DimStore_StoreName] ON [dbo].[DimStore]([StoreName]);
-- CREATE STATISTICS [stat_cso_DimStore_StorePhone] ON [dbo].[DimStore]([StorePhone]);
-- CREATE STATISTICS [stat_cso_DimStore_StoreType] ON [dbo].[DimStore]([StoreType]);
-- CREATE STATISTICS [stat_cso_DimStore_UpdateDate] ON [dbo].[DimStore]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_DimStore_ZipCode] ON [dbo].[DimStore]([ZipCode]);
-- CREATE STATISTICS [stat_cso_DimStore_ZipCodeExtension] ON [dbo].[DimStore]([ZipCodeExtension]);
-- CREATE STATISTICS [stat_cso_DimGeography_CityName] ON [dbo].[DimGeography]([CityName]);
-- CREATE STATISTICS [stat_cso_DimGeography_ContinentName] ON [dbo].[DimGeography]([ContinentName]);
-- CREATE STATISTICS [stat_cso_DimGeography_ETLLoadID] ON [dbo].[DimGeography]([ETLLoadID]);
-- CREATE STATISTICS [stat_cso_DimGeography_GeographyKey] ON [dbo].[DimGeography]([GeographyKey]);
-- CREATE STATISTICS [stat_cso_DimGeography_GeographyType] ON [dbo].[DimGeography]([GeographyType]);
-- CREATE STATISTICS [stat_cso_DimGeography_LoadDate] ON [dbo].[DimGeography]([LoadDate]);
-- CREATE STATISTICS [stat_cso_DimGeography_RegionCountryName] ON [dbo].[DimGeography]([RegionCountryName]);
-- CREATE STATISTICS [stat_cso_DimGeography_StateProvinceName] ON [dbo].[DimGeography]([StateProvinceName]);
-- CREATE STATISTICS [stat_cso_DimGeography_UpdateDate] ON [dbo].[DimGeography]([UpdateDate]);
-- CREATE STATISTICS [stat_cso_FactITMachine_Datekey] ON [dbo].[FactITMachine]([Datekey]);
-- CREATE STATISTICS [stat_cso_FactITMachine_ITMachinekey] ON [dbo].[FactITMachine]([ITMachinekey]);
-- CREATE STATISTICS [stat_cso_FactITMachine_MachineKey] ON [dbo].[FactITMachine]([MachineKey]);
-- CREATE STATISTICS [stat_cso_FactInventory_CurrencyKey] ON [dbo].[FactInventory]([CurrencyKey]);
-- CREATE STATISTICS [stat_cso_FactInventory_DateKey] ON [dbo].[FactInventory]([DateKey]);
-- CREATE STATISTICS [stat_cso_FactInventory_InventoryKey] ON [dbo].[FactInventory]([InventoryKey]);
-- CREATE STATISTICS [stat_cso_FactInventory_ProductKey] ON [dbo].[FactInventory]([ProductKey]);
-- CREATE STATISTICS [stat_cso_FactInventory_StoreKey] ON [dbo].[FactInventory]([StoreKey]);
-- CREATE STATISTICS [stat_cso_FactOnlineSales_CurrencyKey] ON [dbo].[FactOnlineSales]([CurrencyKey]);
-- CREATE STATISTICS [stat_cso_FactOnlineSales_CustomerKey] ON [dbo].[FactOnlineSales]([CustomerKey]);
-- CREATE STATISTICS [stat_cso_FactOnlineSales_DateKey] ON [dbo].[FactOnlineSales]([DateKey]);
-- CREATE STATISTICS [stat_cso_FactOnlineSales_OnlineSalesKey] ON [dbo].[FactOnlineSales]([OnlineSalesKey]);
-- CREATE STATISTICS [stat_cso_FactOnlineSales_ProductKey] ON [dbo].[FactOnlineSales]([ProductKey]);
-- CREATE STATISTICS [stat_cso_FactOnlineSales_PromotionKey] ON [dbo].[FactOnlineSales]([PromotionKey]);
-- CREATE STATISTICS [stat_cso_FactOnlineSales_StoreKey] ON [dbo].[FactOnlineSales]([StoreKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_AccountKey] ON [dbo].[FactStrategyPlan]([AccountKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_CurrencyKey] ON [dbo].[FactStrategyPlan]([CurrencyKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_Datekey] ON [dbo].[FactStrategyPlan]([Datekey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_EntityKey] ON [dbo].[FactStrategyPlan]([EntityKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_ProductCategoryKey] ON [dbo].[FactStrategyPlan]([ProductCategoryKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_ScenarioKey] ON [dbo].[FactStrategyPlan]([ScenarioKey]);
CREATE STATISTICS [stat_cso_FactStrategyPlan_StrategyPlanKey] ON [dbo].[FactStrategyPlan]([StrategyPlanKey]);
-- CREATE STATISTICS [stat_cso_FactSalesQuota_ChannelKey] ON [dbo].[FactSalesQuota]([ChannelKey]);
-- CREATE STATISTICS [stat_cso_FactSalesQuota_CurrencyKey] ON [dbo].[FactSalesQuota]([CurrencyKey]);
-- CREATE STATISTICS [stat_cso_FactSalesQuota_DateKey] ON [dbo].[FactSalesQuota]([DateKey]);
-- CREATE STATISTICS [stat_cso_FactSalesQuota_ProductKey] ON [dbo].[FactSalesQuota]([ProductKey]);
-- CREATE STATISTICS [stat_cso_FactSalesQuota_SalesQuotaKey] ON [dbo].[FactSalesQuota]([SalesQuotaKey]);
-- CREATE STATISTICS [stat_cso_FactSalesQuota_ScenarioKey] ON [dbo].[FactSalesQuota]([ScenarioKey]);
-- CREATE STATISTICS [stat_cso_FactSalesQuota_StoreKey] ON [dbo].[FactSalesQuota]([StoreKey]);
-- CREATE STATISTICS [stat_cso_FactSales_channelKey] ON [dbo].[FactSales]([channelKey]);
-- CREATE STATISTICS [stat_cso_FactSales_CurrencyKey] ON [dbo].[FactSales]([CurrencyKey]);
-- CREATE STATISTICS [stat_cso_FactSales_DateKey] ON [dbo].[FactSales]([DateKey]);
-- CREATE STATISTICS [stat_cso_FactSales_ProductKey] ON [dbo].[FactSales]([ProductKey]);
-- CREATE STATISTICS [stat_cso_FactSales_PromotionKey] ON [dbo].[FactSales]([PromotionKey]);
-- CREATE STATISTICS [stat_cso_FactSales_SalesKey] ON [dbo].[FactSales]([SalesKey]);
-- CREATE STATISTICS [stat_cso_FactSales_StoreKey] ON [dbo].[FactSales]([StoreKey]);
GO


CREATE NONCLUSTERED INDEX [IX_DimAccount] ON [dbo].[DimAccount] (AccountType ASC)
CREATE NONCLUSTERED INDEX [IX_DimProduct] ON [dbo].[DimProduct] (BrandName ASC)
GO


/*
DROP TABLE [dbo].[DimAccount]
DROP TABLE [dbo].[DimChannel]
DROP TABLE [dbo].[DimCurrency]
DROP TABLE [dbo].[DimCustomer] 
DROP TABLE [dbo].[DimDate]     
DROP TABLE [dbo].[DimEmployee] 
DROP TABLE [dbo].[DimEntity]   
DROP TABLE [dbo].[DimGeography]
DROP TABLE [dbo].[DimMachine]  
DROP TABLE [dbo].[DimOutage]   
DROP TABLE [dbo].[DimProduct]  
DROP TABLE [dbo].[DimProductCategory]
DROP TABLE [dbo].[DimScenario]  
DROP TABLE [dbo].[DimPromotion] 
DROP TABLE [dbo].[DimProductSubcategory]
DROP TABLE [dbo].[DimSalesTerritory]    
DROP TABLE [dbo].[DimStore]  
DROP TABLE [dbo].[FactITMachine]
DROP TABLE [dbo].[FactITSLA]  
DROP TABLE [dbo].[FactInventory] 
DROP TABLE [dbo].[FactOnlineSales] 
DROP TABLE [dbo].[FactSales]      
DROP TABLE [dbo].[FactSalesQuota] 
DROP TABLE [dbo].[FactStrategyPlan] 

DROP TABLE [asb].[DimAccount]
DROP TABLE [asb].[DimChannel]
DROP TABLE [asb].[DimCurrency]
DROP TABLE [asb].[DimCustomer] 
DROP TABLE [asb].[DimDate]     
DROP TABLE [asb].[DimEmployee] 
DROP TABLE [asb].[DimEntity]   
DROP TABLE [asb].[DimGeography]
DROP TABLE [asb].[DimMachine]  
DROP TABLE [asb].[DimOutage]   
DROP TABLE [asb].[DimProduct]  
DROP TABLE [asb].[DimProductCategory]
DROP TABLE [asb].[DimScenario]  
DROP TABLE [asb].[DimPromotion] 
DROP TABLE [asb].[DimProductSubcategory]
DROP TABLE [asb].[DimSalesTerritory]    
DROP TABLE [asb].[DimStore]  
DROP TABLE [asb].[FactITMachine]
DROP TABLE [asb].[FactITSLA]  
DROP TABLE [asb].[FactInventory] 
DROP TABLE [asb].[FactOnlineSales] 
DROP TABLE [asb].[FactSales]      
DROP TABLE [asb].[FactSalesQuota] 
DROP TABLE [asb].[FactStrategyPlan] 

DROP TABLE [EXT_cso].[DimAccount]
DROP TABLE [EXT_cso].[DimChannel]
DROP TABLE [EXT_cso].[DimCurrency]
DROP TABLE [EXT_cso].[DimCustomer] 
DROP TABLE [EXT_cso].[DimDate]     
DROP TABLE [EXT_cso].[DimEmployee] 
DROP TABLE [EXT_cso].[DimEntity]   
DROP TABLE [EXT_cso].[DimGeography]
DROP TABLE [EXT_cso].[DimMachine]  
DROP TABLE [EXT_cso].[DimOutage]   
DROP TABLE [EXT_cso].[DimProduct]  
DROP TABLE [EXT_cso].[DimProductCategory]
DROP TABLE [EXT_cso].[DimScenario]  
DROP TABLE [EXT_cso].[DimPromotion] 
DROP TABLE [EXT_cso].[DimProductSubcategory]
DROP TABLE [EXT_cso].[DimSalesTerritory]    
DROP TABLE [EXT_cso].[DimStore]  
DROP TABLE [EXT_cso].[FactITMachine]
DROP TABLE [EXT_cso].[FactITSLA]  
DROP TABLE [EXT_cso].[FactInventory] 
DROP TABLE [EXT_cso].[FactOnlineSales] 
DROP TABLE [EXT_cso].[FactSales]      
DROP TABLE [EXT_cso].[FactSalesQuota] 
DROP TABLE [EXT_cso].[FactStrategyPlan] 
GO
*/
