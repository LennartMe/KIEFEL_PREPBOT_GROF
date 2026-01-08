BEGIN TRANSACTION;

DECLARE @ProdHeaderDossierCode NVARCHAR(50) = '{ProdHeaderDossierCode}';
DECLARE @ProdBOOLineNr        INT          = {@ProdBOOLineNr};
DECLARE @ProdRoutingLineNr    INT          = {@ProdRoutingLineNr};

DECLARE @LastUpdatedOn        NVARCHAR(50);
DECLARE @ResultCode           INT;
DECLARE @ResultMessage        NVARCHAR(255) = N'';

BEGIN TRY
    -- haal de concurrency/timestamp op die de SP verwacht
    SELECT @LastUpdatedOn = LastUpdatedOn
    FROM T_ProductionRouting
    WHERE ProdHeaderDossierCode = @ProdHeaderDossierCode
      AND ProdBOOLineNr        = @ProdBOOLineNr
      AND ProdRoutingLineNr    = @ProdRoutingLineNr;

    -- als record niet bestaat: netjes afkappen
    IF @LastUpdatedOn IS NULL
    BEGIN
        SET @ResultCode = 0;
        SET @ResultMessage = N'Geen record gevonden voor deze combinatie (niets verwijderd).';
        ROLLBACK TRANSACTION;

        SELECT @ResultCode AS ResultCode, @ResultMessage AS [Message];
        RETURN;
    END;

    EXEC dbo.IP_Del_ProdRouting
        @old_ProdHeaderDossierCode = @ProdHeaderDossierCode,
        @old_ProdBOOLineNr         = @ProdBOOLineNr,
        @old_ProdRoutingLineNr     = @ProdRoutingLineNr,
        @LogProgramCode            = 980000,
        @old_LastUpdatedOn         = @LastUpdatedOn,
        @IsahUserCode              = N'RPA';

    SET @ResultCode = 1;
    SET @ResultMessage = N'Deleted ProdRoutingLineNr: ' + CAST(@ProdRoutingLineNr AS NVARCHAR(20))
                       + N' van ProdBOOLineNr: '      + CAST(@ProdBOOLineNr     AS NVARCHAR(20));

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @ResultCode = 0;
    SET @ResultMessage = ERROR_MESSAGE();
END CATCH;

SELECT @ResultCode AS ResultCode, @ResultMessage AS [Message];
