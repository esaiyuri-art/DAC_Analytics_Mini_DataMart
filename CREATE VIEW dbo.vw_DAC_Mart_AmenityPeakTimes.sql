USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Mart_AmenityPeakTimes]
AS
SELECT
    ue.AmenityID,
    ue.AmenityName,
    ue.AmenityCategory,

    ue.DayName,
    ue.IsoDayOfWeek,
    DATEPART(hour, ue.UsageDate) AS UsageHour,

    COUNT(*) AS UsageCount,
    COUNT(DISTINCT ue.CustomerID) AS UniqueMembers
FROM dbo.vw_DAC_Fact_AmenityUsageEvent ue
GROUP BY
    ue.AmenityID,
    ue.AmenityName,
    ue.AmenityCategory,
    ue.DayName,
    ue.IsoDayOfWeek,
    DATEPART(hour, ue.UsageDate);
GO


