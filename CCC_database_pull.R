### This will run the SQL pull. Originally derived from the sproc. 
### Here's its history:
# -- =============================================
# -- Author:		Kim Osterback
# -- Create date: 15 August 2008
# -- Description:	Stored procedure to pull CCC Data
# -- Called by:   Pull_CCC_Data.rdl
# -- Depends on: [Config].[ufn_ATITEASInfo]
# -- Updated 7/20/2009 for 2009.
# -- Modifed 8/31/2009 by Carl Bettis for Next Gen system.
# -- updated 7/19/2010 for 2010 by cbettis
# -- updated 8/15/2011 by Praveena/Brad ,ticket #24346
# -- Updated 09/30/2014 by SWilbanks to fix issue with Science calculation
# -- =============================================

instid <- 6341
startdate <- '20160101'
enddate <- '20170930'

#move this bit over into the main script once QC complete to avoid re-connecting
library(RODBC) 
db <- odbcDriverConnect('driver={SQL Server};server=asc-prd-sql07;trusted_connection=true')


query_setup <- "
USE [asm]
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

BEGIN

SET NOCOUNT ON;

CREATE TABLE #TEMP
(
  userid INT
  ,assessmentid INT
  ,bookletid BIGINT
  ,created DATETIME
  ,[first] BIT
  ,[rank] FLOAT
  ,attempt INT
  ,attempts INT
  ,[days] INT
  ,Reading FLOAT
  ,Math FLOAT
  ,science FLOAT
  ,English FLOAT
  ,Total FLOAT
  ,ReadingPR INT
  ,MathPR INT
  ,SciencePR INT
  ,EnglishPR INT
  ,TotalPR INT
)

