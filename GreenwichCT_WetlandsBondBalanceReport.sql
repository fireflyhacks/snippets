/*

  Greenwich CT
  
  This is a backend for an MS Word Report.
  The report finds fees by type and populates
  new columns by performing calculations.
  
*/


--DECLARE @StartDate DATETIME = '01-01-2021'
--DECLARE @EndDate DATETIME = '06-30-2021'

--Query0


select
  CreatedDate as 'Date',
  ReceiptNo as 'ReceiptNo',
  Owner_Name as 'BondReceivedFrom',
  ControlNumber as 'ApplicationNo',
  COALESCE(Amount, 0) as 'Amount',
  ReleaseDate as 'ReleaseDate1',
  COALESCE(Owner_Fax, 0) as 'ReleaseAmount1',
  COALESCE((CAST(Amount as FLOAT) - CAST(Owner_Fax as FLOAT)), '0') as 'Balance1',
  Owner_website as 'ReleaseDate2',
  COALESCE(Owner_Home_Phone, 0) as 'ReleaseAmount2',
  COALESCE((CAST(Amount as FLOAT) - CAST(Owner_Fax as FLOAT) - CAST(Owner_Home_Phone as FLOAT)), '0') as 'Balance2'
from Bond
where ISNULL(Deleted, 0) = 0
  and CreatedDate >= @StartDate
  and CreatedDate <= @EndDate
order by CreatedDate desc


--Query1


Select
  CONVERT(VARCHAR(MAX),@StartDate,101) as datestartie,
  CONVERT(VARCHAR(MAX),@EndDate,101) as dateendie;
