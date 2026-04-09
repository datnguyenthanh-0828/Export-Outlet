------------MONT------------------
-------------OR-----------------

Declare @CurrentDate Date = GetDate()
Declare @Month Date
Declare @PreMonth Date
Declare @Top int

Set @Month = '2026-03-01'
Set @Top = 40


--Set @PreMonth = '2026-01-01'

--DATEADD(MM, DATEDIFF(MM, 0, DateAdd(MM, -1, @CurrentDate)), 0);

--Select @PreMonth;
;


--SR
--/*
With #Outlet_SR as
(

Select Cast(tmp.Month as Date) Month, Region = case when Area = 'MO6' then 'MONT Central_North' when Area = 'MO8' then 'MONT South' else Region end
	,Area, 
    RCMID, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID, ASMID_UCE, ASMName, ASM_HeiwayID,
    SSID, SSID_UCE, SSName, SS_HeiwayID, SRID, SRID_UCE, SRName, SR_HeiwayID,
    OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
    Longitude, Latitude, Premise, Channel,
    Tier, LeadBrandName, Title, Email, Cast(Phone as varchar(max)) Phone,
    'Priority' = Case 
		When Tier in ('Platinum','Gold','Hot') Then 'Option 1'
        When Tier in ('Silver','Medium') Then 'Option 2'
        When Tier in ('Bronze','Low') Then 'Option 3'
			Else 'Option 4'
    End
	,'Tier_Priority' = Case
		When Tier in ('Platinum','Gold') Then 1
        When Tier in ('Silver') Then 2
        When Tier in ('Bronze') Then 3
        When Tier in ('Hot') Then 4
        When Tier in ('Medium') Then 5
			Else 6
	End
	,'Segment_Priority' = Case 
		When Segment in ('Karaoke','Premium Karaoke') Then 1
		When Segment in ('Young Social') Then 2
		When Segment in ('Bar/Pub','Bar') Then 3
		When Segment in ('Night Club') Then 4
			Else 99
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
			and seg.SegmentName in ('Young Social','Premium Karaoke','Karaoke','Bar/Pub','Bar','Night Club')
		and o.AreaID like '%MO%'
		--Remove Outlet KTC liên tục--
		--and o.Customer_ID not in (63215956,63216537,63217398,63221681,63221685,63230753,63215261,63216200,63216538,63217643,63221519,63221520,63221608,63221651,63221684,63221722,63222162,63222210,63227722,63230141,63230147,63230536,63230615,63230621,63230908,63231032,63236120)
		and o.Tier not in ('Waiting Group')

	) tmp 
	--Order By Region, Area, /*ASMID,*/ SSID, SRID, Priority
)

--select *--Tier, Segment, Count(distinct OutletID) #Outlet
--from #Outlet_SR 
--where 1=1
--and Segment = 'Young Social'
--group by Tier, Segment
--order by Count(distinct OutletID)

--select *
--from [srp].[v_TD_Account]
--		where 1 = 1
--		and closedate is null and StateName = 'Active' and StatusName = 'Opened' and IsReturnTC = 0 
--		and Customer_ID like '6%'
--		and OutletTypeID <> 2038
--		and Left(RegionID,1) Like '[1-9]'
--		and Customer_ID in (63106595,66106944,66111695,66112389,66108968,66111621,66152976,63223672,63237668)

--------------------------------

--, #Thongke_Outlet_SR as
--(
--Select Month, Region, Area, SRID, SRID_UCE, SRName, Platinum, Gold, Silver, Bronze, Waiting_Group, 
--	ISNULL(Platinum,0) + ISNULL(Gold,0) Platinum_Gold
--From
--(
--	Select Month, Region, Area, SRID, SRID_UCE, SRName, [Platinum],[Gold],[Silver],[Bronze],[Waiting Group] Waiting_Group
--	From
--		(
--			Select Month ,Region , Area , SRID, SRID_UCE, SRName, Tier, Count(OutletID) Number_Outlet
--			From #Outlet_SR
--			where Region not in ('MasterData Region') 
--			Group By  Month, Area, Region, SRID, SRID_UCE, SRName, Tier
--		)a
--	Pivot
--	(
--		Sum(Number_Outlet)
--		For Tier In ([Platinum],[Gold],[Silver],[Bronze],[Waiting Group])
--	)as bangchuyen
----Order By Region
--)b
----Order By Region
--)


--, #Outlet_Volume as
--(
--	Select Month, OutletID, Sum(Quantity) Quantity, Sum(ActualHec) ActualHec
--	From
--		(
--			Select Convert(Date, Str(Concat(Left(Cast(PostingDate as varchar),4), SUBSTRING(Cast(PostingDate as varchar),6,2))*100+1)) Month, 
--				 OutletID, Quantity, Volume, Quantity * Volume as ActualHec
--			From [srp].[v_TF_SalesOut_ByMonth]
--			Where 1 = 1
--			And Convert(Date, Str(Concat(Left(Cast(PostingDate as varchar),4), SUBSTRING(Cast(PostingDate as varchar),6,2))*100+1)) = @PreMonth
--			--And OutletCode = 64708083
--		)a
--	Group By  Month, OutletID
--)



