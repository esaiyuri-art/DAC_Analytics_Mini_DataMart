USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don't run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_AmenityUsageMonthlySummary
Object Type: Aggregate/Summary Table (Fact Table)
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Stores pre-aggregated monthly usage summary metrics for each amenity. This summary table denormalizes data from DAC_AmenityUsageHistory 
		 to improve query performance for reporting and BI dashboards without recalculating usage metrics on demand.

Grain: 1 row = 1 amenity + 1 calendar month (one monthly summary record per AmenityID/YearNumber/MonthNumber combination).

Design Decisions:
	- AmenityMonthlySummaryID implemented as IDENTITY surrogate key for performance and clarity.
	- Composite UNIQUE constraint (AmenityID + YearNumber + MonthNumber) prevents duplicate monthly summaries for the same amenity.
	- MonthStartDate enforced to always be the 1st of the month via CHECK constraint to ensure data consistency.
	- CreatedDate defaults to SYSDATETIME() to automatically track when the summary record was created.
	- TotalUsageCount, UniqueMemberCount, and costs default to 0 to support safe inserts without explicit values.
	- TotalMemberSpend and TotalRevenue are nullable to allow for optional revenue tracking if not yet calculated.

Constraints:
	- PK_DAC_AmenityUsageMonthlySummary: Clustered primary key on AmenityMonthlySummaryID for optimal query performance.
	- UK_DAC_AmenityUsageMonthlySummary_AmenityYearMonth: Unique nonclustered index ensures only 1 summary per amenity per month.
	- FK_DAC_AmenityUsageMonthlySummary_DAC_Amenity: Enforces referential integrity - all AmenityIDs must exist in dbo.DAC_Amenity.
	- CK_DAC_AmenityUsageMonthlySummary_CostNonNegative: Ensures TotalOperatingCost cannot be negative.
	- CK_DAC_AmenityUsageMonthlySummary_CountsNonNegative: Ensures usage and member counts cannot be negative.
	- CK_DAC_AmenityUsageMonthlySummary_MonthNumber: Enforces MonthNumber is between 1-12 (valid calendar month).
	- CK_DAC_AmenityUsageMonthlySummary_MonthStartAlign: Ensures MonthStartDate always matches the first day of the specified YearNumber/MonthNumber.

Notes for Junior devs:
    - Fact tables store “events” or “transactions” (things that happened).
    - Dimension tables store “descriptions” (names/categories).
	- Normalization: Split data across multiple tables to avoid repeating the same information. Takes more JOINs to query but saves storage and prevents errors.
	- Denormalization: Combine data into one table so queries are faster. Uses more storage but you don't have to JOIN multiple tables.
**When to use: Normalize databases you UPDATE a lot (banks, stores). Denormalize databases you mostly READ from (reports, dashboards).

