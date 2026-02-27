USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don't run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_membership
Object Type: Dimension Table
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Stores master list of membership types available at the club. Serves as a dimension table that defines membership offerings, 
		 pricing tiers, eligibility requirements, and capacity constraints.

Grain: 1 row = 1 unique membership offering.

Design Decisions:
	- MembershipID implemented as IDENTITY surrogate key for stable joins across fact tables.
	- MembershipTypeID enforced as Foreign Key to reference membership_type dimension.
	- MonthlyDuesAmount, MonthlyMinimumSpend, and InitiationFee are nullable to support memberships with no fees or flexible pricing.
	- AgeMin and AgeMax are nullable to support memberships with no age restrictions.
	- RequiresSponsorFlag defaults to 1 to enforce sponsorship requirement unless explicitly disabled.
	- ActiveFlag defaults to 1 to support soft-deactivation without physical deletion.
	- Capacity and EstimatedWaitMonths are nullable to support memberships without waitlists or capacity limits.

Constraints:
	- PK_DAC_membership: Clustered primary key on MembershipID.
	- FK_DAC_membership_membership_type: Enforces referential integrity - all MembershipTypeIDs must exist in dbo.membership_type.
	- CK_DAC_membership_CountryClubOnly: Business rule - this table is restricted to Country Club memberships only (MembershipTypeID = 6).

Error Log: If this fails with "There is already an object named DAC_membership", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE [dbo].[DAC_membership]
(
	/*Columns for your membership table*/
	[MembershipID] [int] IDENTITY(1,1) NOT NULL,					/*We use IDENTITY(1,1) so SQL Server automatically gives every row its own number. 
																	This is called a "surrogate key" (a system-generated unique ID).*/
	[MembershipTypeID] [int] NOT NULL,
	[MembershipDescription] [nvarchar](200) NOT NULL,
	[MembershipCategory] [nvarchar](100) NOT NULL,
	[MonthlyDuesAmount] [decimal](10, 2) NULL,						/* decimal(10,2): 10 total digits allowed, 2 digits after the decimal point
																	Good for storing money because it avoids rounding errors*/
	[MonthlyMinimumSpend] [decimal](10, 2) NULL,
	[InitiationFee] [decimal](10, 2) NULL,
	[AgeMin] [int] NULL,											
	[AgeMax] [int] NULL,											
	[RequiresSponsorFlag] [bit] NOT NULL,							
	[ActiveFlag] [bit] NOT NULL,									/* BIT = 0 or 1 (Inactive/Active). */						
	[Capacity] [int] NULL,											
	[EstimatedWaitMonths] [int] NULL,								

PRIMARY KEY CLUSTERED												/*PK = Primary Key*/
																	/*Clustered Indexes are great for query optimization because the table is physically sorted 
																	by this column. Only 1 per table allowed*/
(
	[MembershipID] ASC												/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
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

/****************************************************************
DEFAULTS: These ensure safe inserts and prevent accidental NULLs
****************************************************************/

ALTER TABLE [dbo].[DAC_membership] ADD  DEFAULT ((1)) FOR [RequiresSponsorFlag]
/*If RequiresSponsorFlag isn't provided during insert, SQL sets it to 1 (sponsor required).*/
GO

ALTER TABLE [dbo].[DAC_membership] ADD  DEFAULT ((1)) FOR [ActiveFlag]
/*If ActiveFlag isn't provided during insert, SQL sets it to 1 (active). New memberships are active by default.*/
GO

/*************************************************************************************** 
FOREIGN KEYS & CHECK CONSTRAINTS
-Foreign keys enforce "no orphan records".
--Meaning: you cannot create a membership for a MembershipTypeID that doesn't exist.
- Check Constraints enforce business rules + prevent bad data.
****************************************************************************************/

ALTER TABLE [dbo].[DAC_membership]  WITH CHECK ADD  CONSTRAINT [FK_DAC_membership_membership_type] FOREIGN KEY([MembershipTypeID])
REFERENCES [dbo].[membership_type] ([MembershipTypeID])
/*Foreign Key: MembershipTypeID must exist in dbo.membership_type. Prevents orphan membership records.*/
GO

ALTER TABLE [dbo].[DAC_membership] CHECK CONSTRAINT [FK_DAC_membership_membership_type]
GO

ALTER TABLE [dbo].[DAC_membership]  WITH CHECK ADD  CONSTRAINT [CK_DAC_membership_CountryClubOnly] CHECK  (([MembershipTypeID]=(6)))
/*Check Constraint: This table is restricted to Country Club memberships only. MembershipTypeID must equal 6.*/
GO

ALTER TABLE [dbo].[DAC_membership] CHECK CONSTRAINT [CK_DAC_membership_CountryClubOnly]
GO


