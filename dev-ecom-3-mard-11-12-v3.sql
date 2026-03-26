-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.2: Update list of existing storage locations, none missing.
     Second storage location for 9400#0 Sundsvall: Butik.
v.3: Always AR.artbeskrspec from 2000 mallbolaget.
     Refactor with new CTE cte_mard_base.
     Add column MARD_RUN_ID.
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
),
cte_mard_base AS (  -- Add v.3.
  SELECT
    ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Change v.3.
    ar_2000.artbeskrspec AS MARD_PRODUCT,  -- SAP Product. Change v.3.
    CAST(GETDATE() AS date) AS MARD_RUN_ID,  -- Add v.3.
    ars.ForetagKod AS ARS_ForetagKod,
    ars.LagStalle AS ARS_LagStalle,
    CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS  -- SAP plant
  FROM
    ar AS ar_2000  -- Mall
    INNER JOIN ar AS ar_op  -- Operativa bolag
      ON ar_2000.artnr = ar_op.artnr
      AND ar_2000.ForetagKod = 2000  -- Mall
      AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
    INNER JOIN ars
      ON ars.foretagkod = ar_op.foretagkod
      AND ars.artnr = ar_op.artnr
  WHERE
    ar_2000.artnr IN (SELECT artnr FROM cte_artnr)
)
-- One storage location per plant.
SELECT
  AR_ArtNr,
  MARD_PRODUCT,
  MARD_RUN_ID,
  MARD_WERKS,
  MARD_WERKS AS MARD_LGORT  -- SAP storage location
FROM
  cte_mard_base
WHERE
  (  (ForetagKod = 6000 AND LagStalle IN ('20', '30', '101', '102') )  -- Öst
  OR (ForetagKod = 9100 AND LagStalle IN ('5000') )  -- Väst
  OR (ForetagKod = 9400 AND LagStalle IN ('0', '2', '4', '5', '6') )  -- Norr
  OR (ForetagKod = 9500 AND LagStalle IN ('0', '5', '6', '7', '8') )  -- Syd
  )

UNION ALL

-- Second storage location for 9400#0 Sundsvall: Butik.
SELECT
  AR_ArtNr,
  MARD_PRODUCT,
  MARD_RUN_ID,
  MARD_WERKS,
  CONCAT(CAST(ForetagKod AS nvarchar(4)), '#', LagStalle, 'X') AS MARD_LGORT  -- SAP storage location
FROM
  cte_mard_base
WHERE
  ForetagKod = 9400 AND LagStalle = '0'  -- Norr Sundsvall

UNION ALL

-- Second storage location for 9500#5 Växjö: Butik.
SELECT
  AR_ArtNr,
  MARD_PRODUCT,
  MARD_RUN_ID,
  MARD_WERKS,
  CONCAT(CAST(ForetagKod AS nvarchar(4)), '#', LagStalle, 'X') AS MARD_LGORT  -- SAP storage location
FROM
  cte_mard_base
WHERE
  ForetagKod = 9500 AND LagStalle = '5'  -- Syd Växjö

ORDER BY 2, 4, 5;


==============

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
-- One storage location per plant.
SELECT
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Change v.3.
  ar_2000.artbeskrspec AS MARD_PRODUCT,  -- SAP Product. Change v.3.
  CAST(GETDATE() AS date) AS MARD_RUN_ID,  -- Add v.3.
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS,  -- SAP plant
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_LGORT  -- SAP storage location
FROM
/* Remove v.3.
  ar
  INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
    AND ars.artnr = ar.artnr
*/
-- Add v.3.
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000  -- Mall
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  INNER JOIN ars
    ON ars.foretagkod = ar_op.foretagkod
    AND ars.artnr = ar_op.artnr
WHERE
  -- Specifika lager: ARS.ForetagKod (smallint) och ARS.LagStalle (nvarchar(16))
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  (ars.ForetagKod = 6000 AND ars.LagStalle IN ('20', '30', '101', '102') )  -- Öst
  OR (ars.ForetagKod = 9100 AND ars.LagStalle IN ('5000') )  -- Väst
  OR (ars.ForetagKod = 9400 AND ars.LagStalle IN ('0', '2', '4', '5', '6') )  -- Norr
  OR (ars.ForetagKod = 9500 AND ars.LagStalle IN ('0', '5', '6', '7', '8') )  -- Syd
  )
  AND ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Change v.3.

UNION ALL

-- Second storage location for 9400#0 Sundsvall: Butik.
SELECT
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Change v.3.
  ar_2000.artbeskrspec AS MARD_PRODUCT,  -- SAP Product. Change v.3.
  CAST(GETDATE() AS date) AS MARD_RUN_ID,  -- Add v.3.
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS,  -- SAP plant
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle, 'X') AS MARD_LGORT  -- SAP storage location
FROM
/* Remove v.3.
  ar
  INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
    AND ars.artnr = ar.artnr
*/
-- Add v.3.
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000  -- Mall
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  INNER JOIN ars
    ON ars.foretagkod = ar_op.foretagkod
    AND ars.artnr = ar_op.artnr
WHERE
  ars.ForetagKod = 9400 AND ars.LagStalle = '0'  -- Norr Sundsvall
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.

UNION ALL

-- Second storage location for 9500#5 Växjö: Butik.
SELECT
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Change v.3.
  ar_2000.artbeskrspec AS MARD_PRODUCT,  -- SAP Product. Change v.3.
  CAST(GETDATE() AS date) AS MARD_RUN_ID,  -- Add v.3.
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS,  -- SAP plant
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle, 'X') AS MARD_LGORT  -- SAP storage location
FROM
/* Remove v.3.
  ar
  INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
    AND ars.artnr = ar.artnr
*/
-- Add v.3.
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000  -- Mall
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  INNER JOIN ars
    ON ars.foretagkod = ar_op.foretagkod
    AND ars.artnr = ar_op.artnr
WHERE
  ars.ForetagKod = 9500 AND ars.LagStalle = '5'  -- Syd Växjö
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.

ORDER BY 2, 3, 4;

-- END