--, #Outlet_SR_Silver as
--(
--	Select o.Month, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
--		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
--		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority, 
--		v.ActualHec,
--		Dense_Rank() Over (Partition by o.Month, o.SRID_UCE Order By v.ActualHec desc) STT
--	From #Outlet_SR o Left Join #Outlet_Volume v
--		On o.OutletID = v.OutletID
--	Where o.Tier in ('Silver')
--	--And ActualHec > 0
--	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
--)

--, #Outlet_Silver as
--(
--	Select o.Month, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
--		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
--		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
--	From #Outlet_SR o 
--	Where o.Tier in ('Silver')
--	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
--)

--, #Outlet_SR_Platinum_Gold as
--(

--Select o.Month, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
--	o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
--	o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
--from #Outlet_SR o
--Where Tier in ('Platinum','Gold')
----Order By Region, Area, RCMID, ASMID, SSID, SRID

--)


--,#Top_Outlet_SR_Silver as
--(
--Select Month, Region, Area, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID_UCE, ASMName, ASM_HeiwayID, SSID_UCE, SSName, SS_HeiwayID,
--	SRID_UCE, SRName, SR_HeiwayID, OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
--	Longitude, Latitude, Premise, Channel, Tier, LeadBrandName, Title, Email, Phone, Priority
--From
--(
--	Select o.Month, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
--			o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
--			o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority, 
--			v.ActualHec,
--			Dense_Rank() Over (Partition by o.Month, o.SRID_UCE Order By v.ActualHec desc) STT
--			--Dense_Rank() Over (Partition by o.Month, o.SRID_UCE Order By o.Tier desc) STT
--	From #Outlet_SR o 
--	Left Join #Outlet_Volume v On o.OutletID = v.OutletID
--	Where o.Tier in ('Silver')
--	--And ActualHec > 0
--	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
--)a
--Where STT <= 20
----Order By Region, Area, SSID_UCE, SRID_UCE, Priority
--)


--, #Outlet_SR_Bronze as
--(
--Select Month, Region, Area, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID_UCE, ASMName, ASM_HeiwayID, SSID_UCE, SSName, SS_HeiwayID,
--	SRID_UCE, SRName, SR_HeiwayID, OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
--	Longitude, Latitude, Premise, Channel, Tier, LeadBrandName, Title, Email, Phone, Priority
--From
--(
--	Select o.Month, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
--			o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
--			o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority, 
--			v.ActualHec,
--			Dense_Rank() Over (Partition by o.Month, o.SRID_UCE Order By v.ActualHec desc) STT
--	From #Outlet_SR o Left Join #Outlet_Volume v
--			On o.OutletID = v.OutletID
--	Where o.Tier in ('Bronze')
--	And ActualHec > 0
--	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
--)a
--Where STT <= 30
----Order By Region, Area, SSID_UCE, SRID_UCE, Priority
--)

--, #Outlet_Bronze as
--(
--	Select o.Month, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
--		o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
--		o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority
--	From #Outlet_SR o 
--	Where o.Tier in ('Bronze')
--	--Order By o.Region, o.Area, o.ASMID, o.SSID, o.SRID, o.Priority
--)

---- Sử dụng Sub Query All để lấy toàn bộ outlet và ranking outlet top Tier ---
, #Outlet_SR_All as
(

Select o.Month,'MODERN ON TRADE' BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
	o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
	o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority, o.Tier_Priority ,o.Segment_Priority
	,ROW_NUMBER() OVER (PARTITION BY Month, o.SRID_UCE ORDER BY o.Segment_Priority asc, o.Tier_Priority, o.OutletID) AS STT
from #Outlet_SR o
Where 1=1
--and Tier in ('Platinum','Gold','Silver','Bronze')
--Order By Region, Area, RCMID, ASMID, SSID, SRID

)

--1. Thống kê SR

/*

Select *
From #Thongke_Outlet_SR
--where Region = 'Modern On Trade'
--	and SRID = 16214
Order By Region

*/


--2. Xuất danh sách Outlet Platinum Gold

--select *
--from #Outlet_SR_Platinum_Gold


--3. Xuất thêm top 20 Outlet Silver để backup

--select *
--from #Top_Outlet_SR_Silver

--select *
--from #Outlet_Silver


--4. Xuất thêm top 20 Outlet Bronze để backup

--select *
--from #Outlet_SR_Bronze 

--select *
--from #Outlet_Bronze

--5. Xuất full outlet coverage (Outlet focus segment)

select
	 Month
	,BU,Region,Area,RCMID_UCE,RCMName,RCM_HeiwayID,ASMID_UCE,ASMName,ASM_HeiwayID,SSID_UCE,SSName,SS_HeiwayID
	,SRID_UCE,SRName,SR_HeiwayID
	,OutletID,OutletName,Segment,AddLine,WardName,DistrictName,ProvinceName,DemographicID,Longitude,Latitude
	,Premise,Channel,Tier,LeadBrandName,Title,Email,Phone,Priority
	,Segment_Priority
	,Tier_Priority
	,STT
from #Outlet_SR_All
where 1=1
/*Min Outlet per Sales MONT*/
	and STT <= @Top
	--and SRID_UCE = 80706625
order by SRID_UCE
