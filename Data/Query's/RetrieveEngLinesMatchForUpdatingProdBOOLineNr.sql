DECLARE @ProdHeaderDossierCode varchar(255)
SET @ProdHeaderDossierCode = '{Head_ProdHeaderDossierCode}'; 

WITH ValidHeadPDCavitiesReference AS (

SELECT
	h.[ProdHeaderDossierCode],
	[ProdStatusCode],
	h.Description,
	CASE 
		WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = h.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(h.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = h.ProdHeaderDossierCode) > 0
		THEN FORMAT(TRY_CAST(LEFT(h.Description, 3) AS decimal(10,3)), 'N2', 'nl-NL') 
		WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = h.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(h.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = h.ProdHeaderDossierCode) > 0
		THEN FORMAT(TRY_CAST(LEFT(h.Description, 2) AS decimal(10,3)), 'N2', 'nl-NL')
		WHEN (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = h.ProdHeaderDossiercode) IS NULL AND FORMAT(TRY_CAST(LEFT(h.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL') IS NOT NULL AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm WHERE bm.ProdHeaderDossierCode = h.ProdHeaderDossierCode) > 0
		THEN FORMAT(TRY_CAST(LEFT(h.Description, 1) AS decimal(10,3)), 'N2', 'nl-NL')
		ELSE NULL 
	END AS [Cavities],
	(SELECT linenr 
	 FROM [T_ProdBillOfOper] bo 
	 WHERE bo.ProdHeaderDossierCode = h.ProdHeaderDossierCode 
	 AND bo.MachGrpCode LIKE '%ENG%') AS [ENG_LineNr],
	(SELECT COUNT(*) 
	 FROM [T_ProdBillOfMat] bm 
	 WHERE bm.ProdHeaderDossierCode = h.ProdHeaderDossierCode) AS [QTY_Article_Rows]
FROM 
	[T_ProductionHeader] h
	LEFT JOIN T_ProdHeadProdBOMLink PHPBL on PHPBL.Prodheaderdossiercode = h.prodheaderdossiercode 
	LEFT JOIN [T_prodbillofmat] PBOM on (PBOM.prodBomLineNr = PHPBL.ProdBomLineNr AND PBOM.prodheaderdossiercode = PHPBL.ProdBOMprodheaderdossiercode)
  WHERE DOSSIERCODE = (SELECT DISTINCT DOSSIERCODE FROM [T_ProductionHeader] WHERE prodheaderdossiercode = @ProdHeaderDossierCode) 
  AND (Select Min(ProdBOMProdHeaderDossierCode) From T_ProdHeadProdBOMLink PHPBL Where PHPBL.ProdHeaderDossierCode = h.ProdHeaderDossiercode) IS NULL -- Only Head PD's
  AND prodstatuscode = 20 AND (SELECT COUNT(*) FROM [T_ProdBillOfMat] bm LEFT JOIN [T_ProductionHeader] tbm on tbm.prodheaderdossiercode = bm.prodheaderdossiercode WHERE 1=1 
		AND tbm.ProdStatusCode = 15 --Filter for code 15 to exclude sub PD's that are already processed.
		AND bm.ProdHeaderDossierCode = h.ProdHeaderDossierCode
		) > 0 --Filter Valid Head PD's
  )


 SELECT * FROM (
 SELECT
  PHPBL.ProdHeaderDossierCode,
  bm.PartPos,
  bm.LineNr,
  SubPartCode,
	(SELECT linenr FROM [T_ProdBillOfOper] bo Where bo.ProdHeaderDossierCode = @ProdHeaderDossierCode AND bo.MachGrpCode LIKE '%ENG%') [ENG_Line_Head_PD],
	(SELECT LineNr
        FROM dbo.T_ProdBillOfOper
        WHERE ProdHeaderDossierCode = @ProdHeaderDossierCode
              AND ProdBOOLineNr = bm.ProdBOOLineNr) AS [ENG_Old],
  (SELECT linenr FROM [T_ProdBillOfOper] bo Where bo.ProdHeaderDossierCode = @ProdHeaderDossierCode AND bo.MachGrpCode LIKE '%ENG%') [ENG_New]
  FROM [T_prodbillofmat] bm 
  LEFT JOIN T_ProdHeadProdBOMLink PHPBL on (bm.prodBomLineNr = PHPBL.ProdBomLineNr AND bm.prodheaderdossiercode = PHPBL.ProdBOMprodheaderdossiercode)
  LEFT JOIN [T_ProductionHeader] tbm on tbm.prodheaderdossiercode = PHPBL.prodheaderdossiercode
  WHERE bm.ProdHeaderDossierCode = @ProdHeaderDossierCode
  AND tbm.ProdStatusCode = 15 --Filter for code 15 to exclude sub PD's that are already processed.
  ) a WHERE ENG_Old <> ENG_New OR ENG_OLD IS NULL order by PartPos
