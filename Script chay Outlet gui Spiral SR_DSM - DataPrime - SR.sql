------Traditional Trade---------
-------------SR-----------------

Declare @CurrentDate Date = GetDate()
Declare @Month Date
Declare @PreMonth Date

Set @Month = '2026-03-01'--Dateadd(MM,DATEDIFF(MONTH,0,@CurrentDate),0)

--Set @PreMonth = '2026-01-01'--DATEADD(MM, DATEDIFF(MM, 0, DateAdd(MM, -1, @CurrentDate)), 0);

--Select @PreMonth;
;


--SR
--/*
With #Outlet_SR as
(

Select Cast(tmp.Month as Date) Month, Region, Area, 
    RCMID, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID, ASMID_UCE, ASMName, ASM_HeiwayID,
    SSID, SSID_UCE, SSName, SS_HeiwayID, SRID, SRID_UCE, SRName, SR_HeiwayID,
    OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
    Longitude, Latitude, Premise, Channel,
    Tier, LeadBrandName,'SR' Title, Email, Cast(Phone as varchar(max)) Phone,
    'Priority' = Case When Tier in ('Platinum','Gold') Then 'Option 1'
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
		and p.UserProfile Like '%Sales%'
		and Left(o.RegionID,1) Like '[1-9]'
		and seg.SegmentName --Traditional Trade--
							in ('Grocery Store','Beverage Retail Store','Grocery Store with Home Delivery'	--Traditional Off Trade--
								,'Quan Nhau Mainstream','Quan Nhau Economy','Quan Nhau Top','Group Social'	--Traditional On Trade--
								,'Young Social','Karaoke','Premium Karaoke')								--Traditional On Trade--
		and o.AreaID not like '%MO%'
		and o.Tier not in ('Waiting Group')
		--and p.PersonID in (80706342)
		--and o.Customer_ID in (69352571)
	) tmp 

	--Order By Region, Area, /*ASMID,*/ SSID, SRID, Priority
)

--select Segment, Count(distinct OutletID) #Outlet
--from #Outlet_SR 
--where 1=1
--group by Segment
--order by Count(distinct OutletID)

--select distinct o.OutletTypeID, o.OutletTypeName ,SEM_SegmentID2 ,SegmentName
--from [srp].[v_TD_Account] o
--left Join [srp].[SEM-Segment] seg 
--			On o.OutletTypeID = seg.SEM_SegmentID2
--where 1 = 1
--	and o.closedate is null and o.StateName = 'Active' and o.StatusName = 'Opened' and o.IsReturnTC = 0 
--	and o.Customer_ID like '6%'
--	and o.OutletTypeID <> 2038
--	and Left(o.RegionID,1) Like '[1-9]'
--order by SEM_SegmentID2 


--select *
--from [srp].[v_TD_Account] 
--where Customer_ID = 69352571
--------------------------------

, #Thongke_Outlet_SR as
(
Select Month, Region, Area, SRID, SRID_UCE, SRName, Platinum, Gold, Silver, Bronze, Waiting_Group, 
	ISNULL(Platinum,0) + ISNULL(Gold,0) Platinum_Gold
From
(
	Select Month, Region, Area, SRID, SRID_UCE, SRName, [Platinum],[Gold],[Silver],[Bronze],[Waiting Group] Waiting_Group
	From
		(
			Select Month ,Region , Area , SRID, SRID_UCE, SRName, Tier, Count(OutletID) Number_Outlet
			From #Outlet_SR
			where Region not in ('MasterData Region') 
			Group By  Month, Area, Region, SRID, SRID_UCE, SRName, Tier
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
	--And OutletID = 64708083
	)a
Group By  --Month, 
OutletID
)



, #Outlet_SR_Silver as
(
	Select o.Month, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority, 
		v.ActualHec,
		Dense_Rank() Over (Partition by o.Month, o.SRID_UCE Order By v.ActualHec desc) STT
	From #Outlet_SR o 
		Left Join #Outlet_Volume v On o.OutletID = v.OutletID
	Where o.Tier in ('Silver')
	--And ActualHec > 0
	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
)

, #Outlet_Silver as
(
Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
	o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
	o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
from #Outlet_SR o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
Where Tier in ('Silver')
--Order By Region, Area, RCMID, ASMID, SSID, SRID

)



, #Outlet_SR_Platinum_Gold as
(
Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
	o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
	o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
from #Outlet_SR o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
Where Tier in ('Platinum','Gold')
--Order By Region, Area, RCMID, ASMID, SSID, SRID

)

, #Top_Outlet_SR_Silver as
(
	Select Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, Region ,Area, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID_UCE, ASMName, ASM_HeiwayID, SSID_UCE, SSName, SS_HeiwayID,
		SRID_UCE, SRName, SR_HeiwayID, OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
		Longitude, Latitude, Premise, Channel, Tier, LeadBrandName, Title, Email, Phone, Priority
	From #Outlet_SR_Silver o
		left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
	Where STT <= 30
	--Order By Month, Region, Area, SSID_UCE, SRID_UCE, Priority
)


, #Outlet_SR_Bronze as
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
	From #Outlet_SR o 
		Left Join #Outlet_Volume v On o.OutletID = v.OutletID
		left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
	Where o.Tier in ('Bronze')
	--And ActualHec > 0
	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
)a
Where STT <= 30
--Order By Region, Area, SSID_UCE, SRID_UCE, Priority
)

