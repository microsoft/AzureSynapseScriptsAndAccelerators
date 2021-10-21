/*
USE master
GO

SELECT  * FROM sys.databases
GO

DROP DATABASE AdventureWorksDW
GO

CREATE DATABASE AdventureWorksDW WITH (autogrow = on, replicated_size = 0.0625, distributed_size = 1, log_size = 0.2);
GO
*/


CREATE TABLE AdventureWorksDWBuildVersion(
	DBVersion nvarchar(50) NOT NULL,
	VersionDate datetime NOT NULL)
WITH (DISTRIBUTION = REPLICATE);
GO

CREATE TABLE DatabaseLog(
	DatabaseLogID int NOT NULL,
	PostTime datetime NOT NULL,
	DatabaseUser nvarchar(128) NOT NULL,
	Event nvarchar(128) NOT NULL,
	[Schema] nvarchar(128),
	[Object] nvarchar(128),
	TSQL nvarchar(4000) NOT NULL)
WITH (CLUSTERED INDEX(DatabaseLogID), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimAccount(
	AccountKey int NOT NULL,
	ParentAccountKey int,
	AccountCodeAlternateKey int,
	ParentAccountCodeAlternateKey int,
	AccountDescription nvarchar(50),
	AccountType nvarchar(50),
	Operator nvarchar(50),
	CustomMembers nvarchar(300),
	ValueType nvarchar(50),
	CustomMemberOptions nvarchar(200))
WITH (CLUSTERED INDEX(AccountKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimCurrency(
	CurrencyKey int NOT NULL,
	CurrencyAlternateKey nchar(3) NOT NULL, 
	CurrencyName nvarchar(50) NOT NULL)
WITH (CLUSTERED INDEX(CurrencyKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimCustomer(
	CustomerKey int NOT NULL,
	GeographyKey int,
	CustomerAlternateKey nvarchar(15) NOT NULL, 
	Title nvarchar(8),
	FirstName nvarchar(50),
	MiddleName nvarchar(50),
	LastName nvarchar(50),
	NameStyle bit,
	BirthDate date,
	MaritalStatus nchar(1),
	Suffix nvarchar(10),
	Gender nvarchar(1),
	EmailAddress nvarchar(50),
	YearlyIncome money,
	TotalChildren tinyint,
	NumberChildrenAtHome tinyint,
	EnglishEducation nvarchar(40),
	SpanishEducation nvarchar(40),
	FrenchEducation nvarchar(40),
	EnglishOccupation nvarchar(100),
	SpanishOccupation nvarchar(100),
	FrenchOccupation nvarchar(100),
	HouseOwnerFlag nchar(1),
	NumberCarsOwned tinyint,
	AddressLine1 nvarchar(120),
	AddressLine2 nvarchar(120),
	Phone nvarchar(20),
	DateFirstPurchase date,
	CommuteDistance nvarchar(15))
WITH (CLUSTERED INDEX(CustomerKey), DISTRIBUTION = HASH(CustomerKey))
GO

CREATE TABLE DimDate(
	DateKey int NOT NULL,
	FullDateAlternateKey date NOT NULL, 
	DayNumberOfWeek tinyint NOT NULL,
	EnglishDayNameOfWeek nvarchar(10) NOT NULL,
	SpanishDayNameOfWeek nvarchar(10) NOT NULL,
	FrenchDayNameOfWeek nvarchar(10) NOT NULL,
	DayNumberOfMonth tinyint NOT NULL,
	DayNumberOfYear smallint NOT NULL,
	WeekNumberOfYear tinyint NOT NULL,
	EnglishMonthName nvarchar(10) NOT NULL,
	SpanishMonthName nvarchar(10) NOT NULL,
	FrenchMonthName nvarchar(10) NOT NULL,
	MonthNumberOfYear tinyint NOT NULL,
	CalendarQuarter tinyint NOT NULL,
	CalendarYear smallint NOT NULL,
	CalendarSemester tinyint NOT NULL,
	FiscalQuarter tinyint NOT NULL,
	FiscalYear smallint NOT NULL,
	FiscalSemester tinyint NOT NULL)
WITH (CLUSTERED INDEX(DateKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimDepartmentGroup(
	DepartmentGroupKey int NOT NULL,
	ParentDepartmentGroupKey int,
	DepartmentGroupName nvarchar(50))
WITH (CLUSTERED INDEX(DepartmentGroupKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimEmployee(
	EmployeeKey int NOT NULL,
	ParentEmployeeKey int,
	EmployeeNationalIDAlternateKey nvarchar(15), 
	ParentEmployeeNationalIDAlternateKey nvarchar(15), 
	SalesTerritoryKey int,
	FirstName nvarchar(50) NOT NULL,
	LastName nvarchar(50) NOT NULL,
	MiddleName nvarchar(50),
	NameStyle bit NOT NULL,
	Title nvarchar(50),
	HireDate date,
	BirthDate date,
	LoginID nvarchar(256),
	EmailAddress nvarchar(50),
	Phone nvarchar(25),
	MaritalStatus nchar(1),
	EmergencyContactName nvarchar(50),
	EmergencyContactPhone nvarchar(25),
	SalariedFlag bit,
	Gender nchar(1),
	PayFrequency tinyint,
	BaseRate money,
	VacationHours smallint,
	SickLeaveHours smallint,
	CurrentFlag bit NOT NULL,
	SalesPersonFlag bit NOT NULL,
	DepartmentName nvarchar(50),
	StartDate date,
	EndDate date,
	Status nvarchar(50)) 
WITH (CLUSTERED INDEX(EmployeeKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimGeography(
	GeographyKey int NOT NULL,
	City nvarchar(30),
	StateProvinceCode nvarchar(3),
	StateProvinceName nvarchar(50),
	CountryRegionCode nvarchar(3),
	EnglishCountryRegionName nvarchar(50),
	SpanishCountryRegionName nvarchar(50),
	FrenchCountryRegionName nvarchar(50),
	PostalCode nvarchar(15),
	SalesTerritoryKey int)
WITH (CLUSTERED INDEX(GeographyKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimOrganization(
	OrganizationKey int NOT NULL,
	ParentOrganizationKey int,
	PercentageOfOwnership nvarchar(16),
	OrganizationName nvarchar(50),
	CurrencyKey int)
WITH (CLUSTERED INDEX(OrganizationKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimProduct(
	ProductKey int NOT NULL,
	ProductAlternateKey nvarchar(25),		
	ProductSubcategoryKey int,
	WeightUnitMeasureCode nchar(3),
	SizeUnitMeasureCode nchar(3),
	EnglishProductName nvarchar(50) NOT NULL,
	SpanishProductName nvarchar(50),
	FrenchProductName nvarchar(50),
	StandardCost money,
	FinishedGoodsFlag bit NOT NULL,
	Color nvarchar(15) NOT NULL,
	SafetyStockLevel smallint,
	ReorderPoint smallint,
	ListPrice money,
	[Size] nvarchar(50),
	SizeRange nvarchar(50),
	Weight float,
	DaysToManufacture integer,
	ProductLine nchar(2),
	DealerPrice money,
	[Class] nchar(2),
	Style nchar(2),
	ModelName nvarchar(50),
	EnglishDescription nvarchar(400),
	FrenchDescription nvarchar(400),
	ChineseDescription nvarchar(400),
	ArabicDescription nvarchar(400),
	HebrewDescription nvarchar(400),
	ThaiDescription nvarchar(400),
	GermanDescription nvarchar(400),
	JapaneseDescription nvarchar(400),
	TurkishDescription nvarchar(400),
	StartDate datetime,
	EndDate datetime,
	Status nvarchar(7))
WITH (CLUSTERED INDEX(ProductKey), DISTRIBUTION = HASH(ProductKey))
GO

CREATE TABLE DimProductCategory(
	ProductCategoryKey int NOT NULL,
	ProductCategoryAlternateKey int,		
	EnglishProductCategoryName nvarchar(50) NOT NULL,
	SpanishProductCategoryName nvarchar(50) NOT NULL,
	FrenchProductCategoryName nvarchar(50) NOT NULL)
WITH (CLUSTERED INDEX(ProductCategoryKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimProductSubcategory(
	ProductSubcategoryKey int NOT NULL,
	ProductSubcategoryAlternateKey int, 
	EnglishProductSubcategoryName nvarchar(50) NOT NULL,
	SpanishProductSubcategoryName nvarchar(50) NOT NULL,
	FrenchProductSubcategoryName nvarchar(50) NOT NULL,
	ProductCategoryKey int)
WITH (CLUSTERED INDEX(ProductSubcategoryKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimPromotion(
	PromotionKey int NOT NULL,
	PromotionAlternateKey int,	
	EnglishPromotionName nvarchar(255),
	SpanishPromotionName nvarchar(255),
	FrenchPromotionName nvarchar(255),
	DiscountPct float,
	EnglishPromotionType nvarchar(50),
	SpanishPromotionType nvarchar(50),
	FrenchPromotionType nvarchar(50),
	EnglishPromotionCategory nvarchar(50),
	SpanishPromotionCategory nvarchar(50),
	FrenchPromotionCategory nvarchar(50),
	StartDate datetime NOT NULL,
	EndDate datetime,
	MinQty int,
	MaxQty int)
WITH (CLUSTERED INDEX(PromotionKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimReseller(
	ResellerKey int NOT NULL,
	GeographyKey int,
	ResellerAlternateKey nvarchar(15), 
	Phone nvarchar(25),
	BusinessType varchar(20) NOT NULL,
	ResellerName nvarchar(50) NOT NULL,
	NumberEmployees int,
	OrderFrequency char(1),
	OrderMonth tinyint,
	FirstOrderYear int,
	LastOrderYear int,
	ProductLine nvarchar(50),
	AddressLine1 nvarchar(60),
	AddressLine2 nvarchar(60),
	AnnualSales money,
	BankName nvarchar(50),
	MinPaymentType tinyint,
	MinPaymentAmount money,
	AnnualRevenue money,
	YearOpened int)
WITH (CLUSTERED INDEX(ResellerKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimSalesReason(
	SalesReasonKey int NOT NULL,
	SalesReasonAlternateKey int NOT NULL,
	SalesReasonName nvarchar(50) NOT NULL,
	SalesReasonReasonType nvarchar(50) NOT NULL)
WITH (CLUSTERED INDEX(SalesReasonKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimSalesTerritory(
	SalesTerritoryKey int NOT NULL,
	SalesTerritoryAlternateKey int,
	SalesTerritoryRegion nvarchar(50) NOT NULL,
	SalesTerritoryCountry nvarchar(50) NOT NULL,
	SalesTerritoryGroup nvarchar(50))
WITH (CLUSTERED INDEX(SalesTerritoryKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE DimScenario(
	ScenarioKey int NOT NULL,
	ScenarioName nvarchar(50))
WITH (CLUSTERED INDEX(ScenarioKey), DISTRIBUTION = REPLICATE)
GO

CREATE TABLE FactCallCenter(
	FactCallCenterID int NOT NULL,
	DateKey int NOT NULL,
	WageType nvarchar(15) NOT NULL,
	Shift nvarchar(20) NOT NULL,
	LevelOneOperators smallint NOT NULL,
	LevelTwoOperators smallint NOT NULL,
	TotalOperators smallint NOT NULL,
	Calls int NOT NULL,
	AutomaticResponses int NOT NULL,
	Orders int NOT NULL,
	IssuesRaised smallint NOT NULL,
	AverageTimePerIssue smallint NOT NULL,
	ServiceGrade float NOT NULL)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH(FactCallCenterID))
GO

CREATE TABLE FactCurrencyRate(
	CurrencyKey int NOT NULL,
	DateKey int NOT NULL,
	AverageRate float NOT NULL,
	EndOfDayRate float NOT NULL)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = REPLICATE)
GO

CREATE TABLE FactFinance(
	FinanceKey int NOT NULL,
	DateKey int NOT NULL,
	OrganizationKey int NOT NULL,
	DepartmentGroupKey int NOT NULL,
	ScenarioKey int NOT NULL,
	AccountKey int NOT NULL,
	Amount float NOT NULL) 
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH(FinanceKey))
GO

CREATE TABLE FactInternetSales(
	ProductKey int NOT NULL,
	OrderDateKey int NOT NULL,
	DueDateKey int NOT NULL,
	ShipDateKey int NOT NULL,
	CustomerKey int NOT NULL,
	PromotionKey int NOT NULL,
	CurrencyKey int NOT NULL,
	SalesTerritoryKey int NOT NULL,
	SalesOrderNumber nvarchar(20) NOT NULL,
	SalesOrderLineNumber tinyint NOT NULL,
	RevisionNumber tinyint NOT NULL,
	OrderQuantity smallint NOT NULL,
	UnitPrice money NOT NULL,
	ExtendedAmount money NOT NULL,
	UnitPriceDiscountPct float NOT NULL,
	DiscountAmount float NOT NULL,
	ProductStandardCost money NOT NULL,
	TotalProductCost money NOT NULL,
	SalesAmount money NOT NULL,
	TaxAmt money NOT NULL,
	Freight money NOT NULL,
	CarrierTrackingNumber nvarchar(25),
	CustomerPONumber nvarchar(25))
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH(OrderDateKey),
PARTITION(OrderDateKey
RANGE RIGHT FOR VALUES (
20000101,20010101,20020101,20030101,20040101,20050101,20060101,20070101,20080101,20090101,
20100101,20110101,20120101,20130101,20140101,20150101,20160101,20170101,20180101,20190101,
20200101,20210101,20220101,20230101,20240101,20250101,20260101,20270101,20280101,20290101)))
GO

CREATE TABLE FactInternetSalesReason(
	SalesOrderNumber nvarchar(20) NOT NULL,
	SalesOrderLineNumber tinyint NOT NULL,
	SalesReasonKey int NOT NULL)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = REPLICATE)
GO

CREATE TABLE ProspectiveBuyer(
	ProspectiveBuyerKey int NOT NULL,
	ProspectAlternateKey nvarchar(15),
	FirstName nvarchar(50),
	MiddleName nvarchar(50),
	LastName nvarchar(50),
	BirthDate datetime,
	MaritalStatus nchar(1),
	Gender nvarchar(1),
	EmailAddress nvarchar(50),
	YearlyIncome money,
	TotalChildren tinyint,
	NumberChildrenAtHome tinyint,
	Education nvarchar(40),
	Occupation nvarchar(100),
	HouseOwnerFlag nchar(1),
	NumberCarsOwned tinyint,
	AddressLine1 nvarchar(120),
	AddressLine2 nvarchar(120),
	City nvarchar(30),
	StateProvinceCode nvarchar(3),
	PostalCode nvarchar(15),
	Phone nvarchar(20),
	Salutation nvarchar(8),
	[Unknown] int)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH(ProspectiveBuyerKey))
GO

CREATE TABLE FactResellerSales(
	ProductKey int NOT NULL,
	OrderDateKey int NOT NULL,
	DueDateKey int NOT NULL,
	ShipDateKey int NOT NULL,
	ResellerKey int NOT NULL,
	EmployeeKey int NOT NULL,
	PromotionKey int NOT NULL,
	CurrencyKey int NOT NULL,
	SalesTerritoryKey int NOT NULL,
	SalesOrderNumber nvarchar(20) NOT NULL,
	SalesOrderLineNumber tinyint NOT NULL,
	RevisionNumber tinyint,
	OrderQuantity smallint,
	UnitPrice money,
	ExtendedAmount money,
	UnitPriceDiscountPct float,
	DiscountAmount float,
	ProductStandardCost money,
	TotalProductCost money,
	SalesAmount money,
	TaxAmt money,
	Freight money,
	CarrierTrackingNumber nvarchar(25),
	CustomerPONumber nvarchar(25))
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH(OrderDateKey),
PARTITION(OrderDateKey
RANGE RIGHT FOR VALUES (
20000101,20010101,20020101,20030101,20040101,20050101,20060101,20070101,20080101,20090101,
20100101,20110101,20120101,20130101,20140101,20150101,20160101,20170101,20180101,20190101,
20200101,20210101,20220101,20230101,20240101,20250101,20260101,20270101,20280101,20290101)))
GO

CREATE TABLE FactSalesQuota(
	SalesQuotaKey int NOT NULL,
	EmployeeKey int NOT NULL,
	DateKey int NOT NULL,
	CalendarYear smallint NOT NULL,
	CalendarQuarter tinyint NOT NULL,
	SalesAmountQuota money NOT NULL)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH(SalesQuotaKey))
GO

CREATE TABLE FactSurveyResponse(
	SurveyResponseKey int NOT NULL,
	DateKey int NOT NULL,
	CustomerKey int NOT NULL,
	ProductCategoryKey int NOT NULL,
	EnglishProductCategoryName nvarchar(50) NOT NULL,
	ProductSubcategoryKey int NOT NULL,
	EnglishProductSubcategoryName nvarchar(50) NOT NULL)
WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION = HASH(CustomerKey))
GO



-- ===========================================================================================================================================
-- External Tables ---------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================

CREATE MASTER KEY ENCRYPTION BY PASSWORD='pass@word1';
GO


CREATE EXTERNAL DATA SOURCE AzureStorageImport
WITH 
(  
    TYPE = HADOOP 
,   LOCATION = 'wasbs://adventureworksdw@sqldwsamplesdefault.blob.core.windows.net/'
); 
GO


CREATE EXTERNAL FILE FORMAT TextFileFormat 
WITH 
(   FORMAT_TYPE = DELIMITEDTEXT
,	FORMAT_OPTIONS	(   FIELD_TERMINATOR = '|'
					,	STRING_DELIMITER = ''
					,	DATE_FORMAT		 = 'yyyy-MM-dd'
					,	USE_TYPE_DEFAULT = FALSE 
					)
);
GO


CREATE EXTERNAL FILE FORMAT TextFileFormatDateTime
WITH 
(   FORMAT_TYPE = DELIMITEDTEXT
,	FORMAT_OPTIONS	(   FIELD_TERMINATOR = '|'
					,	STRING_DELIMITER = ''
					,	DATE_FORMAT		 = 'yyyy-MM-dd HH:mm:ss.fff'
					,	USE_TYPE_DEFAULT = FALSE 
					)
);
GO


CREATE SCHEMA [asb];
GO

CREATE EXTERNAL TABLE [asb].DimAccount 
(
	AccountKey int NOT NULL,
	ParentAccountKey int,
	AccountCodeAlternateKey int,
	ParentAccountCodeAlternateKey int,
	AccountDescription nvarchar(50),
	AccountType nvarchar(50),
	Operator nvarchar(50),
	CustomMembers nvarchar(300),
	ValueType nvarchar(50),
	CustomMemberOptions nvarchar(200)
)
WITH 
(
    LOCATION='/DimAccount.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormatDateTime
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimCurrency(
	CurrencyKey int NOT NULL,
	CurrencyAlternateKey nchar(3) NOT NULL, 
	CurrencyName nvarchar(50) NOT NULL)
WITH 
(
    LOCATION='/DimCurrency.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimCustomer(
	CustomerKey int NOT NULL,
	GeographyKey int,
	CustomerAlternateKey nvarchar(15) NOT NULL, 
	Title nvarchar(8),
	FirstName nvarchar(50),
	MiddleName nvarchar(50),
	LastName nvarchar(50),
	NameStyle bit,
	BirthDate date,
	MaritalStatus nchar(1),
	Suffix nvarchar(10),
	Gender nvarchar(1),
	EmailAddress nvarchar(50),
	YearlyIncome money,
	TotalChildren tinyint,
	NumberChildrenAtHome tinyint,
	EnglishEducation nvarchar(40),
	SpanishEducation nvarchar(40),
	FrenchEducation nvarchar(40),
	EnglishOccupation nvarchar(100),
	SpanishOccupation nvarchar(100),
	FrenchOccupation nvarchar(100),
	HouseOwnerFlag nchar(1),
	NumberCarsOwned tinyint,
	AddressLine1 nvarchar(120),
	AddressLine2 nvarchar(120),
	Phone nvarchar(20),
	DateFirstPurchase date,
	CommuteDistance nvarchar(15))
WITH 
(
    LOCATION='/DimCustomer.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimDate(
	DateKey int NOT NULL,
	FullDateAlternateKey date NOT NULL, 
	DayNumberOfWeek tinyint NOT NULL,
	EnglishDayNameOfWeek nvarchar(10) NOT NULL,
	SpanishDayNameOfWeek nvarchar(10) NOT NULL,
	FrenchDayNameOfWeek nvarchar(10) NOT NULL,
	DayNumberOfMonth tinyint NOT NULL,
	DayNumberOfYear smallint NOT NULL,
	WeekNumberOfYear tinyint NOT NULL,
	EnglishMonthName nvarchar(10) NOT NULL,
	SpanishMonthName nvarchar(10) NOT NULL,
	FrenchMonthName nvarchar(10) NOT NULL,
	MonthNumberOfYear tinyint NOT NULL,
	CalendarQuarter tinyint NOT NULL,
	CalendarYear smallint NOT NULL,
	CalendarSemester tinyint NOT NULL,
	FiscalQuarter tinyint NOT NULL,
	FiscalYear smallint NOT NULL,
	FiscalSemester tinyint NOT NULL)
WITH 
(
    LOCATION='/DimDate.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimDepartmentGroup(
	DepartmentGroupKey int NOT NULL,
	ParentDepartmentGroupKey int,
	DepartmentGroupName nvarchar(50))
WITH 
(
    LOCATION='/DimDepartmentGroup.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimEmployee(
	EmployeeKey int NOT NULL,
	ParentEmployeeKey int,
	EmployeeNationalIDAlternateKey nvarchar(15), 
	ParentEmployeeNationalIDAlternateKey nvarchar(15), 
	SalesTerritoryKey int,
	FirstName nvarchar(50) NOT NULL,
	LastName nvarchar(50) NOT NULL,
	MiddleName nvarchar(50),
	NameStyle bit NOT NULL,
	Title nvarchar(50),
	HireDate date,
	BirthDate date,
	LoginID nvarchar(256),
	EmailAddress nvarchar(50),
	Phone nvarchar(25),
	MaritalStatus nchar(1),
	EmergencyContactName nvarchar(50),
	EmergencyContactPhone nvarchar(25),
	SalariedFlag bit,
	Gender nchar(1),
	PayFrequency tinyint,
	BaseRate money,
	VacationHours smallint,
	SickLeaveHours smallint,
	CurrentFlag bit NOT NULL,
	SalesPersonFlag bit NOT NULL,
	DepartmentName nvarchar(50),
	StartDate date,
	EndDate date,
	Status nvarchar(50)) 
WITH 
(
    LOCATION='/DimEmployee.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimGeography(
	GeographyKey int NOT NULL,
	City nvarchar(30),
	StateProvinceCode nvarchar(3),
	StateProvinceName nvarchar(50),
	CountryRegionCode nvarchar(3),
	EnglishCountryRegionName nvarchar(50),
	SpanishCountryRegionName nvarchar(50),
	FrenchCountryRegionName nvarchar(50),
	PostalCode nvarchar(15),
	SalesTerritoryKey int)
WITH 
(
    LOCATION='/DimGeography.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimOrganization(
	OrganizationKey int NOT NULL,
	ParentOrganizationKey int,
	PercentageOfOwnership nvarchar(16),
	OrganizationName nvarchar(50),
	CurrencyKey int)
WITH 
(
    LOCATION='/DimOrganization.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimProduct(
	ProductKey int NOT NULL,
	ProductAlternateKey nvarchar(25),		
	ProductSubcategoryKey int,
	WeightUnitMeasureCode nchar(3),
	SizeUnitMeasureCode nchar(3),
	EnglishProductName nvarchar(50) NOT NULL,
	SpanishProductName nvarchar(50),
	FrenchProductName nvarchar(50),
	StandardCost money,
	FinishedGoodsFlag bit NOT NULL,
	Color nvarchar(15) NOT NULL,
	SafetyStockLevel smallint,
	ReorderPoint smallint,
	ListPrice money,
	[Size] nvarchar(50),
	SizeRange nvarchar(50),
	Weight float,
	DaysToManufacture integer,
	ProductLine nchar(2),
	DealerPrice money,
	[Class] nchar(2),
	Style nchar(2),
	ModelName nvarchar(50),
	EnglishDescription nvarchar(400),
	FrenchDescription nvarchar(400),
	ChineseDescription nvarchar(400),
	ArabicDescription nvarchar(400),
	HebrewDescription nvarchar(400),
	ThaiDescription nvarchar(400),
	GermanDescription nvarchar(400),
	JapaneseDescription nvarchar(400),
	TurkishDescription nvarchar(400),
	StartDate datetime,
	EndDate datetime,
	Status nvarchar(7))
WITH 
(
    LOCATION='/DimProduct.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormatDateTime
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimProductCategory(
	ProductCategoryKey int NOT NULL,
	ProductCategoryAlternateKey int,		
	EnglishProductCategoryName nvarchar(50) NOT NULL,
	SpanishProductCategoryName nvarchar(50) NOT NULL,
	FrenchProductCategoryName nvarchar(50) NOT NULL)
WITH 
(
    LOCATION='/DimProductCategory.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimProductSubcategory(
	ProductSubcategoryKey int NOT NULL,
	ProductSubcategoryAlternateKey int, 
	EnglishProductSubcategoryName nvarchar(50) NOT NULL,
	SpanishProductSubcategoryName nvarchar(50) NOT NULL,
	FrenchProductSubcategoryName nvarchar(50) NOT NULL,
	ProductCategoryKey int)
WITH 
(
    LOCATION='/DimProductSubcategory.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimPromotion(
	PromotionKey int NOT NULL,
	PromotionAlternateKey int,	
	EnglishPromotionName nvarchar(255),
	SpanishPromotionName nvarchar(255),
	FrenchPromotionName nvarchar(255),
	DiscountPct float,
	EnglishPromotionType nvarchar(50),
	SpanishPromotionType nvarchar(50),
	FrenchPromotionType nvarchar(50),
	EnglishPromotionCategory nvarchar(50),
	SpanishPromotionCategory nvarchar(50),
	FrenchPromotionCategory nvarchar(50),
	StartDate datetime NOT NULL,
	EndDate datetime,
	MinQty int,
	MaxQty int)
WITH 
(
    LOCATION='/DimPromotion.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormatDateTime
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimReseller(
	ResellerKey int NOT NULL,
	GeographyKey int,
	ResellerAlternateKey nvarchar(15), 
	Phone nvarchar(25),
	BusinessType varchar(20) NOT NULL,
	ResellerName nvarchar(50) NOT NULL,
	NumberEmployees int,
	OrderFrequency char(1),
	OrderMonth tinyint,
	FirstOrderYear int,
	LastOrderYear int,
	ProductLine nvarchar(50),
	AddressLine1 nvarchar(60),
	AddressLine2 nvarchar(60),
	AnnualSales money,
	BankName nvarchar(50),
	MinPaymentType tinyint,
	MinPaymentAmount money,
	AnnualRevenue money,
	YearOpened int)
WITH 
(
    LOCATION='/DimReseller.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimSalesReason(
	SalesReasonKey int NOT NULL,
	SalesReasonAlternateKey int NOT NULL,
	SalesReasonName nvarchar(50) NOT NULL,
	SalesReasonReasonType nvarchar(50) NOT NULL)
WITH 
(
    LOCATION='/DimSalesReason.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimSalesTerritory(
	SalesTerritoryKey int NOT NULL,
	SalesTerritoryAlternateKey int,
	SalesTerritoryRegion nvarchar(50) NOT NULL,
	SalesTerritoryCountry nvarchar(50) NOT NULL,
	SalesTerritoryGroup nvarchar(50))
WITH 
(
    LOCATION='/DimSalesTerritory.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].DimScenario(
	ScenarioKey int NOT NULL,
	ScenarioName nvarchar(50))
WITH 
(
    LOCATION='/DimScenario.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].FactCallCenter(
	FactCallCenterID int NOT NULL,
	DateKey int NOT NULL,
	WageType nvarchar(15) NOT NULL,
	Shift nvarchar(20) NOT NULL,
	LevelOneOperators smallint NOT NULL,
	LevelTwoOperators smallint NOT NULL,
	TotalOperators smallint NOT NULL,
	Calls int NOT NULL,
	AutomaticResponses int NOT NULL,
	Orders int NOT NULL,
	IssuesRaised smallint NOT NULL,
	AverageTimePerIssue smallint NOT NULL,
	ServiceGrade float NOT NULL)
WITH 
(
    LOCATION='/FactCallCenter.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].FactCurrencyRate(
	CurrencyKey int NOT NULL,
	DateKey int NOT NULL,
	AverageRate float NOT NULL,
	EndOfDayRate float NOT NULL)
WITH 
(
    LOCATION='/FactCurrencyRate.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].FactFinance(
	FinanceKey int NOT NULL,
	DateKey int NOT NULL,
	OrganizationKey int NOT NULL,
	DepartmentGroupKey int NOT NULL,
	ScenarioKey int NOT NULL,
	AccountKey int NOT NULL,
	Amount float NOT NULL) 
WITH 
(
    LOCATION='/FactFinance.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].FactInternetSales(
	ProductKey int NOT NULL,
	OrderDateKey int NOT NULL,
	DueDateKey int NOT NULL,
	ShipDateKey int NOT NULL,
	CustomerKey int NOT NULL,
	PromotionKey int NOT NULL,
	CurrencyKey int NOT NULL,
	SalesTerritoryKey int NOT NULL,
	SalesOrderNumber nvarchar(20) NOT NULL,
	SalesOrderLineNumber tinyint NOT NULL,
	RevisionNumber tinyint NOT NULL,
	OrderQuantity smallint NOT NULL,
	UnitPrice money NOT NULL,
	ExtendedAmount money NOT NULL,
	UnitPriceDiscountPct float NOT NULL,
	DiscountAmount float NOT NULL,
	ProductStandardCost money NOT NULL,
	TotalProductCost money NOT NULL,
	SalesAmount money NOT NULL,
	TaxAmt money NOT NULL,
	Freight money NOT NULL,
	CarrierTrackingNumber nvarchar(25),
	CustomerPONumber nvarchar(25))
WITH 
(
    LOCATION='/FactInternetSales.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].FactInternetSalesReason(
	SalesOrderNumber nvarchar(20) NOT NULL,
	SalesOrderLineNumber tinyint NOT NULL,
	SalesReasonKey int NOT NULL)
WITH 
(
    LOCATION='/FactInternetSalesReason.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].ProspectiveBuyer(
	ProspectiveBuyerKey int NOT NULL,
	ProspectAlternateKey nvarchar(15),
	FirstName nvarchar(50),
	MiddleName nvarchar(50),
	LastName nvarchar(50),
	BirthDate datetime,
	MaritalStatus nchar(1),
	Gender nvarchar(1),
	EmailAddress nvarchar(50),
	YearlyIncome money,
	TotalChildren tinyint,
	NumberChildrenAtHome tinyint,
	Education nvarchar(40),
	Occupation nvarchar(100),
	HouseOwnerFlag nchar(1),
	NumberCarsOwned tinyint,
	AddressLine1 nvarchar(120),
	AddressLine2 nvarchar(120),
	City nvarchar(30),
	StateProvinceCode nvarchar(3),
	PostalCode nvarchar(15),
	Phone nvarchar(20),
	Salutation nvarchar(8),
	[Unknown] int)
WITH 
(
    LOCATION='/ProspectiveBuyer.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormatDateTime
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].FactResellerSales(
	ProductKey int NOT NULL,
	OrderDateKey int NOT NULL,
	DueDateKey int NOT NULL,
	ShipDateKey int NOT NULL,
	ResellerKey int NOT NULL,
	EmployeeKey int NOT NULL,
	PromotionKey int NOT NULL,
	CurrencyKey int NOT NULL,
	SalesTerritoryKey int NOT NULL,
	SalesOrderNumber nvarchar(20) NOT NULL,
	SalesOrderLineNumber tinyint NOT NULL,
	RevisionNumber tinyint,
	OrderQuantity smallint,
	UnitPrice money,
	ExtendedAmount money,
	UnitPriceDiscountPct float,
	DiscountAmount float,
	ProductStandardCost money,
	TotalProductCost money,
	SalesAmount money,
	TaxAmt money,
	Freight money,
	CarrierTrackingNumber nvarchar(25),
	CustomerPONumber nvarchar(25))
WITH 
(
    LOCATION='/FactResellerSales.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].FactSalesQuota(
	SalesQuotaKey int NOT NULL,
	EmployeeKey int NOT NULL,
	DateKey int NOT NULL,
	CalendarYear smallint NOT NULL,
	CalendarQuarter tinyint NOT NULL,
	SalesAmountQuota money NOT NULL)
WITH 
(
    LOCATION='/FactSalesQuota.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO

CREATE EXTERNAL TABLE [asb].FactSurveyResponse(
	SurveyResponseKey int NOT NULL,
	DateKey int NOT NULL,
	CustomerKey int NOT NULL,
	ProductCategoryKey int NOT NULL,
	EnglishProductCategoryName nvarchar(50) NOT NULL,
	ProductSubcategoryKey int NOT NULL,
	EnglishProductSubcategoryName nvarchar(50) NOT NULL)
WITH 
(
    LOCATION='/FactSurveyResponse.txt' 
,   DATA_SOURCE = AzureStorageImport
,   FILE_FORMAT = TextFileFormat
,   REJECT_TYPE = VALUE
,   REJECT_VALUE = 0
)
GO


-- ===========================================================================================================================================
-- Load Data ---------------------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================


-- select * from DimProduct
INSERT [dbo].DimAccount  SELECT * FROM [asb].DimAccount 
INSERT [dbo].DimCurrency SELECT * FROM [asb].DimCurrency
INSERT [dbo].DimCustomer SELECT * FROM [asb].DimCustomer
INSERT [dbo].DimDate SELECT * FROM [asb].DimDate
INSERT [dbo].DimDepartmentGroup SELECT * FROM [asb].DimDepartmentGroup
INSERT [dbo].DimEmployee SELECT * FROM [asb].DimEmployee
INSERT [dbo].DimGeography SELECT * FROM [asb].DimGeography
INSERT [dbo].DimOrganization SELECT * FROM [asb].DimOrganization
INSERT [dbo].DimProduct SELECT * FROM [asb].DimProduct
INSERT [dbo].DimProductCategory SELECT * FROM [asb].DimProductCategory
INSERT [dbo].DimProductSubcategory SELECT * FROM [asb].DimProductSubcategory
INSERT [dbo].DimPromotion SELECT * FROM [asb].DimPromotion
INSERT [dbo].DimReseller SELECT * FROM [asb].DimReseller
INSERT [dbo].DimSalesReason SELECT * FROM [asb].DimSalesReason
INSERT [dbo].DimSalesTerritory SELECT * FROM [asb].DimSalesTerritory
INSERT [dbo].DimScenario SELECT * FROM [asb].DimScenario
INSERT [dbo].FactCallCenter SELECT * FROM [asb].FactCallCenter
INSERT [dbo].FactCurrencyRate SELECT * FROM [asb].FactCurrencyRate
INSERT [dbo].FactFinance SELECT * FROM [asb].FactFinance
INSERT [dbo].FactInternetSales SELECT * FROM [asb].FactInternetSales
INSERT [dbo].FactInternetSalesReason SELECT * FROM [asb].FactInternetSalesReason
INSERT [dbo].ProspectiveBuyer SELECT * FROM [asb].ProspectiveBuyer
INSERT [dbo].FactResellerSales SELECT * FROM [asb].FactResellerSales
INSERT [dbo].FactSalesQuota SELECT * FROM [asb].FactSalesQuota
INSERT [dbo].FactSurveyResponse SELECT * FROM [asb].FactSurveyResponse
GO


-- ===========================================================================================================================================
-- Create extra objects ----------------------------------------------------------------------------------------------------------------------
-- ===========================================================================================================================================

-- Total sales per promotion
create view vTotalSalesPerPromotion as
select p.PromotionKey, p.EnglishPromotionName, SalesAmount
from DimPromotion p ,
(select s.PromotionKey, sum(SalesAmount) SalesAmount from FactInternetSales s where PromotionKey != 1 group by s.PromotionKey) s
where p.PromotionKey = s.PromotionKey
go

-- The number of finance records where the amount is more than the average amount
create view vTotalFinanceRecrords AS
select count(*) as [TotalFinanceRecords] from FactFinance where Amount > (select avg(amount) from FactFinance)
go

-- Product categories for surveys received from German customers in 4th quarter of 2002
create view vProductCategories as 
select distinct City, StateProvinceName, DimProductCategory.EnglishProductCategoryName 
from FactSurveyResponse, DimCustomer, DimProductCategory, DimDate, DimGeography
where FactSurveyResponse.CustomerKey = DimCustomer.CustomerKey and
FactSurveyResponse.ProductCategoryKey = DimProductCategory.ProductCategoryKey and
FactSurveyResponse.DateKey = DimDate.DateKey and
DimCustomer.GeographyKey = DimGeography.GeographyKey and
CountryRegionCode = 'DE' and
CalendarYear = 2002 and
CalendarQuarter = 4
go

-- Top 3 quotas applied to every sales person
create view vTop3Quotas as 
select FirstName, LastName, SalesAmountQuota from DimEmployee, (select top 3 SalesAmountQuota from FactSalesQuota order by SalesAmountQuota desc) t2
where SalesPersonFlag = 1
go


-- Prospective buyers in Minnesota where the same occupation is not found between individuals with different marital status
create proc uspProspectiveBuyersInMinnesota
as 
select distinct MaritalStatus, Occupation from ProspectiveBuyer b1 where MaritalStatus = 'M' and StateProvinceCode = 'MN' and not exists (select * from ProspectiveBuyer b2 where MaritalStatus = 'S' and StateProvinceCode = 'MN' and b1.Occupation = b2.Occupation)
union
select distinct MaritalStatus, Occupation from ProspectiveBuyer b1 where MaritalStatus = 'S' and StateProvinceCode = 'MN' and not exists (select * from ProspectiveBuyer b2 where MaritalStatus = 'M' and StateProvinceCode = 'MN' and b1.Occupation = b2.Occupation)
go


create proc uspTempTableDemo
as 
create table #T1  (
	c1 int,
	c2 varchar(100)
)
with (distribution=replicate)
go



CREATE FUNCTION dbo.ConvertInput (@MyValueIn int)  
RETURNS decimal(10,2)  
AS  
BEGIN  
    DECLARE @MyValueOut int;  
    SET @MyValueOut= CAST( @MyValueIn AS decimal(10,2));  
    RETURN(@MyValueOut);  
END;  
GO  


CREATE NONCLUSTERED INDEX [IX_DimAccount] ON [dbo].[DimAccount] (AccountType ASC)
GO


CREATE ROLE Sales
GO
CREATE ROLE Marketing
GO

CREATE USER SalesUser WITHOUT LOGIN
GO
CREATE USER MarketingUser WITHOUT LOGIN
go


/*
DROP TABLE dbo.DimAccount 
DROP TABLE dbo.DimCurrency
DROP TABLE dbo.DimCustomer
DROP TABLE dbo.DimDate
DROP TABLE dbo.DimDepartmentGroup
DROP TABLE dbo.DimEmployee
DROP TABLE dbo.DimGeography
DROP TABLE dbo.DimOrganization
DROP TABLE dbo.DimProduct
DROP TABLE dbo.DimProductCategory
DROP TABLE dbo.DimProductSubcategory
DROP TABLE dbo.DimPromotion
DROP TABLE dbo.DimReseller
DROP TABLE dbo.DimSalesReason
DROP TABLE dbo.DimSalesTerritory
DROP TABLE dbo.DimScenario
DROP TABLE dbo.FactCallCenter
DROP TABLE dbo.FactCurrencyRate
DROP TABLE dbo.FactFinance
DROP TABLE dbo.FactInternetSales
DROP TABLE dbo.FactInternetSalesReason
DROP TABLE dbo.ProspectiveBuyer
DROP TABLE dbo.FactResellerSales
DROP TABLE dbo.FactSalesQuota
DROP TABLE dbo.FactSurveyResponse
GO

DROP TABLE asb.DimAccount 
DROP TABLE asb.DimCurrency
DROP TABLE asb.DimCustomer
DROP TABLE asb.DimDate
DROP TABLE asb.DimDepartmentGroup
DROP TABLE asb.DimEmployee
DROP TABLE asb.DimGeography
DROP TABLE asb.DimOrganization
DROP TABLE asb.DimProduct
DROP TABLE asb.DimProductCategory
DROP TABLE asb.DimProductSubcategory
DROP TABLE asb.DimPromotion
DROP TABLE asb.DimReseller
DROP TABLE asb.DimSalesReason
DROP TABLE asb.DimSalesTerritory
DROP TABLE asb.DimScenario
DROP TABLE asb.FactCallCenter
DROP TABLE asb.FactCurrencyRate
DROP TABLE asb.FactFinance
DROP TABLE asb.FactInternetSales
DROP TABLE asb.FactInternetSalesReason
DROP TABLE asb.ProspectiveBuyer
DROP TABLE asb.FactResellerSales
DROP TABLE asb.FactSalesQuota
DROP TABLE asb.FactSurveyResponse
GO

DROP SCHEMA [asb]
GO

DROP EXTERNAL TABLE [EXT_aw].AdventureWorksDWBuildVersion
DROP EXTERNAL TABLE [EXT_aw].DatabaseLog
DROP EXTERNAL TABLE [EXT_aw].DimAccount 
DROP EXTERNAL TABLE [EXT_aw].DimCurrency
DROP EXTERNAL TABLE [EXT_aw].DimCustomer
DROP EXTERNAL TABLE [EXT_aw].DimDate
DROP EXTERNAL TABLE [EXT_aw].DimDepartmentGroup
DROP EXTERNAL TABLE [EXT_aw].DimEmployee
DROP EXTERNAL TABLE [EXT_aw].DimGeography
DROP EXTERNAL TABLE [EXT_aw].DimOrganization
DROP EXTERNAL TABLE [EXT_aw].DimProduct
DROP EXTERNAL TABLE [EXT_aw].DimProductCategory
DROP EXTERNAL TABLE [EXT_aw].DimProductSubcategory
DROP EXTERNAL TABLE [EXT_aw].DimPromotion
DROP EXTERNAL TABLE [EXT_aw].DimReseller
DROP EXTERNAL TABLE [EXT_aw].DimSalesReason
DROP EXTERNAL TABLE [EXT_aw].DimSalesTerritory
DROP EXTERNAL TABLE [EXT_aw].DimScenario
DROP EXTERNAL TABLE [EXT_aw].FactCallCenter
DROP EXTERNAL TABLE [EXT_aw].FactCurrencyRate
DROP EXTERNAL TABLE [EXT_aw].FactFinance
DROP EXTERNAL TABLE [EXT_aw].FactInternetSales
DROP EXTERNAL TABLE [EXT_aw].FactInternetSalesReason
DROP EXTERNAL TABLE [EXT_aw].ProspectiveBuyer
DROP EXTERNAL TABLE [EXT_aw].FactResellerSales
DROP EXTERNAL TABLE [EXT_aw].FactSalesQuota
DROP EXTERNAL TABLE [EXT_aw].FactSurveyResponse
GO

DROP EXTERNAL FILE FORMAT TextFileFormat 
GO

DROP EXTERNAL FILE FORMAT TextFileFormatDateTime 
GO

DROP EXTERNAL DATA SOURCE AzureStorageImport
GO

DROP EXTERNAL DATA SOURCE AZURE_STAGING_STORAGE
GO

DROP DATABASE SCOPED CREDENTIAL AzureStorageCredential
GO

DROP MASTER KEY
GO
*/