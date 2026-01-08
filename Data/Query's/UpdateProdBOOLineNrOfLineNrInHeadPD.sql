BEGIN TRANSACTION;
DECLARE @ProductionDossiercode NVARCHAR(4000) = N'{ProductionDossiercode}' -- PD to update
DECLARE @HeadProductionDossiercode NVARCHAR(4000);
DECLARE @LineNrPD NVARCHAR(10); --New LineNr
DECLARE @NewLineNr NVARCHAR(10) = '{NewLineNr}' --New LineNr
DECLARE @NewProdBooLineNr NVARCHAR(10); --New ProdBooLineNr for update SP
DECLARE @ProdBOOLineNrPD NVARCHAR(10);
DECLARE @ProdBOMLineNrPD NVARCHAR(10);
DECLARE @Description NVARCHAR(30);

 WITH ReferenceData AS (
 SELECT
  d.OrdNr,
  bm.ProdHeaderDossierCode [HeadPD_ProdHeaderDossierCode], 
  PHPBL.ProdHeaderDossierCode,
  tbm.ProdStatusCode,
  bm.ProdBOMLineNr,
  bm.LineNr,
  bm.Description,
	FORMAT(tbm.Qty, 'N2', 'nl-NL') AS Qty_Old
  FROM [T_prodbillofmat] bm
  LEFT JOIN T_ProdHeadProdBOMLink PHPBL on (bm.prodBomLineNr = PHPBL.ProdBomLineNr AND bm.prodheaderdossiercode = PHPBL.ProdBOMprodheaderdossiercode)
  LEFT JOIN [T_ProductionHeader] tbm on tbm.prodheaderdossiercode = PHPBL.prodheaderdossiercode
  INNER JOIN T_DossierMain d on tbm.DossierCode = d.DossierCode
  WHERE bm.ProdHeaderDossierCode = (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = @ProductionDossiercode)
  AND PHPBL.ProdHeaderDossierCode = @ProductionDossiercode)


SELECT TOP 1 
    @HeadProductionDossiercode = HeadPD_ProdHeaderDossierCode,
    @ProdBOOLineNrPD = ProdBOMLineNr,
	@ProdBOMLineNrPD = ProdBOMLineNr,
	@LineNrPD = Linenr,
    @Description = Description
FROM ReferenceData;

  SELECT @NewProdBooLineNr = ProdBOOLineNr
FROM dbo.T_ProdBillOfOper
WHERE ProdHeaderDossierCode = @HeadProductionDossiercode
  AND LineNr = @NewLineNr


DECLARE @old_LastUpdatedOn NVARCHAR(30)
DECLARE @LastUpdatedOn NVARCHAR(30) = CONVERT(NVARCHAR(30), GETDATE(), 120) -- Format: YYYY-MM-DD HH:MI:SS
DECLARE @ResultCode INT = 0
DECLARE @ResultMessage NVARCHAR(255)
DECLARE @p54 NVARCHAR(30) = CONVERT(NVARCHAR(30), GETDATE(), 120)  -- ISO 8601


-- Retrieve the latest LastUpdatedOn from the database
SELECT @old_LastUpdatedOn = LastUpdatedOn
FROM T_ProdBillOfMat
WHERE ProdHeaderDossierCode = @HeadProductionDossiercode and ProdBOMLineNr = @ProdBOOLineNrPD

-- Ensure @old_LastUpdatedOn is not NULL (optional, remove if LastUpdatedOn is always set)
IF @old_LastUpdatedOn IS NULL
    SET @old_LastUpdatedOn = '2000-01-01 00:00:00.000'

-- Try updating the production header
BEGIN TRY


	declare @p64 smallint
	set @p64=0

	EXEC [dbo].[IP_Upd_ProdBOM] 
		@HeadProductionDossiercode,
		@ProdBOOLineNrPD, --ProdBomLineNr
		NULL,NULL,NULL,NULL,NULL,
		@old_LastUpdatedOn,  -- Use the latest value retrieved from DB
		NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		@NewProdBooLineNr, --New ProdBooLineNr
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		@p54 output,
		N'RPA',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		@p64 output,
		NULL,NULL,NULL,NULL,NULL,940000,NULL,0,0,0,NULL,NULL,NULL,NULL

		
	EXEC dbo.SIP_upd_MaterialsList
		@ProdHeaderDossierCode = @HeadProductionDossiercode, --HeadPD of PD to change
		@ProdBOMLineNr = @ProdBOMLineNrPD, --ProdBomLineNr
		@SpecialPartInd = 0,
		@IsahUserCode = N'RPA';


    -- If no error occurs, update success qty
    SET @ResultCode = 1
    SET @ResultMessage = 'BillOfOperLineNr of LineNr '+ @LineNrPD + ' (ProductionDossiercode '+ @ProductionDossiercode + ') under Head PD '+ @HeadProductionDossiercode +' successfully updated to ' + @NewLineNr + ' in screen 0094'
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
    -- If an error occurs, set failure status and capture error message
    SET @ResultCode = 0
    SET @ResultMessage = ERROR_MESSAGE()
	ROLLBACK TRANSACTION
END CATCH

-- Return the result code and message
SELECT @ResultCode AS ResultCode, @ResultMessage AS Message