Error Log: If this fails with "There is already an object named DAC_AmenityUsageMonthlySummary", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE [dbo].[DAC_AmenityUsageMonthlySummary]
(
	/*Columns for your summary table*/
	[AmenityMonthlySummaryID] [int] IDENTITY(1,1) NOT NULL,			/*We use IDENTITY(1,1) so SQL Server automatically gives every row its own number. 
																	This is called a "surrogate key" (a system-generated unique ID).*/
	[AmenityID] [int] NOT NULL,										
	[YearNumber] [int] NOT NULL,									
	[MonthNumber] [int] NOT NULL,									
	[MonthStartDate] [date] NOT NULL,								
	[TotalUsageCount] [int] NOT NULL,								
	[UniqueMemberCount] [int] NOT NULL,								
	[TotalOperatingCost] [decimal](18, 2) NOT NULL,					/*Aggregate: Total operating cost for this amenity this month. Defaults to 0.00.*/
	[CreatedDate] [datetime2](7) NOT NULL,							/* datetime2 stores date + time (7) means maximum fractional seconds precision */
	[TotalMemberSpend] [decimal](18, 2) NULL,						
	[TotalRevenue] [decimal](18, 2) NULL,							

 CONSTRAINT [PK_DAC_AmenityUsageMonthlySummary] PRIMARY KEY CLUSTERED		/*PK = Primary Key. Clustered Indexes are great for query optimization because the table is physically sorted 
																			by this column. Only 1 per table allowed*/
(
	[AmenityMonthlySummaryID] ASC											/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
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
                            ON [PRIMARY]							/*PRIMARY = default filegroup where the table/index is stored*/
,

 CONSTRAINT [UK_DAC_AmenityUsageMonthlySummary_AmenityYearMonth] UNIQUE NONCLUSTERED	 /*NonClustered Indexes are great for query optimization too as they work similar to an appendix in a book. 
																						 UNIQUE (UK) ensures no two amenities can have the same name*/
(
	[AmenityID] ASC,
	[YearNumber] ASC,
	[MonthNumber] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****************************************************************
DEFAULTS: These ensure safe inserts and prevent accidental NULLs
****************************************************************/

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary] ADD  CONSTRAINT [DF_DAC_AmenityUsageMonthlySummary_TotalOperatingCost]  DEFAULT ((0.00)) FOR [TotalOperatingCost]
/*If TotalOperatingCost isn't provided during insert, SQL sets it to 0.00 (no cost).*/
GO

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary] ADD  CONSTRAINT [DF_DAC_AmenityUsageMonthlySummary_CreatedDate]  DEFAULT (sysdatetime()) FOR [CreatedDate]
/*If CreatedDate isn't provided during insert, SQL automatically sets it to the current system datetime.*/
GO

/**********************************************************************************
FOREIGN KEYS: Enforce referential integrity
-Cannot insert a summary for an AmenityID that doesn't exist in dbo.DAC_Amenity.
-This prevents orphan records and maintains data consistency.
**********************************************************************************/

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary]  WITH CHECK ADD  CONSTRAINT [FK_DAC_AmenityUsageMonthlySummary_DAC_Amenity] FOREIGN KEY([AmenityID])
REFERENCES [dbo].[DAC_Amenity] ([AmenityID])
/*Foreign Key: AmenityID must exist in dbo.DAC_Amenity. Prevents orphan summary records.*/
GO

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary] CHECK CONSTRAINT [FK_DAC_AmenityUsageMonthlySummary_DAC_Amenity]
GO

/**************************************************************
CHECK CONSTRAINTS: Enforce business rules and prevent bad data
**************************************************************/

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary]  WITH CHECK ADD  CONSTRAINT [CK_DAC_AmenityUsageMonthlySummary_CostNonNegative] CHECK  (([TotalOperatingCost]>=(0)))
/*TotalOperatingCost cannot be negative. Costs must be 0 or positive.*/
GO

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary] CHECK CONSTRAINT [CK_DAC_AmenityUsageMonthlySummary_CostNonNegative]
GO

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary]  WITH CHECK ADD  CONSTRAINT [CK_DAC_AmenityUsageMonthlySummary_CountsNonNegative] CHECK  (([TotalUsageCount]>=(0) AND [UniqueMemberCount]>=(0)))
/*TotalUsageCount and UniqueMemberCount cannot be negative. Counts must be 0 or positive (you can't have negative usage).*/
GO

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary] CHECK CONSTRAINT [CK_DAC_AmenityUsageMonthlySummary_CountsNonNegative]
GO

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary]  WITH CHECK ADD  CONSTRAINT [CK_DAC_AmenityUsageMonthlySummary_MonthNumber] CHECK  (([MonthNumber]>=(1) AND [MonthNumber]<=(12)))
/*MonthNumber must be between 1 and 12 inclusive. Prevents invalid month values.*/
GO

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary] CHECK CONSTRAINT [CK_DAC_AmenityUsageMonthlySummary_MonthNumber]
GO

ALTER TABLE [dbo].[DAC_AmenityUsageMonthlySummary]  WITH CHECK ADD  CONSTRAINT [CK_DAC_AmenityUsageMonthlySummary_MonthStartAlign] CHECK  (([MonthStartDate]=datefromparts([YearNumber],[MonthNumber],(1))))
/*MonthStartDate must always be the 1st day of the month specified by YearNumber and MonthNumber.
  Example: If YearNumber=2026 and MonthNumber=2, MonthStartDate must be 2026-02-01.
  This ensures data consistency and prevents date misalignment in reporting.*/
GO