-- Ecom articles from Jeeves.
-- V : Retailvariant
-- V? : Osäker om det kan vara en Retailvariant. Om den inte kan vara en Retailvariant så bör ändå "varianterna" hållas ihop i samma produkt (se P)

/* Change log
v.1: Initial version, ref: dev-ecom-3-mard-11-12-v3.sql.
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (13)  -- Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer.
),
cte_mard_base AS (
  SELECT
    ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
    ar_2000.artbeskrspec AS MARD_PRODUCT,  -- SAP Product
    CAST(GETDATE() AS date) AS MARD_RUN_ID,  -- SAP Run ID
    ars.ForetagKod,
    ars.LagStalle,
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
  -- Specifika lager: ARS.ForetagKod (smallint) och ARS.LagStalle (nvarchar(16))
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  (ForetagKod = 6000 AND LagStalle IN ('20', '30', '101', '102') )  -- Öst
  OR (ForetagKod = 9100 AND LagStalle IN ('5000') )  -- Väst
  OR (ForetagKod = 9400 AND LagStalle IN ('0', '2', '4', '5', '6') )  -- Norr
  OR (ForetagKod = 9500 AND LagStalle IN ('0', '5', '6', '7', '8') )  -- Syd
  )

UNION ALL

-- Second (extra) storage location for 9400#0 Sundsvall: Butik.
SELECT
  AR_ArtNr,
  MARD_PRODUCT,
  MARD_RUN_ID,
  MARD_WERKS,
  CONCAT(MARD_WERKS, 'X') AS MARD_LGORT  -- SAP storage location
FROM
  cte_mard_base
WHERE
  ForetagKod = 9400 AND LagStalle = '0'  -- Norr Sundsvall

UNION ALL

-- Second (extra) storage location for 9500#5 Växjö: Butik.
SELECT
  AR_ArtNr,
  MARD_PRODUCT,
  MARD_RUN_ID,
  MARD_WERKS,
  CONCAT(MARD_WERKS, 'X') AS MARD_LGORT  -- SAP storage location
FROM
  cte_mard_base
WHERE
  ForetagKod = 9500 AND LagStalle = '5'  -- Syd Växjö

ORDER BY 2, 4, 5;

-- END