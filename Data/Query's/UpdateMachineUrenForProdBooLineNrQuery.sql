BEGIN TRANSACTION;

-- Invoervariabelen
DECLARE @ProdHeaderDossierCode NVARCHAR(50) = N'{ProdHeaderDossierCode}';
DECLARE @ProdBOOLineNr INT = {ProdBOOLineNr};
DECLARE @MachineUrenNewInSec INT = {MachineUrenNewInSec};

-- Variabelen
DECLARE @LastUpdatedTime NVARCHAR(50);
DECLARE @ResultCode INT = 0;
DECLARE @ResultMessage NVARCHAR(255);

-- Ophalen huidige LastUpdatedTime uit de database
SELECT @LastUpdatedTime = LastUpdatedOn
FROM dbo.T_ProdBillOfOper
WHERE ProdHeaderDossierCode = @ProdHeaderDossierCode
  AND ProdBOOLineNr = @ProdBOOLineNr;

-- Check of gevonden
IF @LastUpdatedTime IS NULL
BEGIN
    SET @ResultCode = 0;
    SET @ResultMessage = 'LastUpdatedOn niet gevonden.';
    ROLLBACK TRANSACTION;
    SELECT @ResultCode AS ResultCode, @ResultMessage AS Message;
    RETURN;
END

-- Try update uitvoeren
BEGIN TRY
    EXEC [dbo].[IP_Upd_ProdBOO] 
        @old_ProdHeaderDossierCode = @ProdHeaderDossierCode,
        @old_ProdBOOLineNr = @ProdBOOLineNr,
        @old_LastUpdatedOn = @LastUpdatedTime,
        @ProdHeaderDossierCode = @ProdHeaderDossierCode,
        @ProdBOOLineNr = @ProdBOOLineNr,
        @ScriptListCode = NULL,
        @MachGrpCode = NULL,
        @MachCode = NULL,
        @PlanGrpCode = NULL,
        @ProdBOOStatusCode = NULL,
        @LineNr = NULL,
        @ProdBOOPartDescription = NULL,
        @UnitDescription = NULL,
        @Qty = NULL,
        @MachCycleTime = @MachineUrenNewInSec,
        @MachCycleTimeDefInd = NULL,
        @MachSetupTime = NULL,
        @MachSetoffTime = NULL,
        @OccupationSetupTime = NULL,
        @OccupationSetoffTime = NULL,
        @OccupationCycleTime = NULL,
        @StartDate = NULL,
        @StartTime = NULL,
        @EndDate = NULL,
        @LeadTime = NULL,
        @PriorityId = NULL,
        @ProdStartedInd = NULL,
        @StandCapacity = NULL,
        @StandCapacityType = NULL,
        @ProdBOMPhantomLineNr = NULL,
        @FinishedInd = NULL,
        @FinishedDate = NULL,
        @ProducedQty = NULL,
        @InfoType = NULL,
        @Info = NULL,
        @IsahUserCode = N'RPA',
        @LogProgramCode = 950000,
        @SchedulingFactor = NULL,
        @PlanningBasedOnType = NULL,
        @PlanningType = NULL,
        @PlanningInOneTimeSlotInd = NULL,
        @PlanningConstraintType = NULL,
        @PlanningConstraintDate = NULL,
        @StandLeadTime = NULL,
        @MachPlanTime = @MachineUrenNewInSec,
        @OccupationPlanTime = 0,  -- Manuren op 0 zetten
        @ProgressPercentage = NULL,
        @StartDateActual = NULL,
        @EndDateActual = NULL,
        @PlanSetting = NULL,
        @EmpId = NULL,
        @UpdateRelatedDatesInd = 1,
        @MemoGrpId = NULL,
        @Tag = NULL,
        @New_MachCycleTime = @MachineUrenNewInSec,
        @New_OccupationCycleTime = 0,  -- Manuren op 0 zetten
        @LastUpdatedOn = NULL;

    SET @ResultCode = 1;
    SET @ResultMessage = 'Machinetijd succesvol aangepast voor PD ' + @ProdHeaderDossierCode + ', regel ' + CAST(@ProdBOOLineNr AS NVARCHAR);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    SET @ResultCode = 0;
    SET @ResultMessage = ERROR_MESSAGE();
    ROLLBACK TRANSACTION;
END CATCH

SELECT @ResultCode AS ResultCode, @ResultMessage AS Message;
