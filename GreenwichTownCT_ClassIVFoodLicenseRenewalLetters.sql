/*

  GreenwichTownCT
  
  This is a backend for an MS Word Report.
  The report gathers a list of entities
  and the children of those entities.
  There is an additional "Fee Amount" column
  which is selected via a case statement that checks
  for specific values.

*/


DECLARE @StartDate DATETIME = '08/01/21'
DECLARE @EndDate DATETIME = '12/31/21'


select
  --Occupant.Occupant_ID,
  Occupant.Name,
  BusinessOwner.Fullname,
  MailingAddress.Addr1 + ' ' + MailingAddress.Addr2 as 'MailingAddress',
  MailingAddress.City,
  MailingAddress.State,
  MailingAddress.Zipcode,
  CONVERT(varchar, License.ExpirationDate, 107) as ExpirationDate,
  --Conditional Block for Determining Renewal Fee based on "FacilityType" (Occupant.OccupantCertificateNumber)
  CASE
    WHEN OccupantCertificateNumber = 'Town-Owned' 
	  THEN '<N/A: No Fee Required>'
	WHEN OccupantCertificateNumber = 'Country Club/Hotel' 
	  THEN '$474'
	WHEN OccupantCertificateNumber = 'Caterer' 
	  THEN '$408'
	WHEN OccupantCertificateNumber IS NULL 
	  THEN '$207'
	WHEN OccupantCertificateNumber = 'Public School' 
	  THEN '<N/A: No Fee Required>'
	WHEN OccupantCertificateNumber = 'Food Service Establishment' 
	  THEN '$426'
	ELSE '$426'
  END AS Amount
from Occupant
--Get Business Owner
left outer join mpEntity mpBO on mpBO.TableName1 = 'Occupant'
  and mpBO.TableName2 = 'Contact'
  and mpBO.RoleGroupCode_ID = '47' --Business Owner
  and mpBO.Entity1Code_ID = Occupant.Occupant_ID
left outer join Contact BusinessOwner on BusinessOwner.Contact_ID = mpBO.Entity2Code_ID
--Get Mailing Address
left outer join mpEntity mpMA on mpMA.TableName1 = 'Occupant'
  and mpMA.TableName2 = 'Contact'
  and mpMA.RoleGroupCode_ID = '84' --Mailing Address
  and mpMA.Entity1Code_ID = Occupant.Occupant_ID
left outer join Contact MailingAddress on MailingAddress.Contact_ID = mpMA.Entity2Code_ID
left outer join UserDefinedValue UDV on UDV.Entity_ID = Occupant.Occupant_ID
left outer join UserDefinedField UDF on UDF.UserDefinedField_ID = UDV.UserDefinedField_ID
left outer join mpEntity mpOL on mpOL.TableName1 = 'Occupant'
  and mpOL.TableName2 = 'License'
  and mpOL.Entity1Code_ID = Occupant.Occupant_ID
left outer join License on License.License_ID = mpOL.Entity2Code_ID
where ISNULL(Occupant.Deleted, 0) = 0
  and ISNULL(UDV.Deleted, 0) = 0
  and ISNULL(UDF.Deleted, 0) = 0
  and ISNULL(mpBO.Deleted, 0) = 0
  and ISNULL(mpMA.Deleted, 0) = 0
  and ISNULL(BusinessOwner.Deleted, 0) = 0
  and ISNULL(MailingAddress.Deleted, 0) = 0
  and UDF.UserDefinedField_ID = 1878 --This is the "Status" field that they change on occupant
  and UDV.Value = 'Open' --Health Dept. states that only those Occupants with a Status of "Open" should receieve letters
  and YEAR(License.ExpirationDate) = YEAR(GETDATE())
  and MONTH(License.ExpirationDate) >= 9 --Class IV Renewals happen in September
  and Occupant.OccupancyType = 'Food Service Establishment'
  --and Occupant.OccupancyType = 'Food Store'

  /*
    
	IMPORTANT!

	These are for determining how many of each type are currently in the system.
	"OccupantCertificateNumber" is being used to store subcategories of Class IV Establishments.
	In M5 this field is called "FacilityType".
	This field is the cost basis for Renewal of Class IV Licenses.

  */

  --and Occupant.OccupantCertificateNumber like '%ervice%'  --Food Service Establishment
  --and Occupant.OccupantCertificateNumber like '%rivate%'  --Private School
  --and Occupant.OccupantCertificateNumber like '%aycare%'  --Daycare Facility
  --and Occupant.OccupantCertificateNumber like '%enior%'   --Senior Care Facility
  --and Occupant.OccupantCertificateNumber like '%ocial%'   --Social Club
  --and Occupant.OccupantCertificateNumber like '%aterer%'  --Caterer
  --and Occupant.OccupantCertificateNumber like '%ountry%'  --Country Club/Hotel
  --and Occupant.OccupantCertificateNumber like '%own%'     --Town-Owned
  --and Occupant.OccupantCertificateNumber like '%ublic%'   --Public School
  order by OccupancyType, OccupantCertificateNumber
