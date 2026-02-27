USE [PortfolioDB] /*Replace PortfolioDB with whatever your database name is. If you don't run USE, your table might get created in the wrong database.*/
GO

/****************************************************************************************************************************************************
Object Name: dbo.fn_GetCurrentAge
Object Type: Scalar Function
Developer/ Author: Liz Yang
Created: 2026-02-27

Purpose: Calculates the current age in years for a given date of birth. Returns an integer representing how many complete years have passed 
		 since the date of birth. Accounts for whether the birthday has occurred in the current calendar year.

Parameters:
	- @DOB [DATE]: The date of birth to calculate age from.

Returns:
	- INT: The person's current age in complete years.

Logic:
	1. Calculate the difference in years between DOB and today's date.
	2. Check if the birthday has already occurred this year by adding the calculated years back to the DOB.
	3. If that date is in the future, subtract 1 (birthday hasn't happened yet this year).
	4. Return the final age.

Example Usage:
	SELECT dbo.fn_GetCurrentAge('1990-03-15') AS CurrentAge;
	-- Returns: 35 (if today is after March 15, 2025) or 34 (if today is before March 15, 2025)

Notes for Junior devs:
	- Scalar functions return a single value (not a table). Use them in SELECT, WHERE, or JOIN conditions.
	- DATEDIFF calculates the difference between two dates. DATEDIFF(YEAR, @DOB, GETDATE()) counts year boundaries crossed.
	- DATEADD adds/subtracts time from a date. DATEADD(YEAR, @Age, @DOB) reconstructs what the birthday is in the current year.
	- GETDATE() returns the current system date and time.

****************************************************************************************************************************************************/

CREATE FUNCTION [dbo].[fn_GetCurrentAge]
(
    @DOB DATE		/*Date of birth to calculate age from.*/
)
RETURNS INT			/*Returns an integer representing age in complete years.*/
AS
BEGIN
    DECLARE @Age INT;	/*Variable to store the calculated age.*/

    SET @Age = DATEDIFF(YEAR, @DOB, GETDATE());
	/*Calculate the number of year boundaries between DOB and today. This may be off by 1 if birthday hasn't occurred yet.*/

    -- Subtract 1 if birthday hasn't occurred yet this year
    IF (DATEADD(YEAR, @Age, @DOB) > GETDATE())
		/*Check if adding the calculated years to DOB results in a future date (birthday hasn't happened yet this year).*/
        SET @Age = @Age - 1;	/*If birthday is in the future, reduce age by 1 to get complete years only.*/

    RETURN @Age;	/*Return the final calculated age.*/
END;
GO