INSERT INTO #TEMP
(
  userid
  ,assessmentid
  ,bookletid
  ,created
  ,attempt
  ,attempts
  ,[days]
  ,Reading
  ,Math
  ,science
  ,English
  ,Total
  ,ReadingPR
  ,MathPR
  ,SciencePR
  ,EnglishPR
  ,TotalPR
)
SELECT 
BB.UserID
,BB.AssessmentID
,BB.BookletID
,BB.Created
,BB.Attempt
,BB.Attempts
,BB.[Days] 
,SUM(CASE 
WHEN S.Name LIKE 'TEAS Reading%' OR S.Name LIKE 'Reading'
THEN ISNULL(SS.AdjPercentage, SS.Percentage) 
ELSE 0 
END) AS 'ReadingPercentage'
,SUM(CASE 
WHEN S.Name LIKE 'TEAS Math%' OR S.Name LIKE 'Math' 
THEN ISNULL(SS.AdjPercentage, SS.Percentage) 
ELSE 0 
END) AS 'MathPercentage'
,SUM(CASE 
WHEN S.Name LIKE 'TEAS Science%' OR S.Name LIKE 'Science' 
THEN ISNULL(SS.AdjPercentage, SS.Percentage) 
ELSE 0 
END) AS 'SciencePercentage'
,SUM(CASE 
WHEN S.Name LIKE 'TEAS English%' OR S.Name LIKE 'English and Language Usage'  
THEN ISNULL(SS.AdjPercentage, SS.Percentage) 
ELSE 0 
END) AS 'EnglishPercentage'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.SectionID = 0 
)
THEN ISNULL(SS.AdjPercentage, SS.Percentage) 
ELSE 0 
END) AS 'Total_TestPercentage'
,SUM(CASE 
WHEN S.Name LIKE 'TEAS Reading%' OR S.Name LIKE 'Reading'
THEN ISNULL(SS.AdjPercentile, SS.Percentile) 
ELSE 0 
END) AS 'ReadingPercentile'
,SUM(CASE 
WHEN S.Name LIKE 'TEAS Math%' OR S.Name LIKE 'Math' 
THEN ISNULL(SS.AdjPercentile, SS.Percentile) 
ELSE 0 
END) AS 'MathPercentile'
,SUM(CASE 
WHEN S.Name LIKE 'TEAS Science%' OR S.Name LIKE 'Science'
THEN ISNULL(SS.AdjPercentile, SS.Percentile) 
ELSE 0 
END) AS 'SciencePercentile'
,SUM(CASE 
WHEN S.Name LIKE 'TEAS English%' OR S.Name LIKE 'English and Language Usage'
THEN ISNULL(SS.AdjPercentile, SS.Percentile) 
ELSE 0 
END) AS 'EnglishPercentile'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3
AND S.SectionID = 0
)
THEN ISNULL(SS.AdjPercentile, SS.Percentile) 
ELSE 0 
END) AS 'Total_TestPercentile'
FROM (
SELECT 
SectionID
,A.AssessmentID
,AdjPercentage
,Percentage
,AdjPercentile
,Percentile
,BookletID
FROM [Stats].SectionScore SS1 WITH(NOLOCK)
INNER JOIN Config.Assessment A WITH(NOLOCK)
ON A.AssessmentID = SS1.AssessmentID
WHERE A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3
) SS
INNER JOIN Config.Section S WITH(NOLOCK)
ON S.SectionID = SS.SectionID 
INNER JOIN Config.Assessment A WITH(NOLOCK)
ON A.AssessmentID = SS.AssessmentID 
INNER JOIN [Stats].Booklet B WITH(NOLOCK) 
ON B.BookletID = SS.BookletID
INNER JOIN (
SELECT 
B.UserID
,B.AssessmentID
,B.BookletID
,B.Created
,Config.ufn_ATITEASInfo(B.BookletID, 1) AS 'Attempt'
,Config.ufn_ATITEASInfo(B.BookletID, 2) AS 'Attempts'
,Config.ufn_ATITEASInfo(B.BookletID, 3) AS 'Days' 
FROM [Stats].Booklet B WITH(NOLOCK)
INNER JOIN Config.Assessment A WITH(NOLOCK)
ON A.AssessmentID = B.AssessmentID 
WHERE B.InstitutionID = @InstitutionID
AND A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3
AND B.StatusID = 31 
AND B.Created BETWEEN @StartDate AND @EndDate

UNION

SELECT DISTINCT
B.UserID
,B.AssessmentID
,B.BookletID
,B.Created
,Config.ufn_ATITEASInfo(B.BookletID, 1) AS 'Attempt'
,Config.ufn_ATITEASInfo(B.BookletID, 2) AS 'Attempts'
,Config.ufn_ATITEASInfo(B.BookletID, 3) AS 'Days' 
FROM [E-Com].dbo.TEASSendResultDetail TSR WITH(NOLOCK)
INNER JOIN Config.Batch BA WITH(NOLOCK) 
ON BA.BatchID = TSR.BatchID
INNER JOIN [Stats].Booklet B WITH(NOLOCK) 
ON B.BatchID = BA.BatchID 
AND B.UserID = TSR.OwnerID
INNER JOIN Config.Institution I WITH(NOLOCK) 
ON I.InstitutionID = TSR.InstitutionID
INNER JOIN Config.Institution I2 WITH(NOLOCK) 
ON I2.InstitutionID = B.InstitutionID
WHERE I.InstitutionID = @InstitutionID 
AND B.StatusID = 31 
AND B.Created BETWEEN @StartDate AND @EndDate
) BB 
ON BB.BookletID = B.BookletID
GROUP BY 
BB.UserID
,BB.AssessmentID
,BB.BookletID
,BB.Created
,BB.Attempt
,BB.Attempts
,BB.[Days]

-- Mark First Booklet
UPDATE #TEMP 
SET [first] = 1 
WHERE bookletid IN (
SELECT 
MIN(T.BookletID) 
FROM #TEMP T 
INNER JOIN Config.Assessment A 
ON A.AssessmentID = T.AssessmentID 
WHERE A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
GROUP BY
T.userid
)

UPDATE #TEMP 
SET [first] = 0 
WHERE [first] IS NULL

-- TEAS
UPDATE T1
SET T1.[rank] = T2.[rank] 
FROM #TEMP T1
INNER JOIN (
SELECT 
T.userid
,A.AssessmentID
,T.bookletid
,T.attempt
,T.attempts
,T.total
,DENSE_RANK() OVER (
PARTITION BY 
T.userid 
ORDER BY 
T.created DESC
,T.bookletid DESC
) AS [rank] 
FROM #TEMP T 
INNER JOIN Config.Assessment A 
ON A.AssessmentID = T.AssessmentID
WHERE A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3
) T2 
ON T2.bookletid = T1.bookletid

