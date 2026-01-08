--Query to update PD quantitty in screen 0094:

BEGIN TRANSACTION;
DECLARE @ProdHeaderDossierCode NVARCHAR(4000) = N'{ProdHeaderDossierCode}' -- PD to update
DECLARE @QuantityNew NVARCHAR(10) = {QuantityNew} --New Quantity
DECLARE @HeadProductionDossiercode NVARCHAR(4000);
DECLARE @PBLineNr NVARCHAR(10);
DECLARE @Description NVARCHAR(30);

 WITH ReferenceData AS (SELECT
  d.OrdNr,
  bm.ProdHeaderDossierCode [HeadPD_ProdHeaderDossierCode], 
  PHPBL.ProdHeaderDossierCode,
  tbm.ProdStatusCode,
  bm.ProdBOMLineNr,
  bm.Description,
	FORMAT(tbm.Qty, 'N2', 'nl-NL') AS Qty_Old
  FROM [T_prodbillofmat] bm
  LEFT JOIN T_ProdHeadProdBOMLink PHPBL on (bm.prodBomLineNr = PHPBL.ProdBomLineNr AND bm.prodheaderdossiercode = PHPBL.ProdBOMprodheaderdossiercode)
  LEFT JOIN [T_ProductionHeader] tbm on tbm.prodheaderdossiercode = PHPBL.prodheaderdossiercode
  INNER JOIN T_DossierMain d on tbm.DossierCode = d.DossierCode
  WHERE bm.ProdHeaderDossierCode = (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = @ProdHeaderDossierCode)
  AND PHPBL.ProdHeaderDossierCode = @ProdHeaderDossierCode)


SELECT TOP 1 
    @HeadProductionDossiercode = HeadPD_ProdHeaderDossierCode,
    @PBLineNr = ProdBOMLineNr,
    @Description = Description
FROM ReferenceData;

--DECLARE @HeadProductionDossiercode NVARCHAR(4000) = N'0000209958' -- Head_PD to update
--DECLARE @PBLineNr NVARCHAR(10) = 7 -- current ProdBomLineNr
--DECLARE @Description NVARCHAR(30) = 'Description' --current Description

DECLARE @old_LastUpdatedOn NVARCHAR(30)
DECLARE @LastUpdatedOn NVARCHAR(30) = CONVERT(NVARCHAR(30), GETDATE(), 120) -- Format: YYYY-MM-DD HH:MI:SS
DECLARE @ResultCode INT = 0
DECLARE @ResultMessage NVARCHAR(255)
DECLARE @p54 NVARCHAR(30) = CONVERT(NVARCHAR(30), GETDATE(), 120)  -- ISO 8601


-- Retrieve the latest LastUpdatedOn from the database
SELECT @old_LastUpdatedOn = LastUpdatedOn
FROM T_ProdBillOfMat
WHERE ProdHeaderDossierCode = @HeadProductionDossiercode and ProdBOMLineNr = @PBLineNr

-- Ensure @old_LastUpdatedOn is not NULL (optional, remove if LastUpdatedOn is always set)
IF @old_LastUpdatedOn IS NULL
    SET @old_LastUpdatedOn = '2000-01-01 00:00:00.000'

-- Try updating the production header
BEGIN TRY
SET NOCOUNT ON;
DECLARE @tmp036 TABLE (
    Result int NULL,
    Parameter1Str nvarchar(4000) NULL,
    Parameter2Str nvarchar(4000) NULL,
    Parameter3Str nvarchar(4000) NULL
);

INSERT INTO @tmp036 (Result, Parameter1Str, Parameter2Str, Parameter3Str)
	EXEC SIP_036_Upd_ProdQtyFromPBOM  @IsahUserCode  = 'RPA',@ScriptCode    = 'RS036' ,@ProdHeaderDossierCode = @HeadProductionDossiercode ,--HeadPD of PD to change
		@ProdBomLineNr         = @PBLineNr, --ProdBomLineNr
		@CalcQty               = @QuantityNew, --New Quantity
		@Description           = @Description --Description of PD row

	declare @p64 smallint
	set @p64=0
	EXEC [dbo].[IP_Upd_ProdBOM] 
		@HeadProductionDossiercode,
		@PBLineNr, --ProdBomLineNr
		NULL,NULL,NULL,NULL,NULL,
		@old_LastUpdatedOn,  -- Use the latest value retrieved from DB
		NULL,NULL,NULL,NULL,NULL,NULL,1,
		@QuantityNew, --New Quantity
		@QuantityNew, --New Quantity
		@QuantityNew, --New Quantity
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		@p54 output,
		N'RPA',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
		@p64 output,
		NULL,NULL,NULL,NULL,NULL,940000,NULL,0,0,0,NULL,NULL,NULL,NULL
		
	EXEC dbo.SIP_upd_MaterialsList
		@ProdHeaderDossierCode = @HeadProductionDossiercode, --HeadPD of PD to change
		@ProdBOMLineNr = @PBLineNr, --ProdBomLineNr
		@Qty = @QuantityNew,	--New Quantity
		@NetQty = @QuantityNew, --New Quantity
		@SpecialPartInd = 1,  -- must be 1
		@IsahUserCode = N'RPA';


    -- If no error occurs, update success qty
    SET @ResultCode = 1
    SET @ResultMessage = 'quantity ProductionDossiercode '+ @ProdHeaderDossierCode + ' successfully updated to ' + @QuantityNew + ' in screen 0094'
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