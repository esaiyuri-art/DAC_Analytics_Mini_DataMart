USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Dim_Amenity]
AS
SELECT
    a.AmenityID,
    a.AmenityName,
    a.AmenityCategory,
    a.ActiveFlag AS AmenityActiveFlag,

    c.ActiveFlag AS CostActiveFlag,
    c.InitialBuildCost,
    c.MonthlyFixedCost,
    c.CostPerUse,
    c.UsefulLifeYears,
    c.InDuesIND,
    c.MemberCostPerUse
FROM dbo.DAC_Amenity a
LEFT JOIN dbo.DAC_Amenity_Cost c
    ON a.AmenityID = c.AmenityID;
GO


