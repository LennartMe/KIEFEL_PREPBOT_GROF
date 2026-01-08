-- Inputparameters
DECLARE @ProdHeaderDossierCode NVARCHAR(50) = N'{ProdHeaderDossierCode}';  -- PD

SELECT * FROM (SELECT 
    ProdHeaderDossierCode,
	ProdBOOLineNr,
	LineNr,
    MachGrpCode,
	CASE WHEN MachCode = '     ' THEN '' ELSE Machcode END AS MachcodeOld,
	'' AS MachcodeNew,
    FORMAT(CAST(((MachCycleTime / 3600)*3600) as INT), 'G', 'nl-NL') as [MachineUrenOld],
	CASE 
        WHEN MachGrpCode IN ('GL','HA','VER','RSL','BEH') 
			THEN FORMAT(CAST(('0') as INT), 'G', 'nl-NL') --GL,HA,VER,RSL and BEH should always be 0,00
        WHEN PlanningBasedOnType = 2 
			THEN FORMAT(CAST(('0') as INT), 'G', 'nl-NL') --If Type is ManHours return 0,00 as new value for MachineHours
        WHEN (MachCycleTime = 0 OR MachCycleTime IS NULL) AND OccupationCycleTime > 0 AND FORMAT(CAST(((ROUND((OccupationCycleTime / 3600) * 4,0) / 4.0)*3600) as INT), 'G', 'nl-NL') = '0,00'
			THEN '360'  --If MachineHours is empty, but ManHours is filled in and above 0, but rounded ManHours is 0, then return 0,10 
		WHEN (MachCycleTime = 0 OR MachCycleTime IS NULL) AND OccupationCycleTime > 0 
			THEN FORMAT(CAST(((ROUND((OccupationCycleTime / 3600) * 4,0) / 4.0)*3600) as INT), 'G', 'nl-NL')  --If MachineHours is empty, but ManHours is filled in, copy and round ManHours as new value for MachineHours
        WHEN FORMAT(CAST(((ROUND((MachCycleTime / 3600) * 4,0) / 4.0)*3600) as INT), 'G', 'nl-NL') = '0'
             AND MachCycleTime > 0 
			THEN '360' --If MachineHours is above 0, but rounded it returns as 0,00 then return 0,10
        WHEN MachCycleTime = 0  
			THEN FORMAT(CAST((('0')*3600) as INT), 'G', 'nl-NL') --If MachineHours is 0, return as 0,00 
        ELSE FORMAT(CAST(((ROUND((MachCycleTime / 3600) * 4,0) / 4.0)*3600) as INT), 'G', 'nl-NL')
    END as [MachineUrenNew],
	    (SELECT FORMAT(CAST(((AVG(MachCycleTime) / 3600)*3600) as INT), 'G', 'nl-NL') 
     FROM [T_ProdBillOfOper] s1
     WHERE s1.MachGrpCode = m.MachGrpCode 
       AND s1.ProdBOOLineNr = m.ProdBOOLineNr 
       AND s1.Qty = m.Qty 
       AND s1.PlanningBasedOnType = m.PlanningBasedOnType 
       AND StartDate > GETDATE() -365) as [AVG_MachineUren],
    FORMAT(CAST(((OccupationCycleTime / 3600)*3600) as INT), 'G', 'nl-NL') as [ManUrenOld],
	CASE 
        WHEN MachGrpCode IN ('GL','HA','VER','RSL','BEH') 
			THEN FORMAT(CAST(('0') as INT), 'G', 'nl-NL') --GL,HA,VER,RSL and BEH should always be 0,00
        WHEN PlanningBasedOnType = 1 
			THEN FORMAT(CAST(('0') as INT), 'G', 'nl-NL') --If Type is MachineHours return 0,00 as new value for ManHours
        WHEN (OccupationCycleTime = 0 OR OccupationCycleTime IS NULL) AND MachCycleTime > 0 AND FORMAT(CAST(((ROUND((MachCycleTime / 3600) * 4,0) / 4.0)*3600) as INT), 'G', 'nl-NL') = '0,00'
			THEN '360'  --If ManHours is empty, but MachineHours is filled in and above 0, but rounded MachineHours is 0, then return 0,10 
		WHEN (OccupationCycleTime = 0 OR OccupationCycleTime IS NULL) AND MachCycleTime > 0 
			THEN FORMAT(CAST(((ROUND((MachCycleTime / 3600) * 4,0) / 4.0)*3600) as INT), 'G', 'nl-NL')  --If ManHours is empty, but MachineHours is filled in, copy and round MachineHours as new value for ManHours
        WHEN FORMAT(CAST(((ROUND((OccupationCycleTime / 3600) * 4,0) / 4.0)*3600) as INT), 'G', 'nl-NL') = '0'
             AND OccupationCycleTime > 0 
			THEN '360' --If ManHours is above 0, but rounded it returns as 0,00 then return 0,10
        WHEN OccupationCycleTime = 0  
			THEN FORMAT(CAST((('0')*3600) as INT), 'G', 'nl-NL') --If ManHours is 0, return as 0,00 
        ELSE FORMAT(CAST(((ROUND((OccupationCycleTime / 3600) * 4,0) / 4.0)*3600) as INT), 'G', 'nl-NL')
    END as [ManUrenNew],
    (SELECT FORMAT(CAST(((AVG(OccupationCycleTime) / 3600)*3600) as INT), 'G', 'nl-NL') 
     FROM [T_ProdBillOfOper] s2
     WHERE s2.MachGrpCode = m.MachGrpCode 
       AND s2.ProdBOOLineNr = m.ProdBOOLineNr 
       AND s2.Qty = m.Qty 
       AND s2.PlanningBasedOnType = m.PlanningBasedOnType 
       AND StartDate > GETDATE() -365) as [AVG_ManUren],

    PlanningBasedOnType,
    CASE 
        WHEN PlanningBasedOnType = 2 THEN 'ManUren' 
        WHEN PlanningBasedOnType = 1 THEN 'MachineUren' 
        ELSE '' 
    END AS SoortUren
    
FROM [T_ProdBillOfOper] m

Where ProdHeaderDossierCode IN (@ProdHeaderDossierCode)
) a
WHERE MachcodeOLD <> MachcodeNew OR MachineUrenOld <> MachineUrenNew OR ManUrenOld <> ManUrenNew
order by LineNr