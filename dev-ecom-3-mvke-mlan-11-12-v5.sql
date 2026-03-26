-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.2: Item category group MTPOS:
     (a) Om Ordertyp [ar.ordtyp] = 10 "Direktleverans" så CBNA "3rd party SO w/o SN".
     (b) Om Ordertyp [ar.ordtyp] <> 10 och AR-Anskaffningssätt = 0 "BP" så NORM "Standard item".
     (c) Om Ordertyp [ar.ordtyp] <> 10 och AR-Anskaffningssätt = 2 "KMB" så CBUK "Bought-in".
     Must include condition for Anskaffningssätt 0 "BP" to have reorder-point quantity, but this is stored in ARS-table [ars.LagBestPkt] so cannot be checked since MVKE-data is on AR-level!
v.3: Column MVKE_AUMNG as type varchar(16).
v.4: Column MVKE_AUMNG as integer without decimals if applicable.
     Column MLAN_TAXM1 update.
v.5: Always AR.artbeskrspec from 2000 mallbolaget.
     Add column 
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
SELECT
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Change v.5.
  ar_2000.artbeskrspec AS MVKE_PRODUCT,  -- SAP Product. Change v.5.
  CAST(GETDATE() AS date) AS MVKE_RUN_ID,  -- Add v.5.
  ar_op.ForetagKod AS MVKE_VKORG,  -- SAP sales org. Change v.5.
  10 AS MVKE_VTWEG,  -- SAP distribution channel
  'ABC' AS MVKE_VMSTA,  -- SAP sales status per assortment
  '2026-01-01' AS MVKE_VMSTD,  -- SAP sales status date
--  IIF(AR.artfsgforp > 1.0, ROUND(AR.artfsgforp, 3), '') AS MVKE_AUMNG,  -- SAP Minimum Order Quantity in Base UoM

  CASE
    WHEN ar_op.artfsgforp > 0.0 AND ar_op.artfsgforp <> 1.0 AND FLOOR(ar_op.artfsgforp) = CEILING(ar_op.artfsgforp)  -- If meaningful integer value. Change v.5.
      THEN CAST(CAST(ar_op.artfsgforp AS int) AS varchar(16))  -- integer as varchar(16). Change v.5.
    WHEN ar_op.artfsgforp > 0.0 THEN CAST(ROUND(ar_op.artfsgforp, 3) AS varchar(16))  -- decimal(15,6) as varchar(16). Change v.5.
    ELSE CAST('' AS varchar(16))
    -- Mix integer, decimal and '' in varchar column
  END AS MVKE_AUMNG,  -- SAP Minimum Order Quantity in Base UoM

  CASE
    WHEN ar_op.ordtyp = 10 THEN 'CBNA'  -- "3rd party SO w/o SN". Change v.5.
    ELSE  -- ar_op.ordtyp <> 10
      CASE ar_op.anskaffningssatt  -- (smallint not nullable) Change v.5.
        WHEN 0 THEN 'NORM'  -- BP. "Standard item".
        WHEN 2 THEN 'CBUK'  -- KMB. "Bought-in".
        ELSE 'NORM'  -- Default: "Standard item".
      END
  END AS MVKE_MTPOS,  -- SAP Item Category Group

  'Z1' AS MVKE_KTGRM  -- SAP Account Assignment Group
FROM
/* Remove v.5.
  ar
*/
-- Add v.5.
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)
WHERE
--  AR.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS. Remove v.5.
  ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Change v.5.
ORDER BY 2, 3;

-- Sales tax classification. One (1) country for all locations, select from mallbolaget 2000.
-- (If consistency problems, SELECT DISTINCT from operational companies, but then risk of duplicates if inconsistent AR.momskod.)
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS MLAN_PRODUCT,
  'SE' AS MLAN_ALAND,
  'TTX1' AS MLAN_TATYP1,
--  COALESCE(ar.momskod, '') AS MLAN_TAXM1  -- SAP sales tax. Remove v.4.
  COALESCE(ar.momskod, 1) AS MLAN_TAXM1  -- SAP sales tax. AR.momskod (smallint nullable). Add v.4.
FROM ar
WHERE
  ForetagKod = 2000  -- Mall
  AND extra4 IN (11, 12)
ORDER BY 2, 3;

-- END