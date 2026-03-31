-- Ecom articles from Jeeves.
-- V : Retailvariant
-- V? : Osäker om det kan vara en Retailvariant. Om den inte kan vara en Retailvariant så bör ändå "varianterna" hållas ihop i samma produkt (se P)

/* Change log
v.1: Initial version, ref: dev-ecom-3-mvke-mlan-11-12-v5.sql.
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (13)  -- Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer.
)
SELECT
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  CONCAT('GEN#', ar_2000.artbeskrspec) AS MVKE_PRODUCT,  -- SAP Product
  CAST(GETDATE() AS date) AS MVKE_RUN_ID,  -- SAP Run ID
  ar_op.ForetagKod AS MVKE_VKORG,  -- SAP sales org
  10 AS MVKE_VTWEG,  -- SAP distribution channel

  '' AS MVKE_VMSTA,  -- SAP sales status per assortment
  '' AS MVKE_VMSTD,  -- SAP sales status date

  'SAMM' AS MVKE_MTPOS,  -- SAP Item Category Group
  'Z1' AS MVKE_KTGRM  -- SAP Account Assignment Group
FROM
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000  -- Mall
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
WHERE
  ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery
ORDER BY 2, 3;

-- Sales tax classification. One (1) country for all locations, select from mallbolaget 2000.
-- (If consistency problems, SELECT DISTINCT from operational companies, but then risk of duplicates if inconsistent AR.momskod.)
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  CONCAT('GEN#', ar.artbeskrspec) AS MLAN_PRODUCT,  -- SAP Product
  'SE' AS MLAN_ALAND,
  'TTX1' AS MLAN_TATYP1,
  COALESCE(ar.momskod, 1) AS MLAN_TAXM1  -- SAP sales tax. AR.momskod (smallint nullable)
FROM ar
WHERE
  ForetagKod = 2000  -- Mall
  AND extra4 IN (13)  -- Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer.
ORDER BY 2, 3;

-- END