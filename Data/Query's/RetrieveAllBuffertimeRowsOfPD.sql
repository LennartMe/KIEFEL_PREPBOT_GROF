DECLARE @ProdHeaderDossierCode NVARCHAR(50) = N'{ProdHeaderDossierCode}';

SELECT PBoo1.ProdHeaderDossierCode
	           ,PBoo1.ProdbooLineNr
	           ,[ProdRoutingLineNr] = ISNULL(PR.ProdRoutingLineNr, 0)
	           ,[LineNr] = PBoo1.LineNr
	           --,[EndDate] = PBOO1.EndDate
	           --,[StartDate] = PBOO2.StartDate
	           ,[MachGrpCode] = PBOO1.MachGrpCode
	           ,[DaysBuff] = CAST(ISNULL(PR.WaitTimeAfter / (3600 * 8), 0)as int)
	           --,[OperStartDate] = PBoo1.StartDate
	           --,[OperEndDate] = PBoo1.EndDate
	    FROM   dbo.T_ProdBillofOper PBoo1
	           LEFT OUTER JOIN dbo.T_ProductionRouting PR
	                ON  PBoo1.ProdHeaderDossierCode = PR.ProdHeaderDossierCode
	                AND PBoo1.ProdBooLineNr = PR.ProdbooLineNr
	           LEFT OUTER JOIN dbo.T_ProdBillofOper PBoo2
	                ON  PR.ProdHeaderDossierCode = PBOO2.ProdHeaderDossiercode
	                AND PR.ToBooLineNr = PBOO2.ProdBooLineNr
	    WHERE  PBoo1.ProdHeaderDossierCode = @ProdHeaderDossierCode
		AND CAST(ISNULL(PR.WaitTimeAfter / (3600 * 8), 0)as int) <> 2
		AND ProdRoutingLineNr != 0
	    ORDER BY
	           PBoo1.LineNr

--Exec RS072_Get_ProdBillofOper      
--@IsahUserCode =  'RPA' ,   
--@ProdHeaderDossierCode = @ProdHeaderDossierCode ,   
--@GenRout               = 0
