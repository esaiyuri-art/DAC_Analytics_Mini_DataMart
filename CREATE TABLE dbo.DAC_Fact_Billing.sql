USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don't run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_Fact_Billing
Object Type: Fact Table
Developer/ Author: Liz Yang
Created: 2026-02-28

Purpose: Stores billing and payment transactions for DAC members at the invoice line level. This fact table supports finance reporting such as monthly
		 dues revenue, initiation fee revenue, amenity charges, minimum spend tracking, and paid vs unpaid balances. Each row represents one billed line.

Grain: 1 row = 1 invoice line item for 1 customer membership on 1 invoice date.

Design Decisions:
	- BillingID implemented as an IDENTITY surrogate key for stable warehouse row identification.
	- InvoiceNumber + InvoiceLineNumber used as a unique natural key to prevent duplicate loads.
	- InvoiceDateKey and optional BillingPeriodStart/EndDateKey stored as INT keys to join cleanly to dbo.Dim_Date for time analysis.
	- ChargeType standardizes billing categories (Dues, Initiation, Amenity, etc.) so reporting is consistent across systems.
	- Quantity and UnitPrice stored to support per-use charges and future expansion (e.g., guest passes, food & beverage).
	- AmountBilled and BalanceAmount stored as computed columns for consistent calculations across the project.
	- Status flags (IsVoidedIND, IsRefundIND, IsCompedIND) stored as BIT for quick filtering in reports.

Constraints:
	- PK_DAC_Fact_Billing: Clustered primary key on BillingID for optimal query performance.
	- UQ_DAC_Fact_Billing_Invoice: Ensures each invoice line loads only once (InvoiceNumber, InvoiceLineNumber).
	- CK_DAC_Fact_Billing_ChargeType: Ensures ChargeType stays within approved business categories.

Notes for Junior devs:
	- Fact tables store measurable events or transactions (billing lines, usage events, payments) that can be summed and analyzed.
	- This table is the source of truth for ACTUAL billed revenue (not estimated revenue).
	- Dim_Date is used so you can group by month/year without writing date math in every query.

