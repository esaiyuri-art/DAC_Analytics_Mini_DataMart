USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don't run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.DAC_ErrorLog
Object Type: System/Utility Table (Error Logging)
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Centralized error logging table for capturing and auditing exceptions that occur in stored procedures, functions, and other database objects.
		 Provides full context for debugging, root cause analysis, and production support. Essential for enterprise-level data integrity and 
		 troubleshooting.

Grain: 1 row = 1 error event logged by a database object.

Design Decisions:
	- ErrorLogID implemented as IDENTITY surrogate key for unique identification and natural sort order (most recent last).
	- ProcedureName stored as NVARCHAR(255) to accommodate fully qualified names (e.g., [dbo].[sp_GetAmenityInformation]).
	- ErrorNumber captured from SQL Server's ERROR_NUMBER() function (system error codes).
	- ErrorMessage stored as NVARCHAR(4000) to capture full error text without truncation.
	- ErrorLine captured to pinpoint exact line number where error occurred (critical for debugging).
	- ErrorSeverity indicates severity level (1-25, where higher = more severe). Used to prioritize alerting.
	- Parameters stored as NVARCHAR(500) to log parameter values that triggered the error (critical for reproduction).
	- CreatedDate defaults to SYSDATETIME() to automatically track when error occurred (datetime2 precision for exact timing).
	- Clustered primary key on ErrorLogID ensures chronological ordering and optimal range queries (e.g., "errors from last 24 hours").

Constraints:
	- PK_DAC_ErrorLog: Clustered primary key on ErrorLogID.
	- DF_DAC_ErrorLog_CreatedDate: Default constraint ensures timestamp is auto-populated.
	- Optional: Add a nonclustered index on (ProcedureName, CreatedDate DESC) for quick filtering by procedure/date.

Notes for Junior devs:
	- Error logs are CRITICAL for production databases. They help you debug issues after they happen.
	- SYSDATETIME() returns the current date/time with 100 nanosecond precision (more accurate than GETDATE()).
	- ERROR_NUMBER(): SQL Server error code (0-65535). User-defined errors use 50000-65535.
	- ERROR_MESSAGE(): Full error message text (up to 2048 chars, but we use 4000 to be safe).
	- ERROR_LINE(): The line number in the script where the error occurred.
	- ERROR_SEVERITY(): How serious the error is (1=informational, 20+=severe, can crash session).
	- Retention: Consider archiving old records quarterly and truncating this table annually (keep last 2 years).

Error Log: If this fails with "There is already an object named DAC_ErrorLog", it means the table already exists. You can drop it or rename it.
****************************************************************************************************************************************************/

CREATE TABLE [dbo].[DAC_ErrorLog]
(
	/*Columns for error logging table*/
	[ErrorLogID] [int] IDENTITY(1,1) NOT NULL						/*Surrogate key: Auto-incrementing unique ID for each error log entry.
																	Ensures chronological order (most recent = highest ID).*/
	, [ProcedureName] [nvarchar](255) NOT NULL						/*Name of the stored procedure/function where error occurred.
																	Example: 'dbo.sp_GetAmenityInformation'*/
	, [ErrorNumber] [int] NOT NULL									/*SQL Server error code from ERROR_NUMBER().
																	Examples: 208=Invalid object, 207=Column undefined, 50001=Custom user error*/
	, [ErrorMessage] [nvarchar](4000) NOT NULL						/*Full text of the error message from ERROR_MESSAGE().
																	Describes what went wrong (e.g., "Invalid parameter @AmenityID...").*/
	, [ErrorLine] [int] NULL											/*Line number in the SQL script where the error occurred (from ERROR_LINE()).
																	Critical for pinpointing the exact problem in the code.*/
	, [ErrorSeverity] [int] NULL										/*Error severity level from ERROR_SEVERITY() (1-25).
																	1-10=Informational, 11-16=User/application error, 17+=System error (serious).*/
	, [Parameters] [nvarchar](500) NULL								/*Parameter values passed to the procedure at time of error.
																	Example: 'AmenityID=5, ActiveOnly=1, AmenityCategory=Athletic'
																	Helps reproduce the error and debug parameter-related issues.*/
	, [CreatedDate] [datetime2](7) NOT NULL							/*Timestamp when the error was logged (from SYSDATETIME()).
																	datetime2(7) = date + time with 100 nanosecond precision.
																	Used to filter errors by date range.*/

 CONSTRAINT [PK_DAC_ErrorLog] PRIMARY KEY CLUSTERED					/*PK = Primary Key*/
																	/*Clustered Index sorts table by ErrorLogID (chronological).
																	Makes date-range queries efficient (e.g., last 24 hours).*/
(
	[ErrorLogID] ASC												/*SQL assumes ASC order so you dont NEED to write it, but its a good best practice*/
)

                        WITH 
                            (
                                PAD_INDEX = OFF,					/*Controls how full index pages are. Default OFF is fine.*/
                            
                                STATISTICS_NORECOMPUTE = OFF,		/*Allows SQL Server to automatically update statistics.*/
                            
                                IGNORE_DUP_KEY = OFF,				/*If duplicate error ID is inserted, throw error (safer).*/
                            
                                ALLOW_ROW_LOCKS = ON,				/*Allows row-level locking during updates (good for concurrency).*/
                            
                                ALLOW_PAGE_LOCKS = ON,				/*Allows page-level locking for performance.*/
                            
                                OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF	/*Default is fine for typical error logging workload.*/
                            )
                            ON [PRIMARY]							/*PRIMARY = default filegroup where table/index is stored.*/
) ON [PRIMARY]
GO
;

