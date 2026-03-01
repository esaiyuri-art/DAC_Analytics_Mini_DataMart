USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Mart_MemberEngagementMonthly]
AS
SELECT
    dd.Year,
    dd.Month,
    dd.MonthName,

    ue.CustomerID,
    ue.MembershipID,
    ue.EmployeeIND,

    COUNT(*) AS UsageCount,
    COUNT(DISTINCT ue.AmenityID) AS DistinctAmenitiesUsed,
    MIN(ue.UsageDate) AS FirstUseInMonth,
    MAX(ue.UsageDate) AS LastUseInMonth
FROM dbo.vw_DAC_Fact_AmenityUsageEvent ue
LEFT JOIN dbo.Dim_Date dd
    ON dd.CalendarDate = ue.UsageDay
GROUP BY
    dd.Year,
    dd.Month,
    dd.MonthName,
    ue.CustomerID,
    ue.MembershipID,
    ue.EmployeeIND;
GO


