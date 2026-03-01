USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Fact_AmenityUsageEvent]
AS
SELECT
    uh.AmenityUsageID,
    uh.UsageDate,
    CONVERT(date, uh.UsageDate) AS UsageDay,

    dd.DateKey,
    dd.Year,
    dd.Month,
    dd.MonthName,
    dd.Quarter,
    dd.DayName,
    dd.IsoDayOfWeek,
    dd.IsWeekend,
    dd.IsHoliday,
    dd.IsBusinessDay,

    cm.DACCustomerMembershipID,
    cm.CustomerID,
    cm.MembershipID,
    cm.ActiveIND AS MembershipActiveIND,
    cm.EmployeeIND,
    cm.JoinDate,
    cm.RenewalDate,

    a.AmenityID,
    a.AmenityName,
    a.AmenityCategory
FROM dbo.DAC_AmenityUsageHistory uh
JOIN dbo.DAC_customer_membership cm
    ON uh.DACCustomerMembershipID = cm.DACCustomerMembershipID
JOIN dbo.DAC_Amenity a
    ON uh.AmenityID = a.AmenityID
LEFT JOIN dbo.Dim_Date dd
    ON dd.CalendarDate = CONVERT(date, uh.UsageDate);
GO


