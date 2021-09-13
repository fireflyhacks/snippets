/*

  GreenwichTownCT
  FSE Renewal Script 2021
  ABG 09/10/21

*/


--[TEMP TABLE FOR ACCESS TO OLD LICENSES]------------------------------------------------------

create table #FSEList (
  Temp_FSEList_ID varchar(50),
  License_ID varchar(50),
  Occupant_ID varchar(50),
  LicenseType varchar(50),
  Modified DATETIME,
  CreatedDate DATETIME,
  Name varchar(100),
  Addr1 varchar(100),
  City varchar(100),
  State varchar(25),
  Zip varchar(25),
  Phone varchar(50),
  Company_Name varchar(100),
  Company_Addr1 varchar(100),
  Company_City varchar(100),
  Company_State varchar(25),
  Company_Zip varchar(25),
  Latitude varchar(50),
  Longitude varchar(50),
  CreatedBy varchar(50),
  ModifiedBy varchar(50),
  Renewed SMALLINT,
  BusinessName varchar(100),
  LegalAddress varchar(100),
  IsQuickEntity SMALLINT
)


insert into #FSEList
select 
  '91919191',
  License.License_ID,
  Occupant.Occupant_ID,
  License.LicenseType,
  License.Modified,
  License.CreatedDate,
  License.Name,
  License.Addr1,
  License.City,
  License.State,
  License.Zip,
  License.Phone,
  License.Company_Name,
  License.Company_Addr1,
  License.Company_City,
  License.Company_State,
  License.Company_Zip,
  License.Latitude,
  License.Longitude,
  License.CreatedBy,
  License.ModifiedBy,
  License.Renewed,
  License.BusinessName,
  License.LegalAddress,
  License.IsQuickEntity
from Occupant
  left outer join UserDefinedValue UDV on UDV.Entity_ID = Occupant.Occupant_ID
  left outer join UserDefinedField UDF on UDF.UserDefinedField_ID = UDV.UserDefinedField_ID
  left outer join mpEntity mpOL on mpOL.TableName1 = 'Occupant'
    and mpOL.TableName2 = 'License'
    and mpOL.Entity1Code_ID = Occupant.Occupant_ID
  left outer join License on License.License_ID = mpOL.Entity2Code_ID
where ISNULL(Occupant.Deleted, 0) = 0
  and ISNULL(UDV.Deleted, 0) = 0
  and ISNULL(UDF.Deleted, 0) = 0
  and UDF.UserDefinedField_ID = 1878 --This is the "Status" field that they change on occupant
  and UDV.Value = 'Open' --Health Dept. states that only those Occupants with a Status of "Open" should receieve letters
  and YEAR(License.ExpirationDate) = YEAR(GETDATE())
  and MONTH(License.ExpirationDate) >= 9 --Class IV and II Renewals happen in September
  and Occupant.OccupancyType IN('Food Service Establishment', 'Food Store')
   

--[UPDATE THE STATUS OF CURRENT ISSUED LICENSES TO EXPIRED]------------------------------------

