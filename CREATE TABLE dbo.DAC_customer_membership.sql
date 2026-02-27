USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don't run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_customer_membership
Object Type: Bridge/Junction Table (Dimension)
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Stores the relationship between customers and memberships. Acts as a bridge table that tracks each customer's membership enrollments, 
		 join dates, renewal dates, and status (active/inactive). Links transactional data (like amenity usage) to specific customer membership records.

Grain: 1 row = 1 customer + 1 membership enrollment (one enrollment record per customer-membership combination).

Design Decisions:
	- DACCustomerMembershipID implemented as IDENTITY surrogate key to uniquely identify each customer membership enrollment.
	- UQ_DAC_customer_membership_CustomerID enforces that each customer can only have ONE active membership at a time.
	- ActiveIND defaults to 1 to support soft-deactivation without deleting enrollment history.
	- EmployeeIND defaults to 0 to distinguish employee memberships from regular member memberships.
	- CreatedDate defaults to SYSDATETIME() to automatically track enrollment creation timestamp.
	- JoinDate and RenewalDate stored as DATE (not DATETIME) since specific times are not needed.

Constraints:
	- PK_DAC_customer_membership: Clustered primary key on DACCustomerMembershipID.
	- UQ_DAC_customer_membership_CustomerID: Ensures only 1 membership per customer (business rule enforcement).
	- FK_DACCustomer_Customer: Enforces referential integrity - all CustomerIDs must exist in dbo.customer.
	- FK_DACCustomer_Membership: Enforces referential integrity - all MembershipIDs must exist in dbo.DAC_membership.

Notes for Junior devs:
	- Bridge tables (also called junction tables) connect two tables that have a many-to-many relationship.
	- In this case: 1 customer can have multiple memberships over time, and 1 membership type can have multiple customers.

Error Log: If this fails with "There is already an object named DAC_customer_membership", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE [dbo].[DAC_customer_membership]
(
	/*Columns for your membership enrollment table*/
	[DACCustomerMembershipID] [int] IDENTITY(1,1) NOT NULL,			/*We use IDENTITY(1,1) so SQL Server automatically gives every row its own number. 
																	This is called a "surrogate key" (a system-generated unique ID).*/
	[CustomerID] [int] NOT NULL,
	[MembershipID] [int] NOT NULL,
	[JoinDate] [date] NOT NULL,										
	[RenewalDate] [date] NOT NULL,									
	[ActiveIND] [bit] NOT NULL,										/* BIT = 0 or 1 (Inactive/Active). */
	[EmployeeIND] [bit] NOT NULL,									
	[CreatedDate] [datetime2](7) NOT NULL,							/* datetime2 stores date + time (7) means maximum fractional seconds precision */

PRIMARY KEY CLUSTERED												/*PK = Primary Key. Clustered Indexes are great for query optimization because the table is physically sorted 
																	by this column. Only 1 per table allowed*/
(
	[DACCustomerMembershipID] ASC									/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
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

 CONSTRAINT [UQ_DAC_customer_membership_CustomerID] UNIQUE NONCLUSTERED	/*NonClustered Indexes are great for query optimization too as they work similar to an appendix in a book. 
																						 UNIQUE (UK) ensures no two amenities can have the same name*/
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****************************************************************
DEFAULTS: These ensure safe inserts and prevent accidental NULLs
****************************************************************/

ALTER TABLE [dbo].[DAC_customer_membership] ADD  DEFAULT ((1)) FOR [ActiveIND]
/*If ActiveIND isn't provided during insert, SQL sets it to 1 (active). New enrollments are active by default.*/
GO

ALTER TABLE [dbo].[DAC_customer_membership] ADD  DEFAULT ((0)) FOR [EmployeeIND]
/*If EmployeeIND isn't provided during insert, SQL sets it to 0 (regular member, not employee).*/
GO

ALTER TABLE [dbo].[DAC_customer_membership] ADD  DEFAULT (sysdatetime()) FOR [CreatedDate]
/*If CreatedDate isn't provided during insert, SQL automatically sets it to the current system datetime.*/
GO

/**********************************************************************************
FOREIGN KEYS & Check Constraints
-Foreign keys enforce “no orphan records”.
--Meaning: you cannot log a usage event for a membership or amenity that doesn’t exist
- Check Constraints enforce business rules + prevent bad data.
**********************************************************************************/

ALTER TABLE [dbo].[DAC_customer_membership]  WITH CHECK ADD  CONSTRAINT [FK_DACCustomer_Customer] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[customer] ([CustomerID])
/*Foreign Key: CustomerID must exist in dbo.customer. Prevents orphan enrollment records.*/
GO

ALTER TABLE [dbo].[DAC_customer_membership] CHECK CONSTRAINT [FK_DACCustomer_Customer]
GO

ALTER TABLE [dbo].[DAC_customer_membership]  WITH CHECK ADD  CONSTRAINT [FK_DACCustomer_Membership] FOREIGN KEY([MembershipID])
REFERENCES [dbo].[DAC_membership] ([MembershipID])
/*Foreign Key: MembershipID must exist in dbo.DAC_membership. Prevents orphan enrollment records.*/
GO

ALTER TABLE [dbo].[DAC_customer_membership] CHECK CONSTRAINT [FK_DACCustomer_Membership]
GO