Error Log: If this fails with "There is already an object named DAC_Fact_Billing", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE dbo.DAC_Fact_Billing
(
      BillingID BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_DAC_Fact_Billing PRIMARY KEY CLUSTERED  /* Surrogate Key */

    , InvoiceNumber VARCHAR(50) NOT NULL                         /* Natural invoice number from source system */
    , InvoiceLineNumber INT NOT NULL                             /* Line number within invoice (prevents duplicate loads) */

    , InvoiceDateKey INT NOT NULL                                /* FK to Dim_Date (invoice posted date) */
            CONSTRAINT FK_DAC_Fact_Billing_InvoiceDateKey 
                FOREIGN KEY REFERENCES dbo.Dim_Date(DateKey)

    , BillingPeriodStartDateKey INT NULL                         /* FK to Dim_Date (start of billing period) */
            CONSTRAINT FK_DAC_Fact_Billing_BillingPeriodStartDateKey 
                FOREIGN KEY REFERENCES dbo.Dim_Date(DateKey)

    , BillingPeriodEndDateKey INT NULL                           /* FK to Dim_Date (end of billing period) */
            CONSTRAINT FK_DAC_Fact_Billing_BillingPeriodEndDateKey 
                FOREIGN KEY REFERENCES dbo.Dim_Date(DateKey)

    , PaidDateKey INT NULL                                       /* FK to Dim_Date (date payment received) */
            CONSTRAINT FK_DAC_Fact_Billing_PaidDateKey 
                FOREIGN KEY REFERENCES dbo.Dim_Date(DateKey)

    , DACCustomerMembershipID INT NOT NULL                       /* FK to DAC_customer_membership (member instance) */
            CONSTRAINT FK_DAC_Fact_Billing_DACCustomerMembershipID 
                FOREIGN KEY REFERENCES dbo.DAC_customer_membership(DACCustomerMembershipID)

    , CustomerID INT NULL                                        /* Customer identifier (reporting convenience) */

    , MembershipID INT NULL                                      /* FK to DAC_membership (membership type at billing time) */
            CONSTRAINT FK_DAC_Fact_Billing_MembershipID 
                FOREIGN KEY REFERENCES dbo.DAC_membership(MembershipID)

    , ChargeType VARCHAR(30) NOT NULL                            /* DUES / INITIATION / MIN_SPEND / AMENITY / FOOD_BEV / GUEST / OTHER */
            CONSTRAINT CK_DAC_Fact_Billing_ChargeType
                CHECK (ChargeType IN ('DUES','INITIATION','MIN_SPEND','AMENITY','FOOD_BEV','GUEST','OTHER'))

    , ChargeSubType VARCHAR(50) NULL                             /* Optional detail (locker rental, event fee, etc.) */

    , AmenityID INT NULL                                         /* FK to DAC_Amenity (required when ChargeType = AMENITY) */
            CONSTRAINT FK_DAC_Fact_Billing_AmenityID
                FOREIGN KEY REFERENCES dbo.DAC_Amenity(AmenityID)

    , Quantity DECIMAL(12,2) NOT NULL 
            CONSTRAINT DF_DAC_Fact_Billing_Quantity DEFAULT (1)  
            CONSTRAINT CK_DAC_Fact_Billing_Quantity CHECK (Quantity >= 0) /* Units billed */

    , UnitPrice DECIMAL(18,2) NOT NULL 
            CONSTRAINT DF_DAC_Fact_Billing_UnitPrice DEFAULT (0.00)
            CONSTRAINT CK_DAC_Fact_Billing_UnitPrice CHECK (UnitPrice >= 0) /* Price per unit */

    , DiscountAmount DECIMAL(18,2) NOT NULL 
            CONSTRAINT DF_DAC_Fact_Billing_Discount DEFAULT (0.00)
            CONSTRAINT CK_DAC_Fact_Billing_Discount CHECK (DiscountAmount >= 0) /* Discount applied */

	, TaxAmount DECIMAL(18,2) NOT NULL 
	        CONSTRAINT DF_DAC_Fact_Billing_Tax DEFAULT (0.00)
	        CONSTRAINT CK_DAC_Fact_Billing_Tax CHECK (TaxAmount >= 0) /* Tax amount */
	
	, AmountBilled AS (ROUND((Quantity * UnitPrice) - DiscountAmount + TaxAmount, 2)) PERSISTED /* Calculated billed amount */
	
	, AmountPaid DECIMAL(18,2) NOT NULL 
	        CONSTRAINT DF_DAC_Fact_Billing_AmountPaid DEFAULT (0.00)
	        CONSTRAINT CK_DAC_Fact_Billing_AmountPaid CHECK (AmountPaid >= 0) /* Amount paid */
	
	, BalanceAmount AS (
	      ROUND(((Quantity * UnitPrice) - DiscountAmount + TaxAmount) - AmountPaid, 2)
	  ) PERSISTED /* Remaining balance */

    , IsVoidedIND BIT NOT NULL 
            CONSTRAINT DF_DAC_Fact_Billing_IsVoided DEFAULT (0)   /* 1 = voided / cancelled */

    , IsRefundIND BIT NOT NULL 
            CONSTRAINT DF_DAC_Fact_Billing_IsRefund DEFAULT (0)   /* 1 = refund transaction */

    , IsCompedIND BIT NOT NULL 
            CONSTRAINT DF_DAC_Fact_Billing_IsComped DEFAULT (0)   /* 1 = comped by club */

    , SourceSystem VARCHAR(50) NULL                              /* ERP / POS / Accounting system source */

    , LoadDTS DATETIME2(0) NOT NULL 
            CONSTRAINT DF_DAC_Fact_Billing_LoadDTS DEFAULT (SYSUTCDATETIME()) /* Warehouse load timestamp */

    , CONSTRAINT UQ_DAC_Fact_Billing_Invoice UNIQUE (InvoiceNumber, InvoiceLineNumber)

    , CONSTRAINT CK_DAC_Fact_Billing_PeriodDates
            CHECK (BillingPeriodStartDateKey IS NULL 
                OR BillingPeriodEndDateKey IS NULL 
                OR BillingPeriodStartDateKey <= BillingPeriodEndDateKey) /* Billing period integrity */

    , CONSTRAINT CK_DAC_Fact_Billing_AmenityLogic
            CHECK (ChargeType <> 'AMENITY' OR AmenityID IS NOT NULL) /* Amenity charge must have AmenityID */
);
GO