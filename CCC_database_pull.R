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
startdate <- "20160101"
enddate <- "20170930"

#move this bit over into the main script once QC complete to avoid re-connecting
library(RODBC) 
db <- odbcDriverConnect('driver={SQL Server};server=asc-prd-sql07;trusted_connection=true')

