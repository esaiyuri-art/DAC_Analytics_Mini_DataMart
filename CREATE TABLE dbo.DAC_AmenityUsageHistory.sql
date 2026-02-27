USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don’t run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_AmenityUsageHistory
Object Type: Fact Table (Transactional)
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Stores the detailed event-level history of amenity usage. Each row represents one instance of a member using an amenity at a specific time.

Grain: 1 row = 1 amenity usage event (one member enrollment + one amenity + one timestamp)

Design Decisions:
    - DACCustomerMembershipID ties usage to a specific member's membership enrollment.
    - AmenityID ties usage to the amenity dimension (dbo.DAC_Amenity).

Notes for Junior devs:
    - Fact tables store “events” or “transactions” (things that happened).
    - Dimension tables store “descriptions” (names/categories).

Error Log: If this fails with "There is already an object named DAC_AmenityUsageHistory", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE [dbo].[DAC_AmenityUsageHistory]
(
/*Columns for your new table*/
	[AmenityUsageID] [int] IDENTITY(1,1) NOT NULL,					/*We use IDENTITY(1,1) so SQL Server automatically gives every row its own number. 
																	This is called a "surrogate key" (a system-generated unique ID).*/
	[DACCustomerMembershipID] [int] NOT NULL,
	[AmenityID] [int] NOT NULL,
	[UsageDate] [datetime] NOT NULL,

PRIMARY KEY CLUSTERED												/*PK = Primary Key*/
																	/*Clustered Indexes are great for query optimization because the table is physically sorted 
																	by this column. Only 1 per table allowed*/
(
	[AmenityUsageID] ASC											/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
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
) ON [PRIMARY]
GO
;

/*************************************************************************************** 
FOREIGN KEYS & Check Constraints
-Foreign keys enforce “no orphan records”.
--Meaning: you cannot log a usage event for a membership or amenity that doesn’t exist
- Check Constraints enforce business rules + prevent bad data.
****************************************************************************************/

ALTER TABLE [dbo].[DAC_AmenityUsageHistory]  WITH CHECK ADD  CONSTRAINT [FK_DAC_AmenityUsageHistory_DAC_customer_membership] FOREIGN KEY([DACCustomerMembershipID])
REFERENCES [dbo].[DAC_customer_membership] ([DACCustomerMembershipID])
GO

ALTER TABLE [dbo].[DAC_AmenityUsageHistory] CHECK CONSTRAINT [FK_DAC_AmenityUsageHistory_DAC_customer_membership]
GO

ALTER TABLE [dbo].[DAC_AmenityUsageHistory]  WITH CHECK ADD  CONSTRAINT [FK_DAC_AmenityUsageHistory_DAC_Membership_Amenity] FOREIGN KEY([AmenityID])
REFERENCES [dbo].[DAC_Amenity] ([AmenityID])
GO

ALTER TABLE [dbo].[DAC_AmenityUsageHistory] CHECK CONSTRAINT [FK_DAC_AmenityUsageHistory_DAC_Membership_Amenity]
GO


