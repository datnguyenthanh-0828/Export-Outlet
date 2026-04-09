Declare @CurrentDate Date = GetDate()
Declare @Month Date
Declare @PreMonth Date

Set @Month = '2026-03-01'
With #Outlet_DSM as
(

Select Cast(tmp.Month as Date) Month, Region, Area, 
    RCMID, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID, ASMID_UCE, ASMName, ASM_HeiwayID,
    SSID, SSID_UCE, SSName, SS_HeiwayID, SRID, SRID_UCE, SRName, SR_HeiwayID,
    OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
    Longitude, Latitude, Premise, Channel,
    Tier, LeadBrandName, 'DSM' Title, Email, Cast(Phone as varchar(max)) Phone,
    'Priority' = 
	Case 
		When Tier in ('Platinum','Gold') Then 'Option 1'
        When Tier in ('Silver') Then 'Option 2'
        When Tier in ('Bronze') Then 'Option 3'
        Else 'Option 4'
    End
From
	(
		Select 'Month' = @Month
			,o.RegionName Region, o.AreaID Area, 
			p3.SIS_PersonID RCMID, p3.PersonID RCMID_UCE, p3.FullName RCMName, p3.PositionID PosID_RCM, p3.HeiwayID RCM_HeiwayID,
			p2.SIS_PersonID ASMID, p2.PersonID ASMID_UCE, p2.FullName ASMName, p2.PositionID PosID_ASM, p2.HeiwayID ASM_HeiwayID,
			p1.SIS_PersonID SSID, p1.PersonID SSID_UCE, p1.FullName SSName, p1.PositionID PosID_SS, p1.HeiwayID SS_HeiwayID,
			p.SIS_PersonID SRID, p.PersonID SRID_UCE, p.FullName SRName, p.HeiwayID SR_HeiwayID, p.Title Title,
			o.Customer_ID OutletID, o.Customer_Name OutletName, seg.SegmentName Segment,
			o.Customer_Addr AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, o.Longitude, o.Latitude, 
			seg.Premise Premise, seg.Channel Channel, o.Tier, o.LeadBrandName, p.Email Email, p.Phone
		From [srp].[v_TD_Account] o 
		Join [srp].[SEM-Segment] seg 
			On o.OutletTypeID = seg.SEM_SegmentID2
		Left Join (Select * From [srp].[v_TD_Person] p Where FirstName not like '%Mer%') p
			On o.SalesRepID = p.PersonID
		Left Join [srp].[v_TD_Person] p1 On p.ReportToID = p1.PersonID
		Left Join [srp].[v_TD_Person] p2 On p1.ReportToID = p2.PersonID
		Left Join [srp].[v_TD_Person] p3 On p2.ReportToID = p3.PersonID
		where 1 = 1
		and o.closedate is null and o.StateName = 'Active' and o.StatusName = 'Opened' and o.IsReturnTC = 0 
		and o.Customer_ID like '6%'
		and o.OutletTypeID <> 2038
		and p.UserProfile Like '%DSM%'
		and Left(o.RegionID,1) Like '[1-9]'
		and seg.SegmentName --Traditional Trade--
							in ('Grocery Store','Beverage Retail Store','Grocery Store with Home Delivery'	--Traditional Off Trade--
								,'Quan Nhau Mainstream','Quan Nhau Economy','Quan Nhau Top','Group Social'	--Traditional On Trade--
								,'Young Social','Karaoke','Premium Karaoke')								--Traditional On Trade--
		and o.AreaID not like '%MO%'
		and o.Tier not in ('Waiting Group')
	) tmp

	--Order By Region, Area, /*ASMID,*/ SSID, SRID, Priority
)

--select * from #Outlet_DSM 
--where Area = 'S22'


-----------------------------------------------------------------------

, #Outlet_Volume as
(
Select --Month, 
OutletID, Sum(Quantity) Quantity, Sum(ActualHec) ActualHec
From
	(
	Select Convert(Date, Str(Concat(Left(Cast(PostingDate as varchar),4), SUBSTRING(Cast(PostingDate as varchar),6,2))*100+1)) Month, 
		 OutletID, Quantity, Volume, Quantity * Volume as ActualHec
	From [srp].[v_TF_SalesOut_ByMonth]
	Where 1 = 1
	And Convert(Date, Str(Concat(Left(Cast(PostingDate as varchar),4), SUBSTRING(Cast(PostingDate as varchar),6,2))*100+1)) = @PreMonth
	--And OutletID = 63220741
	)a
Group By  --Month, 
OutletID
)

--select top 10 * from srp.[v_TF_SalesOut_ByMonth]

, #Thongke_Outlet_DSM as
(
Select Month, Region,Area, SRID, SRID_UCE, SRName, Platinum, Gold, Silver, Bronze, Waiting_Group, 
	ISNULL(Platinum,0) + ISNULL(Gold,0) Platinum_Gold
From
(
Select Month, Region, Area,SRID, SRID_UCE, SRName, [Platinum],[Gold],[Silver],[Bronze],[Waiting Group] Waiting_Group
From
(
	Select Month, Region,Area, SRID, SRID_UCE, SRName, Tier, Count(OutletID) Number_Outlet
	From #Outlet_DSM
	where Region not in ('MasterData Region')
	Group By Month, Region,Area, SRID, SRID_UCE, SRName, Tier
)a
Pivot
(
	Sum(Number_Outlet)
	For Tier In ([Platinum],[Gold],[Silver],[Bronze],[Waiting Group])
)as bangchuyen
--Order By Region
)b
--Order By Region
)