SELECT 
i.institutionid AS 'ID'
,[data].userid
,u.lastname
,u.firstname
,u.Birthdate
,b2.created AS 'TEAS_Date'
,[data].MostRecent_ReadingPercentage AS 'Reading'
,[data].MostRecent_MathPercentage AS 'Math'
,[data].MostRecent_SciencePercentage AS 'Science'
,[data].MostRecent_EnglishPercentage AS 'English'
,[data].MostRecent_TEAS_Percentage AS 'TEAS_Composite'
,'' AS 'LVN'
,'' AS 'Age_at_Enrollment'
,'' AS 'Age_at_Enroll_Categorized'
,'' AS 'Disability_Accommodation'
,CASE 
WHEN u.languageid = 0 
THEN 'English' 
WHEN u.languageID = 1 
THEN 'Spanish' 
ELSE '' 
END AS 'Language_at_Home'
,'' AS 'Additional_Language_1'
,'' AS 'Additional_Language_2'
,CASE 
WHEN u.gender = 'M' 
THEN 'Male' 
WHEN u.gender = 'F' 
THEN 'Female' 
ELSE '' 
END AS 'Gender'
,CASE 
WHEN u.raceid = 1 
THEN 'White Non-Hispanic' 
WHEN u.raceid = 2 
THEN 'African-American'
WHEN u.raceid = 4 
THEN 'American Indian/Alaskan Native' 
WHEN u.raceid = 16 
THEN 'Asian' 
WHEN u.raceid = 8 
THEN 'Hispanic' 
ELSE '' 
END AS 'Ethnicity'
,'' AS 'Remediation_Required'
,'' AS 'Remediation_Participation'
,'' AS 'Remediation_Completed'
,'' AS 'Remediation_Completion_Date'
,'' AS 'Cohort'
,'' AS 'Anticipated_Grad_Date'
,'' AS 'Actual_Grad_Date'
,'' AS 'F07_Status'
,'' AS 'SP08_Status'
FROM (
SELECT
SS.UserID
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.bookletID 
ELSE 0 
END) AS 'MostRecent_TEAS_BookletID'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.assessmentid 
ELSE 0 
END) AS 'MostRecent_AssessmentID'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.reading 
ELSE 0 
END) AS 'MostRecent_ReadingPercentage'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.readingpr 
ELSE 0 
END) AS 'MostRecent_ReadingPercentile'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.Math 
ELSE 0 
END) AS 'MostRecent_MathPercentage'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.Mathpr 
ELSE 0 
END) AS 'MostRecent_MathPercentile'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.science 
ELSE 0 
END) AS 'MostRecent_SciencePercentage'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.sciencepr 
ELSE 0 
END) AS 'MostRecent_SciencePercentile'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.english 
ELSE 0 
END) AS 'MostRecent_EnglishPercentage'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.englishpr 
ELSE 0 
END) AS 'MostRecent_EnglishPercentile'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.total 
ELSE 0 
END) AS 'MostRecent_TEAS_Percentage'
,SUM(CASE 
WHEN (
A.AssessmentStyleID IN (6, 13) 
AND A.TestTypeID = 3 
AND SS.[rank] = 1 
)
THEN SS.totalpr 
ELSE 0 
END) AS 'MostRecent_TEAS_Percentile'
FROM #TEMP SS
INNER JOIN Config.Assessment A 
ON A.AssessmentID = SS.AssessmentID
GROUP BY 
SS.userid
) [data]
INNER JOIN [Stats].Booklet B2 WITH(NOLOCK) 
ON B2.BookletID = [data].MostRecent_TEAS_BookletID
INNER JOIN Config.atiUser U WITH(NOLOCK) 
ON U.UserID = [data].userid
INNER JOIN Config.Institution I WITH(NOLOCK) 
ON I.InstitutionID = B2.InstitutionID
LEFT OUTER JOIN Config.Class C2 WITH(NOLOCK) 
ON C2.ClassID = U.ClassID
WHERE [data].MostRecent_ReadingPercentage > 0 
AND [data].MostRecent_MathPercentage > 0 
AND [data].MostRecent_SciencePercentage > 0
AND [data].MostRecent_EnglishPercentage > 0 
AND [data].MostRecent_TEAS_Percentage > 0

DROP TABLE #temp

END
"
query_setup <- gsub("@InstitutionID", instid, query_setup)
query_setup <- gsub("@StartDate", paste0("'", startdate, "'"), query_setup)
query_setup <- gsub("@EndDate", paste0("'", enddate, "'"), query_setup)

inst_data <- sqlQuery(db, query_setup)