update License
set Status = 'Expired', Temp_License_ID = '00090121'
where License_ID IN(select License_ID from #FSEList)


--[CREATE NEW LICENSES WITH DIFFERENT PREFIX BASED ON OCCUPANCYTYPE]---------------------------

insert into License (
  Temp_License_ID,
  RenewalNumber,
  LicenseType,
  Modified,
  CreatedDate,
  Name,
  Addr1,
  City,
  State,
  Zip,
  Phone,
  Company_Name,
  Company_Addr1,
  Company_City,
  Company_State,
  Company_Zip,
  Latitude,
  Longitude,
  CreatedBy,
  ModifiedBy,
  Renewed,
  BusinessName,
  LegalAddress,
  IsQuickEntity
)  
select
  '91919191', --Temp_License_ID, same as the one in the temp table
  #FSEList.Occupant_ID, --Occupant_ID for linking
  #FSEList.LicenseType,
  GETDATE(), --Modified
  GETDATE(), --CreatedDate
  #FSEList.Name,
  #FSEList.Addr1,
  #FSEList.City,
  #FSEList.State,
  #FSEList.Zip,
  #FSEList.Phone,
  #FSEList.Company_Name,
  #FSEList.Company_Addr1,
  #FSEList.Company_City,
  #FSEList.Company_State,
  #FSEList.Company_Zip,
  #FSEList.Latitude,
  #FSEList.Longitude,
  'M5FSE2021', --CreatedBy
  'M5FSE2021', --ModifedBy
  0, --Renewed
  #FSEList.BusinessName,
  #FSEList.LegalAddress,
  0, --IsQuickEntity,
  CONCAT (
    CASE
	  WHEN Occupant.OccupancyType = 'Food Service Establishment'
	    THEN 'FSIV2022'
	  WHEN Occupant.OccupancyType = 'Food Store'
	    THEN 'FSII2022'
	  ELSE 'XXXXXXX'
	END
  , FORMAT(ROW_NUMBER() OVER(order by Occupant.Name), '0000')
  ) as LicenseNumber
from #FSEList
left outer join Occupant on Occupant.Occupant_ID = #FSEList.Occupant_ID


--[LINK NEW LICENSES TO OCCUPANT]--------------------------------------------------------------

insert into mpEntity (
  Temp_EntityMap_ID,
  TableName1,
  TableName2,
  Entity1Code_ID,
  Entity2Code_ID
)
select
  '29292929',
  'Occupant',
  'License',
  RenewalNumber, --Occupant_ID from Temp Table
  License_ID
from License
where Temp_License_ID = '91919191'


--[COPY OCCUPANT CONTACTS OVER TO NEW LICENSES]-------------------------------------------------

insert into mpEntity (
  Temp_EntityMap_ID,
  TableName1,
  TableName2,
  Entity1Code_ID,
  Entity2Code_ID
)
select
  '97979797',
  'License',
  'Contact',
  License.License_ID,
  LicOccConts.Contact_ID
from License
  left outer join mpEntity LicOccContsMap on LicOccContsMap.Entity1Code_ID = License.RenewalNumber
    and LicOccContsMap.TableName1 = 'Occupant'
	and LicOccContsMap.TableName2 = 'Contact'
  left outer join Contact LicOccConts on LicOccConts.Contact_ID = LicOccContsMap.Entity2Code_ID
where Temp_License_ID = '91919191'


--[CREATE FEES FOR THE NEW LICENSES]-----------------------------------------------------------

insert into Fee (
  Temp_Fee_ID,
  FeeType,
  Amount,
  Paid,
  InvoicedDate,
  Section_ID,
  GLCode
)
select
  '07070707',
  --get license type
  CASE
    WHEN #FSEList.LicenseType = 'Food Store License'
	  THEN 'Health Class II Food Establishment'
	WHEN #FSEList.LicenseType = 'Food Service Establishment License'
	  THEN 'Health Class IV Food Establishment'
	ELSE 'XXXXXX'
  END,
  --get fee amount
  CASE
    WHEN #FSEList.LicenseType = 'Food Store License'
	  THEN '211'
	WHEN #FSEList.LicenseType = 'Food Service Establishment License'
	  THEN 
	  CASE
	    WHEN Occupant.OccupantCertificateNumber = 'Country Club/Hotel' 
	      THEN '474'
	    WHEN Occupant.OccupantCertificateNumber = 'Caterer' 
	      THEN '408'
	    WHEN Occupant.OccupantCertificateNumber IS NULL 
	      THEN '426'
	    WHEN Occupant.OccupantCertificateNumber = 'Food Service Establishment' 
	      THEN '426'
	    ELSE '426'
      END
	ELSE 'XXXXXX'
  END,
  '0', --unpaid
  GETDATE(), --invoice date
  License.LicenseNumber, --put license number into fee for linkage
  --get GLCode
  CASE
    WHEN #FSEList.LicenseType = 'Food Store License'
	  THEN 'A405-42124'
	WHEN #FSEList.LicenseType = 'Food Service Establishment License'
	  THEN 'A405-42123'
	ELSE 'XXXXXX'
  END,
  Occupant.OccupantCertificateNumber
from #FSEList
  left outer join Occupant on Occupant.Occupant_ID = #FSEList.Occupant_ID --get Occupant from FSEList
  left outer join License on CAST(License.RenewalNumber as varchar) = CAST(Occupant.Occupant_ID as varchar) --get License from Occupant
where Occupant.OccupantCertificateNumber NOT IN ('Town-Owned','Public School'/*,'Senior Care Facility'*/) --don't generate fees for these establishment types
  and License.Temp_License_ID = '91919191'

--[LINK FEES TO LICENSES]----------------------------------------------------------------------

insert into mpEntity (
  Temp_EntityMap_ID,
  TableName1,
  TableName2,
  Entity1Code_ID,
  Entity2Code_ID
)
select
  '64646464',
  'License',
  'Fee',
  License_ID,
  Fee_ID
from Fee
  left outer join License on License.License_ID = Fee.Section_ID
where Temp_Fee_ID = '07070707'


/*[END]-------------------------------------------------------------------*/drop table #FSEList




/******************************************
*                                         *
*  Temp IDs Legend:                       *
*                                         *
*  Old Licenses: '00090121'               *
*  New Licenses: '91919191'               *
*  New Fees: '07070707'                   *
*  mpEntity Occupant-License: '29292929'  *
*  mpEntity License-Contact: '97979797'   *
*  mpEntity License-Fee: '64646464'       *
*                                         *
******************************************/

