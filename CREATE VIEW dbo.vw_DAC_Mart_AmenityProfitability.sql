USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Mart_AmenityProfitability]
AS
SELECT
      a.AmenityID
    , a.AmenityName
    , a.AmenityCategory

    , ac.InitialBuildCost
    , ac.MonthlyFixedCost
    , ac.CostPerUse
    , ac.UsefulLifeYears

    , COALESCE(COUNT(auh.AmenityUsageID), 0) AS TotalUsageCount  /* All-time usage events */

    , COALESCE(ac.CostPerUse, 0.00) * COALESCE(COUNT(auh.AmenityUsageID), 0) AS TotalVariableCostFromUsage  /* CostPerUse * Uses */

    , COALESCE(ac.MonthlyFixedCost, 0.00)
        + (COALESCE(ac.CostPerUse, 0.00) * COALESCE(COUNT(auh.AmenityUsageID), 0)) AS TotalOperatingCost_Est /* Fixed + Variable */

    , CASE 
        WHEN COALESCE(COUNT(auh.AmenityUsageID), 0) = 0 THEN NULL
        ELSE (COALESCE(ac.MonthlyFixedCost, 0.00)
              + (COALESCE(ac.CostPerUse, 0.00) * COUNT(auh.AmenityUsageID)))
             / NULLIF(COUNT(auh.AmenityUsageID), 0)
      END AS OperatingCostPerUse_Est

    , CASE 
        WHEN COALESCE(COUNT(auh.AmenityUsageID), 0) > 0 THEN 'In Use'
        ELSE 'Underutilized'
      END AS UsageStatus

FROM dbo.DAC_Amenity a
LEFT JOIN dbo.DAC_Amenity_Cost ac
    ON a.AmenityID = ac.AmenityID
LEFT JOIN dbo.DAC_AmenityUsageHistory auh
    ON a.AmenityID = auh.AmenityID
WHERE a.ActiveFlag = 1
GROUP BY
      a.AmenityID
    , a.AmenityName
    , a.AmenityCategory
    , ac.InitialBuildCost
    , ac.MonthlyFixedCost
    , ac.CostPerUse
    , ac.UsefulLifeYears;
GO


