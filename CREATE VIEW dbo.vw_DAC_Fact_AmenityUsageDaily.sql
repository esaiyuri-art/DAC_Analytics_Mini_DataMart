USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Fact_AmenityUsageDaily]
AS
SELECT
    ue.UsageDay,
    ue.Year,
    ue.Month,
    ue.MonthName,
    ue.DayName,
    ue.IsWeekend,

    ue.AmenityID,
    ue.AmenityName,
    ue.AmenityCategory,

    COUNT(*) AS UsageCount,
    COUNT(DISTINCT ue.CustomerID) AS UniqueMembers
FROM dbo.vw_DAC_Fact_AmenityUsageEvent ue
GROUP BY
    ue.UsageDay,
    ue.Year,
    ue.Month,
    ue.MonthName,
    ue.DayName,
    ue.IsWeekend,
    ue.AmenityID,
    ue.AmenityName,
    ue.AmenityCategory;
GO


