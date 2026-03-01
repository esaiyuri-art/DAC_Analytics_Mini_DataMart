USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Dim_MembershipAmenity]
AS
SELECT
    m.MembershipID,
    m.MembershipDescription,
    m.MembershipCategory,
    m.MonthlyDuesAmount,
    m.MonthlyMinimumSpend,
    m.InitiationFee,
    m.ActiveFlag AS MembershipActiveFlag,

    ma.AmenityID,
    a.AmenityName,
    a.AmenityCategory,
    ma.IncludedFlag,
    ma.GuestAllowanceCount,

    c.InDuesIND,
    c.MemberCostPerUse
FROM dbo.DAC_membership m
JOIN dbo.DAC_Membership_Amenity ma
    ON m.MembershipID = ma.MembershipID
JOIN dbo.DAC_Amenity a
    ON ma.AmenityID = a.AmenityID
LEFT JOIN dbo.DAC_Amenity_Cost c
    ON a.AmenityID = c.AmenityID;
GO