, #Outlet_Bronze as
(
Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
	o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
	o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
from #Outlet_SR o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
Where Tier in ('Bronze')
--Order By Region, Area, RCMID, ASMID, SSID, SRID

)

, #Full_Outlet_SR as
(
Select o.Month, REPLACE(REPLACE(BusinessUnitID, '[', ''), ']', '') BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
	o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
	o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
from #Outlet_SR o
	left join [srp].[v_TD_Region_Area] r on o.Area = r.AreaID
--Where Tier in ('Platinum','Gold','Silver','Bronze')
)


--1. Thống kê SR--

/*

Select *
From #Thongke_Outlet_SR
--where Region = 'Modern On Trade'
--	and SRID = 16214
Order By Region

*/


--2. Xuất danh sách Outlet Platinum Gold

--insert into [srp].[OutletList_SentTo_Spiral] 

--select *
--from #Outlet_SR_Platinum_Gold-- Done


--3. Xuất thêm top 10 Outlet Silver để backup

--select *
--from #Top_Outlet_SR_Silver  -- Done

--select *
--from #Outlet_Silver


--4. Xuất thêm top 20 Outlet Bronze để backup

--select *
--from #Outlet_SR_Bronze --Done
--where SRID_UCE in (80704754)


--select *
--from #Outlet_Bronze --Done


--5. Xuất full outlet coverage (Outlet focus segment)

select 
	 Month
	,BU
	,Region,Area,RCMID_UCE,RCMName,RCM_HeiwayID,ASMID_UCE,ASMName,ASM_HeiwayID,SSID_UCE,SSName,SS_HeiwayID
	,SRID_UCE,SRName,SR_HeiwayID
	,OutletID,OutletName,Segment,AddLine,WardName,DistrictName,ProvinceName,DemographicID,Longitude,Latitude
	,Premise,Channel,Tier,LeadBrandName,Title,Email,Phone,[Priority]
from #Full_Outlet_SR
where 1=1
order by SRID_UCE, Area, Region, BU



		/*Tie Up - OSR Systems*/

/*

	SELECT OutletID, StartingDate, CompleteDate , CurrentStatusID
		,case 
			when CurrentStatusID ='-1' then 'Draft'
			when CurrentStatusID ='1' then 'Pending SS Approval'
			when CurrentStatusID ='2' then 'Pending SE Approval'
			when CurrentStatusID ='3' then 'Pending'
			when CurrentStatusID ='4' then 'Approved'
			when CurrentStatusID ='5' then 'Waiting for Approval'
			when CurrentStatusID ='6' then 'Pending CD Approval'
			when CurrentStatusID ='7' then 'Pending GD Approval'
			when CurrentStatusID ='10' then 'Completed'
			when CurrentStatusID ='31' then 'Pending ASM Approval'
			when CurrentStatusID ='99' then 'Cancel'
			when CurrentStatusID ='100' then 'Terminal' else 'Other' end [Status]
	FROM [srp].[v_OSR_Contract]
	WHERE 1=1
		AND GETDATE() BETWEEN StartingDate AND CompleteDate
		----and DATEFROMPARTS(YEAR(CompleteDate), MONTH(CompleteDate), 1) = '2026-03-01'
		AND LiquidationDate IS NULL
		--AND CurrentStatusID = 10
		--and OutletID = 66450915
	order by CompleteDate

*/