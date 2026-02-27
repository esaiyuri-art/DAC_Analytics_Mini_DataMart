USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don't run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.Dim_Date
Object Type: Dimension Table
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Stores a complete calendar dimension table with pre-calculated date attributes. This dimension table supports time-based analysis and reporting
		 without requiring complex date calculations in queries. Each row represents one calendar day.

Grain: 1 row = 1 calendar date.

Design Decisions:
	- DateKey implemented as YYYYMMDD integer format (e.g., 20260227) for efficient numeric joins and sorting.
	- CalendarDate stored as DATE type to support standard date operations and filtering.
	- Quarter, Month, DayOfMonth, DayOfYear stored as TINYINT to save storage space (values 1-31, 1-12, etc.).
	- IsoDayOfWeek and IsoWeekOfYear follow ISO 8601 standard (Monday = 1, Sunday = 7) for international consistency.
	- IsWeekend, IsHoliday, and IsBusinessDay stored as BIT flags for quick filtering in reports.
	- HolidayName is nullable to support non-holiday dates.
	- FiscalYear, FiscalQuarter, FiscalMonth support fiscal calendar analysis (may differ from calendar year).

Constraints:
	- PK_Dim_Date: Clustered primary key on DateKey for optimal query performance.
	- UQ_Dim_Date_CalendarDate: Ensures each calendar date appears only once in the dimension table.

Notes for Junior devs:
	- Dimension tables store descriptive attributes (dates, names, categories) that support fact table analysis.
	- Date dimensions pre-calculate all date attributes so queries don't have to compute them repeatedly (improves performance).
	- ISO 8601 is an international standard for date/time formatting (useful for global businesses).

Error Log: If this fails with "There is already an object named Dim_Date", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE [dbo].[Dim_Date]
(
	/*Columns for your date dimension table*/
	[DateKey] [int] NOT NULL,										/*Integer surrogate key in YYYYMMDD format (e.g., 20260227 for Feb 27, 2026). Used for efficient joins.*/
	[CalendarDate] [date] NOT NULL,									/*The actual calendar date. Unique constraint ensures one row per date.*/
	[Year] [smallint] NOT NULL,
	[Quarter] [tinyint] NOT NULL,									/*Quarter number: 1, 2, 3, or 4.*/
	[Month] [tinyint] NOT NULL,										/*Month number: 1-12 (January-December).*/
	[MonthName] [varchar](20) NOT NULL,
	[DayOfMonth] [tinyint] NOT NULL,								/*Day of the month: 1-31.*/
	[DayOfYear] [smallint] NOT NULL,								/*Day of the year: 1-366 (accounting for leap years).*/
	[IsoDayOfWeek] [tinyint] NOT NULL,								/*ISO day of week: 1=Monday, 2=Tuesday, ... 7=Sunday. ISO 8601 standard.*/
	[DayName] [varchar](20) NOT NULL,
	[WeekOfYear] [tinyint] NOT NULL,								/*Week number in the year (1-53). Standard U.S. week numbering.*/
	[IsoWeekOfYear] [tinyint] NOT NULL,								/*ISO week number in the year (1-53). ISO 8601 standard.*/
	[IsWeekend] [bit] NOT NULL,										/* BIT = 0 or 1 (No/Yes). Set to 1 if Saturday or Sunday.*/
	[IsHoliday] [bit] NOT NULL,										/* BIT = 0 or 1 (No/Yes). Set to 1 if date is a recognized holiday.*/
	[HolidayName] [varchar](100) NULL,								/*Name of the holiday (e.g., "Christmas", "Thanksgiving"). NULL if not a holiday.*/
	[IsBusinessDay] [bit] NOT NULL,									/* BIT = 0 or 1 (No/Yes). Set to 1 if weekday AND not a holiday (useful for business metrics).*/
	[FiscalYear] [smallint] NOT NULL,								/*Fiscal year. May differ from calendar year depending on company fiscal calendar.*/
	[FiscalQuarter] [tinyint] NOT NULL,								/*Fiscal quarter: 1, 2, 3, or 4 (based on fiscal calendar, not calendar year).*/
	[FiscalMonth] [tinyint] NOT NULL,								/*Fiscal month: 1-12 (based on fiscal calendar, not calendar month).*/

 CONSTRAINT [PK_Dim_Date] PRIMARY KEY CLUSTERED						/*PK = Primary Key*/
																	/*Clustered Indexes are great for query optimization because the table is physically sorted 
																	by this column. Only 1 per table allowed*/
(
	[DateKey] ASC													/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
)
                        WITH 
                            (
                                PAD_INDEX = OFF,					/*Controls how full index pages are. Default OFF is fine*/
                            
                                STATISTICS_NORECOMPUTE = OFF,		/*Allows SQL Server to automatically update statistics (recommended)*/
                            
                                IGNORE_DUP_KEY = OFF,				/*If duplicate key is inserted, SQL throws an error (safer behavior)*/
                            
                                ALLOW_ROW_LOCKS = ON,				/*SQL can lock individual rows during updates (good for concurrency)*/
                            
                                ALLOW_PAGE_LOCKS = ON,				/*SQL can lock groups of rows for performance optimization*/
                            
                                OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF	/*Advanced setting for high insert concurrency. Default is fine for most projects*/
                            )
                            ON [PRIMARY]							/*PRIMARY = default filegroup where the table/index is stored*/,

 CONSTRAINT [UQ_Dim_Date_CalendarDate] UNIQUE NONCLUSTERED			/*NonClustered Indexes are great for query optimization too as they work similar to an appendix in a book. 
																	UNIQUE (UQ) ensures no two amenities can have the same name*/
(
	[CalendarDate] ASC												
/*UNIQUE constraint ensures only one record per calendar date. No duplicate dates allowed.*/
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO