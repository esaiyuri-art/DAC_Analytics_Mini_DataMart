USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don't run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_Membership_Amenity
Object Type: Bridge/Junction Table (Dimension)
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Stores the relationship between memberships and amenities. Acts as a bridge table that tracks which amenities are included with each membership type,
		 whether they are included or not, and how many guests can use each amenity under that membership.

Grain: 1 row = 1 membership + 1 amenity relationship (one record per membership-amenity combination).

Design Decisions:
	- MembershipID and AmenityID form a composite primary key to uniquely identify each membership-amenity pairing.
	- IncludedFlag defaults to 1 to indicate amenity is included with the membership unless explicitly marked as excluded.
	- GuestAllowanceCount is nullable to support amenities with no guest limits or memberships that don't allow guest access.
	- Both foreign keys use ON DELETE CASCADE to automatically remove amenity associations when a membership or amenity is deleted.

Constraints:
	- PK_DAC_Membership_Amenity: Clustered composite primary key on (MembershipID, AmenityID).
	- FK_DAC_Membership_Amenity_Amenity: Enforces referential integrity - all AmenityIDs must exist in dbo.DAC_Amenity.
	- FK_DAC_Membership_Amenity_Membership: Enforces referential integrity - all MembershipIDs must exist in dbo.DAC_membership.

Notes for Junior devs:
	- Bridge tables (also called junction tables) connect two tables that have a many-to-many relationship.
	- In this case: 1 membership can include many amenities, and 1 amenity can be part of many memberships.

Error Log: If this fails with "There is already an object named DAC_Membership_Amenity", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE [dbo].[DAC_Membership_Amenity]
(
	/*Columns for your membership-amenity bridge table*/
	[MembershipID] [int] NOT NULL,
	[AmenityID] [int] NOT NULL,
	[IncludedFlag] [bit] NOT NULL,									/* BIT = 0 or 1 (Not Included/Included). Defaults to 1. Indicates if amenity is included with this membership.*/
	[GuestAllowanceCount] [int] NULL,								/*Number of guests allowed to use this amenity under this membership. NULL if no guest access or unlimited.*/

 CONSTRAINT [PK_DAC_Membership_Amenity] PRIMARY KEY CLUSTERED 		/*PK = Primary Key. Clustered Indexes are great for query optimization because the table is physically sorted 
																	by this column. Only 1 per table allowed*/
(
	[MembershipID] ASC,												/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
	[AmenityID] ASC
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
                            ON [PRIMARY]							/*PRIMARY = default filegroup where the table/index is stored*/) ON [PRIMARY]
GO

/****************************************************************
DEFAULTS: These ensure safe inserts and prevent accidental NULLs
****************************************************************/

ALTER TABLE [dbo].[DAC_Membership_Amenity] ADD  DEFAULT ((1)) FOR [IncludedFlag]
/*If IncludedFlag isn't provided during insert, SQL sets it to 1 (included). Amenities are assumed included unless explicitly marked otherwise.*/
GO

/*************************************************************************************** 
FOREIGN KEYS & CHECK CONSTRAINTS
-Foreign keys enforce "no orphan records".
--Meaning: you cannot link a membership to an amenity that doesn't exist.
- Check Constraints enforce business rules + prevent bad data.
****************************************************************************************/

ALTER TABLE [dbo].[DAC_Membership_Amenity]  WITH CHECK ADD  CONSTRAINT [FK_DAC_Membership_Amenity_Amenity] FOREIGN KEY([AmenityID])
REFERENCES [dbo].[DAC_Amenity] ([AmenityID])
ON DELETE CASCADE
/*Foreign Key: AmenityID must exist in dbo.DAC_Amenity. ON DELETE CASCADE removes this amenity pairing if the amenity is deleted.*/
GO

ALTER TABLE [dbo].[DAC_Membership_Amenity] CHECK CONSTRAINT [FK_DAC_Membership_Amenity_Amenity]
GO

ALTER TABLE [dbo].[DAC_Membership_Amenity]  WITH CHECK ADD  CONSTRAINT [FK_DAC_Membership_Amenity_Membership] FOREIGN KEY([MembershipID])
REFERENCES [dbo].[DAC_membership] ([MembershipID])
ON DELETE CASCADE											/*ON DELETE CASCADE: If a parent record is deleted (e.g., an amenity), all child records that reference 
															it are automatically deleted too (e.g., all membership-amenity pairings for that amenity).
															Use with caution: It's convenient but risky—deleting one thing can wipe out many related records. 
															Many teams prefer soft-deletes (marking as inactive) instead*/

/*Foreign Key: MembershipID must exist in dbo.DAC_membership. 
ON DELETE CASCADE removes this amenity pairing if the membership is deleted.*/
GO

ALTER TABLE [dbo].[DAC_Membership_Amenity] CHECK CONSTRAINT [FK_DAC_Membership_Amenity_Membership]
GO

