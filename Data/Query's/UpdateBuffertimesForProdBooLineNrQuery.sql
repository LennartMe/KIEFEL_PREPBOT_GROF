BEGIN TRANSACTION;

-- Invoervariabelen
DECLARE @ProdHeaderDossierCode NVARCHAR(50) = N'{ProdHeaderDossierCode}';
DECLARE @ProdBOOLineNr INT = {ProdBOOLineNr};
DECLARE @ProdRoutingLineNr INT = {ProdRoutingLineNr};

-- Variabelen
DECLARE @ResultCode INT = 0;
DECLARE @ResultMessage NVARCHAR(255);

-- Try update uitvoeren
BEGIN TRY
Exec RS072_Set_PlanOper  
@IsahUserCode  = 'RPA' , 
@ScriptCode  = 'RS072'  ,
@ProdHeaderDossierCode = @ProdHeaderDossierCode  ,
@ProdBoolineNr         = @ProdBOOLineNr  ,
@DaysBuff	         = 2  ,
@ProdRoutingLineNr	 = @ProdRoutingLineNr


    SET @ResultCode = 1;
    SET @ResultMessage = 'Buffertijden succesvol op 2 gezet voor PD ' + @ProdHeaderDossierCode + ', regel ' + CAST(@ProdBOOLineNr AS NVARCHAR);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    SET @ResultCode = 0;
    SET @ResultMessage = ERROR_MESSAGE();
    ROLLBACK TRANSACTION;
END CATCH

SELECT @ResultCode AS ResultCode, @ResultMessage AS Message;