/****************************************************************
DEFAULTS: These ensure safe inserts and prevent accidental NULLs
****************************************************************/

ALTER TABLE [dbo].[DAC_ErrorLog] ADD  CONSTRAINT [DF_DAC_ErrorLog_CreatedDate]  DEFAULT (SYSDATETIME()) FOR [CreatedDate]
/*If CreatedDate isn't provided during insert, SQL automatically sets it to the current system datetime.
  SYSDATETIME() provides 100 nanosecond precision (more accurate than GETDATE()).*/
GO

/*********************************************************************************************************
OPTIONAL: CREATE NONCLUSTERED INDEX FOR COMMON QUERY PATTERNS
This index speeds up queries like "Show me all errors from sp_GetAmenityInformation in the last 24 hours"
Uncomment if you plan to query errors frequently by procedure name and date.
*********************************************************************************************************/

/*
CREATE NONCLUSTERED INDEX [IX_DAC_ErrorLog_ProcedureDate] 
	ON [dbo].[DAC_ErrorLog] ([ProcedureName] ASC, [CreatedDate] DESC)
	INCLUDE ([ErrorNumber], [ErrorMessage], [ErrorSeverity])
	WITH (STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	ON [PRIMARY]
GO

-- This index allows queries like:
-- SELECT * FROM dbo.DAC_ErrorLog 
-- WHERE ProcedureName = 'dbo.sp_GetAmenityInformation' 
-- AND CreatedDate >= DATEADD(HOUR, -24, SYSDATETIME()) 
-- ORDER BY CreatedDate DESC
*/

/***********************************************************************
SAMPLE USAGE: How to query the error log
***********************************************************************/

/*
-- View all errors from last 24 hours (ordered by most recent first)
SELECT 
	[ErrorLogID]
	, [ProcedureName]
	, [ErrorNumber]
	, [ErrorMessage]
	, [ErrorLine]
	, [ErrorSeverity]
	, [Parameters]
	, [CreatedDate]
FROM [dbo].[DAC_ErrorLog]
WHERE [CreatedDate] >= DATEADD(HOUR, -24, SYSDATETIME())
ORDER BY [CreatedDate] DESC;

-- View all errors from a specific procedure
SELECT 
	[ErrorLogID]
	, [ErrorNumber]
	, [ErrorMessage]
	, [ErrorLine]
	, [Parameters]
	, [CreatedDate]
FROM [dbo].[DAC_ErrorLog]
WHERE [ProcedureName] = 'dbo.sp_GetAmenityInformation'
ORDER BY [CreatedDate] DESC;

-- Count errors by severity level
SELECT 
	[ErrorSeverity]
	, COUNT(*) AS [ErrorCount]
FROM [dbo].[DAC_ErrorLog]
WHERE [CreatedDate] >= DATEADD(DAY, -7, CAST(SYSDATETIME() AS DATE))
GROUP BY [ErrorSeverity]
ORDER BY [ErrorSeverity] DESC;

-- Find the most frequently occurring errors
SELECT TOP 10
	[ErrorNumber]
	, [ErrorMessage]
	, COUNT(*) AS [Occurrences]
FROM [dbo].[DAC_ErrorLog]
WHERE [CreatedDate] >= DATEADD(DAY, -30, CAST(SYSDATETIME() AS DATE))
GROUP BY [ErrorNumber], [ErrorMessage]
ORDER BY [Occurrences] DESC;
*/
