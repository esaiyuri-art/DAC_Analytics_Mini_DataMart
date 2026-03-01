USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Fact_AmenityMonthlyPerformance]
AS
SELECT
    ms.AmenityID,
    a.AmenityName,
    a.AmenityCategory,

    ms.YearNumber,
    ms.MonthNumber,
    ms.MonthStartDate,

    ms.TotalUsageCount,
    ms.UniqueMemberCount,

    -- If TotalOperatingCost is already stored, use it. Otherwise estimate it.
    COALESCE(
        ms.TotalOperatingCost,
        (ISNULL(c.MonthlyFixedCost, 0) + (ISNULL(c.CostPerUse, 0) * ISNULL(ms.TotalUsageCount, 0)))
    ) AS TotalOperatingCost_Est,

    -- Member spend only really applies to pay-per-use amenities (or however you define it).
    COALESCE(
        ms.TotalMemberSpend,
        (CASE WHEN ISNULL(c.InDuesIND, 1) = 0
              THEN (ISNULL(c.MemberCostPerUse, 0) * ISNULL(ms.TotalUsageCount, 0))
              ELSE 0
         END)
    ) AS TotalMemberSpend_Est,

    -- Helpful ratios
    CASE WHEN ISNULL(ms.TotalUsageCount, 0) = 0 THEN NULL
         ELSE COALESCE(
                ms.TotalOperatingCost,
                (ISNULL(c.MonthlyFixedCost, 0) + (ISNULL(c.CostPerUse, 0) * ms.TotalUsageCount))
              ) / NULLIF(ms.TotalUsageCount, 0)
    END AS OperatingCostPerUse_Est

FROM dbo.DAC_AmenityUsageMonthlySummary ms
JOIN dbo.DAC_Amenity a
    ON ms.AmenityID = a.AmenityID
LEFT JOIN dbo.DAC_Amenity_Cost c
    ON ms.AmenityID = c.AmenityID;
GO