--Outlet Silver DSM

, #Outlet_DSM_Silver as
(
	Select o.Month, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority, 
		v.ActualHec,
		Dense_Rank() Over (Partition by o.Month, o.SRID_UCE Order By v.ActualHec desc) STT
	From #Outlet_DSM o Left Join #Outlet_Volume v
		On o.OutletID = v.OutletID
	Where o.Tier in ('Silver')
	--And v.ActualHec > 0
	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
)



--Thống kê Outlet DSM
/*
Select *
From #Thongke_Outlet_DSM
*/


, #Outlet_DSM_Platinum_Gold as
(
	Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
	from #Outlet_DSM o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
	Where Tier in ('Platinum','Gold')
	--Order By Region, Area, RCMID, ASMID, SSID, SRID
)

, #Full_Outlet_DSM as
(
	Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
	from #Outlet_DSM o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
		--Where Tier in ('Platinum','Gold','Silver','Bronze')
)



, #Top_Outlet_DSM_Silver as
(	
	Select  Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, Region, Area, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID_UCE, ASMName, ASM_HeiwayID, SSID_UCE, SSName, SS_HeiwayID,
		SRID_UCE, SRName, SR_HeiwayID, OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
		Longitude, Latitude, Premise, Channel, Tier, LeadBrandName, Title, Email, Phone, Priority
	From #Outlet_DSM_Silver o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
	Where STT <= 30
--Order By Region, Area, SSID_UCE, SRID_UCE, Priority
)

, #Outlet_Silver as
(
	Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
	from #Outlet_DSM o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
	Where Tier in ('Silver')
	--Order By Region, Area, RCMID, ASMID, SSID, SRID
)

, #Outlet_Bronze as
(
	Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
	from #Outlet_DSM o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
	Where Tier in ('Bronze')
	--Order By Region, Area, RCMID, ASMID, SSID, SRID
)


, #Thongke_Outlet_DSM_Platinum_Gold as
(
Select Region, SRID_UCE, SRName, [Platinum],[Gold],[Silver], (Platinum + Gold + Silver) as Outlet_Platinum_Gold_Silver
From
(
	Select Region, SRID_UCE, SRName, Tier, Count(OutletID) Number_Outlet
	From #Outlet_DSM_Platinum_Gold
	Group By Region, SRID_UCE, SRName, Tier
	--Order By Region
)a
Pivot
(
	Sum(Number_Outlet)
	For Tier in ([Platinum],[Gold],[Silver])
) as bangchuyen
--Order by Region
)


, #Outlet_DSM_Bronze as
(
Select Month, BU, Region, Area, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID_UCE, ASMName, ASM_HeiwayID, SSID_UCE, SSName, SS_HeiwayID,
		SRID_UCE, SRName, SR_HeiwayID, OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
		Longitude, Latitude, Premise, Channel, Tier, LeadBrandName, Title, Email, Phone, Priority
From
(
	Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
			o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
			o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority, 
			v.ActualHec,
			Dense_Rank() Over (Partition by o.Month, o.SRID_UCE Order By v.ActualHec desc) STT
	From #Outlet_DSM o 
	Left Join #Outlet_Volume v On o.OutletID = v.OutletID
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
	Where o.Tier in ('Bronze')
	And v.ActualHec > 0
	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
)a
Where STT <= 30
)

--1. Thống kê DSM
--/*
--Select *
--From #Thongke_Outlet_DSM
--Order By Region
--*/


--2. Xuất danh sách Outlet Platinum Gold

--select *
--from #Outlet_DSM_Platinum_Gold --Done


--3. Danh sách Outlet Silver 

--select *
--from #Top_Outlet_DSM_Silver --Done

--select *
--from #Outlet_Silver
--where SRID_UCE in (1745531)

--4. Danh sách Outlet Bronze

--select *
--from #Outlet_DSM_Bronze --Done
--where SRID_UCE in (80710883)

--select *
--from #Outlet_Bronze
--where SRID_UCE in (80712138)

--5. Xuất full outlet coverage (Outlet focus segment)

select 
	 Month
	,BU
	,Region,Area
	,RCMID_UCE,RCMName,RCM_HeiwayID,ASMID_UCE,ASMName,ASM_HeiwayID,SSID_UCE,SSName,SS_HeiwayID
	,SRID_UCE,SRName,SR_HeiwayID
	,OutletID,OutletName,Segment,AddLine,WardName,DistrictName,ProvinceName,DemographicID,Longitude,Latitude
	,Premise,Channel,Tier,LeadBrandName,Title,Email,Phone,[Priority]
from #Full_Outlet_DSM
where 1=1
order by SRID_UCE, Area, Region, BU

