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
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MVKE_PRODUCT,
  AR.ForetagKod AS MVKE_VKORG,  -- SAP sales org
  10 AS MVKE_VTWEG,  -- SAP distribution channel
  'ABC' AS MVKE_VMSTA,  -- SAP sales status per assortment
  '2026-01-01' AS MVKE_VMSTD,  -- SAP sales status date
--  IIF(AR.artfsgforp > 1.0, ROUND(AR.artfsgforp, 3), '') AS MVKE_AUMNG,  -- SAP Minimum Order Quantity in Base UoM
  CASE
    WHEN ar.artfsgforp > 0.0 AND ar.artfsgforp <> 1.0 AND FLOOR(ar.artfsgforp) = CEILING(ar.artfsgforp)  -- If meaningful integer value
      THEN CAST(CAST(ar.artfsgforp AS int) AS varchar(16))  -- integer as varchar(16)
    WHEN ar.artfsgforp > 0.0 THEN CAST(ROUND(ar.artfsgforp, 3) AS varchar(16))  -- decimal(15,6) as varchar(16)
    ELSE CAST('' AS varchar(16))
    -- Mix integer, decimal and '' in varchar column
  END AS MVKE_AUMNG,  -- SAP Minimum Order Quantity in Base UoM
--  'NORM' AS MVKE_MTPOS,  -- SAP Item Category Group / Remove v.2.
  CASE  -- Add v.2.
    WHEN ar.ordtyp = 10 THEN 'CBNA'  -- "3rd party SO w/o SN".
    ELSE  -- ar.ordtyp <> 10
      CASE ar.anskaffningssatt  -- (smallint not nullable)
        WHEN 0 THEN 'NORM'  -- BP. "Standard item".
        WHEN 2 THEN 'CBUK'  -- KMB. "Bought-in".
        ELSE 'NORM'  -- Default: "Standard item".
      END
  END AS MVKE_MTPOS,  -- SAP Item Category Group
  'Z1' AS MVKE_KTGRM  -- SAP Account Assignment Group
FROM ar
WHERE
  AR.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2, 3;

-- Sales tax classification. One (1) country for all locations, select from mallbolaget 2000.
-- (If consistency problems, SELECT DISTINCT from operational companies, but then risk of duplicates if inconsistent AR.momskod.)
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS MLAN_PRODUCT,
  'SE' AS MLAN_ALAND,
  'TTX1' AS MLAN_TATYP1,
  COALESCE(ar.momskod, '') AS MLAN_TAXM1  -- SAP sales tax
FROM ar
WHERE
  ForetagKod = 2000  -- Mall
  AND extra4 IN (11, 12)
ORDER BY 2, 3;

-- END