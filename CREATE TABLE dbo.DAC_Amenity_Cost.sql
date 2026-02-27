USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don’t run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_Amenity_Cost
Object Type: Dimension / Attribute Table (Amenity Cost & Pricing)
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Stores cost + pricing attributes for each amenity.

Grain: 1 row = 1 amenity (one cost/pricing record per AmenityID).

Design Decisions:
    - AmenityID is both the Primary Key and a Foreign Key to dbo.DAC_Amenity. This creates a 1-to-1 relationship: each amenity has one pricing record.
    - CHECK constraints enforce realistic business rules:
        • costs cannot be negative
        • if included in dues, MemberCostPerUse must be 0
        • if NOT included in dues, MemberCostPerUse must be > 0
    - Defaults are set so new records behave safely (active + included in dues by default).

Notes for Junior devs:
    - This is not a “fact table” because it is not recording events. It stores attributes (settings/pricing) that other tables use.

Error Log: If this fails with "There is already an object named DAC_Amenity_Cost", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/


CREATE TABLE [dbo].[DAC_Amenity_Cost]
(
/*Columns for your new table*/
	[AmenityID] [int] NOT NULL,								/* Foreign Key + Primary Key: This matches exactly 1 record in dbo.DAC_Amenity. */
	[InitialBuildCost] [decimal](18, 2) NOT NULL,			/* decimal(18,2): 18 total digits allowed, 2 digits after the decimal point
															Good for storing money because it avoids rounding errors*/
	[MonthlyFixedCost] [decimal](18, 2) NOT NULL,
	[CostPerUse] [decimal](18, 2) NOT NULL,
	[UsefulLifeYears] [int] NULL,
	[ActiveFlag] [bit] NOT NULL,							/* BIT = 0 or 1 (Inactive/Active). */
	[InDuesIND] [bit] NOT NULL,
	[MemberCostPerUse] [decimal](18, 2) NOT NULL,

 CONSTRAINT [PK_DAC_Amenity_Cost] PRIMARY KEY CLUSTERED		/*PK = Primary Key*/
															/*Clustered Indexes are great for query optimization because the table is physically sorted 
															by this column. Only 1 per table allowed*/
(
	[AmenityID] ASC											/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
)

        WITH (
            PAD_INDEX = OFF,					/*Controls how full index pages are. Default OFF is fine*/
        
            STATISTICS_NORECOMPUTE = OFF,		/*Allows SQL Server to automatically update statistics (recommended)*/
        
            IGNORE_DUP_KEY = OFF,				/*If duplicate key is inserted, SQL throws an error (safer behavior)*/
        
            ALLOW_ROW_LOCKS = ON,				/*SQL can lock individual rows during updates (good for concurrency)*/
        
            ALLOW_PAGE_LOCKS = ON,				/*SQL can lock groups of rows for performance optimization*/
        
            OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF	/*Advanced setting for high insert concurrency. Default is fine for most projects*/
             )
        ON [PRIMARY]							/*PRIMARY = default filegroup where the table/index is stored*/

) ON [PRIMARY]
GO
;

/******************************************************************** 
DEFAULTS: These help prevent accidental NULLs and make inserts safer 
********************************************************************/

ALTER TABLE [dbo].[DAC_Amenity_Cost]
ADD DEFAULT ((1)) FOR [ActiveFlag];
/* If ActiveFlag isn’t provided, SQL sets it to 1 (active). */
GO

ALTER TABLE [dbo].[DAC_Amenity_Cost]
ADD CONSTRAINT [DF_DAC_Amenity_Cost_InDuesIND] DEFAULT ((1)) FOR [InDuesIND];
/* Default is included in dues (1) unless you explicitly set pay-per-use. */
GO

ALTER TABLE [dbo].[DAC_Amenity_Cost]
ADD CONSTRAINT [DF_DAC_Amenity_Cost_MemberCostPerUse] DEFAULT ((0.00)) FOR [MemberCostPerUse];
/* Default member cost is 0.00 (works correctly when InDuesIND = 1). */
GO


/******************************************************************** 
FOREIGN KEY: This forces AmenityID to exist in dbo.DAC_Amenity first 
********************************************************************/

ALTER TABLE [dbo].[DAC_Amenity_Cost] WITH CHECK
ADD CONSTRAINT [FK_DAC_Amenity_Cost_Amenity]
FOREIGN KEY([AmenityID])
REFERENCES [dbo].[DAC_Amenity] ([AmenityID])
ON DELETE CASCADE;
/* ON DELETE CASCADE means:
   If an Amenity is deleted from DAC_Amenity, its cost record is deleted too.
   (In production, many teams avoid deletes and prefer ActiveFlag instead.) */
GO

ALTER TABLE [dbo].[DAC_Amenity_Cost]
CHECK CONSTRAINT [FK_DAC_Amenity_Cost_Amenity];
GO


/****************************************************************** 
CHECK CONSTRAINTS: These enforce business rules + prevent bad data 
******************************************************************/

ALTER TABLE [dbo].[DAC_Amenity_Cost] WITH CHECK
ADD CONSTRAINT [CK_DAC_Amenity_Cost_InDues_MemberCost]
CHECK
(
    ([InDuesIND] = 1 AND [MemberCostPerUse] = 0)
 OR ([InDuesIND] = 0 AND [MemberCostPerUse] > 0)
);
/* Rule:
   - If included in dues, members pay $0 per use.
   - If NOT included, members must pay something (>0). */
GO

ALTER TABLE [dbo].[DAC_Amenity_Cost]
CHECK CONSTRAINT [CK_DAC_Amenity_Cost_InDues_MemberCost];
GO


ALTER TABLE [dbo].[DAC_Amenity_Cost] WITH CHECK
ADD CONSTRAINT [CK_DAC_Amenity_Cost_MemberCostPerUse_NonNegative]
CHECK ([MemberCostPerUse] >= (0));
/* MemberCostPerUse cannot be negative. */
GO

ALTER TABLE [dbo].[DAC_Amenity_Cost]
CHECK CONSTRAINT [CK_DAC_Amenity_Cost_MemberCostPerUse_NonNegative];
GO


ALTER TABLE [dbo].[DAC_Amenity_Cost] WITH CHECK
ADD CONSTRAINT [CK_DAC_Amenity_Cost_Positive]
CHECK
(
    [InitialBuildCost] >= (0)
AND [MonthlyFixedCost] >= (0)
AND [CostPerUse] >= (0)
);
/* Costs cannot be negative. */
GO

ALTER TABLE [dbo].[DAC_Amenity_Cost]
CHECK CONSTRAINT [CK_DAC_Amenity_Cost_Positive];
GO

