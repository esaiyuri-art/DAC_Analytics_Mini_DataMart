USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don’t run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_Amenity
Object Type: Dimension Table
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Stores master list of club amenities available for usage. Serves as a dimension table referenced by transactional and aggregate fact tables.

Grain: 1 row = 1 unique amenity.

Design Decisions:
    - AmenityID implemented as IDENTITY surrogate key to ensure stable joins across fact tables.
    - AmenityName enforced as UNIQUE to prevent duplicate business keys.
    - AmenityCategory stored as descriptive attribute to support BI grouping (e.g., Athletic, Dining, Social).
    - ActiveFlag defaults to 1 to support soft-deactivation without physical deletion.

Constraints:
    - PK_DAC_Amenity: Clustered primary key on AmenityID.
    - UQ_DAC_Amenity_Name: Enforces business uniqueness.
    - Default constraint on ActiveFlag ensures new records
      are active unless explicitly disabled.

Error Log: If this fails with "There is already an object named DAC_Amenity", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE [dbo].[DAC_Amenity]
(
/*Columns for your new table*/
	[AmenityID] [int] IDENTITY(1,1) NOT NULL,			/*We use IDENTITY(1,1) so SQL Server automatically gives every row its own number. 
														This is called a "surrogate key" (a system-generated unique ID).*/
	[AmenityName] [nvarchar](100) NOT NULL,
														/*We use NVARCHAR instead of VARCHAR so it supports Unicode (more character types)*/
	[AmenityCategory] [nvarchar](100) NOT NULL,
	[ActiveFlag] [bit] NOT NULL,
														/* BIT = 0 or 1 (Inactive/Active). */

 CONSTRAINT [PK_DAC_Amenity] PRIMARY KEY CLUSTERED		/*PK = Primary Key*/
														/*Clustered Indexes are great for query optimization because the table is physically sorted 
														by this column. Only 1 per table allowed*/
(
	[AmenityID] ASC										/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
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

 CONSTRAINT [UQ_DAC_Amenity_Name] UNIQUE NONCLUSTERED 
 /*NonClustered Indexes are great for query optimization too as they work similar to an appendix in a book. 
 UNIQUE (UQ) ensures no two amenities can have the same name*/

(
	[AmenityName] ASC
)

WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DAC_Amenity] ADD  DEFAULT ((1)) FOR [ActiveFlag]
/*DEFAULT (1) means if you insert a row and do NOT specify ActiveFlag, SQL Server automatically sets it to 1 (Active). This prevents accidental NULL values*/
GO


