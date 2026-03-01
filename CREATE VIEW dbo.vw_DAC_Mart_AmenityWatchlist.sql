USE [PortfolioDB]
GO

CREATE OR ALTER     VIEW [dbo].[vw_DAC_Mart_AmenityWatchlist]
AS
SELECT
    mp.YearNumber,
    mp.MonthNumber,
    mp.MonthStartDate,

    mp.AmenityID,
    mp.AmenityName,
    mp.AmenityCategory,

    mp.TotalUsageCount,
    mp.UniqueMemberCount,
    mp.TotalOperatingCost_Est,
    mp.OperatingCostPerUse_Est
FROM dbo.vw_DAC_Fact_AmenityMonthlyPerformance mp
WHERE
    mp.TotalUsageCount <= 10                 -- tweak threshold
    AND mp.TotalOperatingCost_Est >= 100;   -- tweak threshold
GO


