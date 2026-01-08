BEGIN TRANSACTION;

-- Invoervariabelen
DECLARE @ProdHeaderDossierCode NVARCHAR(50) = N'{ProdHeaderDossierCode}';
DECLARE @DayBeforeEngLineStartDateHeadPD NVARCHAR(50);

--Retrieve @DayBeforeEngLineStartDateHeadPD
SELECT top 1
	--bm.ProdHeaderDossierCode [HeadPD],
	--PHPBL.ProdHeaderDossierCode,
	--CAST(PHPBL.Qty as int) Qty,
	--bm.Description,
	@DayBeforeEngLineStartDateHeadPD = (SELECT CONVERT(VARCHAR(10), DATEADD(DAY, -1, bo.startdate), 120) + ' 00:00:00' AS startdate_ENG_Line_Minus_1_Day
	 FROM [T_ProdBillOfOper] bo 
	 WHERE bo.ProdHeaderDossierCode = bm.ProdHeaderDossierCode 
	 AND bo.MachGrpCode LIKE '%ENG%')
  FROM [T_prodbillofmat] bm
	LEFT JOIN  [T_ProdHeadProdBOMLink] PHPBL on (bm.prodBomLineNr = PHPBL.ProdBomLineNr AND bm.prodheaderdossiercode = PHPBL.ProdBOMprodheaderdossiercode)
  WHERE 1=1
  AND PHPBL.ProdHeaderDossierCode = @ProdHeaderDossierCode;

DECLARE @ResultCode INT = 0;
DECLARE @ResultMessage NVARCHAR(255);


-- Try update uitvoeren
BEGIN TRY

exec [IP_prc_PlanProdHeader] @ProdHeaderDossierCode,NULL,NULL,NULL,NULL,2,NULL,@DayBeforeEngLineStartDateHeadPD,0,1,0,1,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,9999,0,N'',0,N'',0,0,N'',0,0,N'',0,0,N'',0,N'RPA',1480000

    SET @ResultCode = 1;
    SET @ResultMessage = 'Doorlooptijdenplanning van PD ' + CAST(@ProdHeaderDossierCode AS NVARCHAR) + ' succesvol uitgevoerd.' ;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    SET @ResultCode = 0;
    SET @ResultMessage = ERROR_MESSAGE();
    ROLLBACK TRANSACTION;
END CATCH

SELECT @ResultCode AS ResultCode, @ResultMessage AS Message;

