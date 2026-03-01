USE [PortfolioDB]
GO

CREATE OR ALTER   VIEW [dbo].[vw_DAC_Mart_RevenueActualsMonthly]
AS
SELECT
      dd.Year
    , dd.Month
    , dd.MonthName
    , MIN(dd.CalendarDate) AS MonthStartDate  /* First calendar date in that month */

    , fb.ChargeType

    , COUNT(DISTINCT fb.InvoiceNumber) AS InvoiceCount            /* Number of invoices */
    , SUM(fb.AmountBilled) AS TotalAmountBilled                   /* Total billed revenue */
    , SUM(fb.AmountPaid) AS TotalAmountPaid                       /* Total collected */
    , SUM(fb.BalanceAmount) AS TotalOutstandingBalance            /* Remaining balance */

FROM dbo.DAC_Fact_Billing fb
JOIN dbo.Dim_Date dd
    ON fb.InvoiceDateKey = dd.DateKey

WHERE fb.IsVoidedIND = 0  /* Exclude voided transactions */

GROUP BY
      dd.Year
    , dd.Month
    , dd.MonthName
    , fb.ChargeType;
GO


