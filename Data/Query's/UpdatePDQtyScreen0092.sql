--update for screen 0092

BEGIN TRANSACTION;
DECLARE @ProdHeaderDossierCode NVARCHAR(30) = N'{ProdHeaderDossierCode}'
DECLARE @QuantityNew NVARCHAR(10) = {QuantityNew} --New Quantity
DECLARE @PropagateQty NVARCHAR(10) = {PropagateQty} --Doorrekenen

DECLARE @old_LastUpdatedOn NVARCHAR(30)
DECLARE @LastUpdatedOn NVARCHAR(30) = CONVERT(NVARCHAR(30), GETDATE(), 120) -- Format: YYYY-MM-DD HH:MI:SS
DECLARE @ResultCode INT = 0
DECLARE @ResultMessage NVARCHAR(255)

-- Retrieve the latest LastUpdatedOn from the database
SELECT @old_LastUpdatedOn = LastUpdatedOn
FROM T_ProductionHeader
WHERE ProdHeaderDossierCode = @ProdHeaderDossierCode 

BEGIN TRY
--Update qty in screen 0092
EXEC dbo.IP_Upd_ProdHeader
      @old_ProdHeaderDossierCode = @ProdHeaderDossierCode,
      @old_LastUpdatedOn         = @old_LastUpdatedOn,
      @Qty                       = @QuantityNew,
      @IsahUserCode              = 'RPA',
      @PropagateQty              = @PropagateQty,      -- 0 = niet doorrekenen, 1 = doorrekenen
      @LogProgramCode            = 920000,
      @LastUpdatedOn             = @LastUpdatedOn OUTPUT;

    -- If no error occurs, update success qty
    SET @ResultCode = 1
IF @PropagateQty = 0
    SET @ResultMessage = 'quantity of ProductionDossiercode '+ @ProdHeaderDossierCode + ' in screen 0092 successfully updated to ' + @QuantityNew + ' without recalculating.'
IF @PropagateQty = 1
    SET @ResultMessage = 'quantity of ProductionDossiercode '+ @ProdHeaderDossierCode + ' in screen 0092 successfully updated to ' + @QuantityNew + ' with recalculating.'
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
