-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.
-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.
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
  '2026-03-01' AS MVKE_VMSTD,  -- SAP sales status date
  IIF(AR.artfsgforp > 1.0, ROUND(AR.artfsgforp, 3), NULL) AS MVKE_AUMNG,  -- SAP Minimum Order Quantity in Base UoM
  'NORM' AS MVKE_MTPOS,  -- SAP Item Category Group
  'Z1' AS MVKE_KTGRM  -- SAP Account Assignment Group
FROM ar
WHERE
  AR.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  AND AR.artnr IN (SELECT artnr FROM cte_artnr)  -- FIX
ORDER BY 2, 3;
-- Sales tax classification. One (1) country for all locations, select from mallbolaget 2000.
-- (If consistency problems, SELECT DISTINCT from operational companies, but then risk of duplicates if inconsistent AR.momskod.)
SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MLAN_PRODUCT,
  'SE' AS MLAN_ALAND,
  'TTX1' AS MLAN_TATYP1,
  COALESCE(AR.momskod, '') AS MLAN_TAXM1  -- SAP sales tax
FROM ar
WHERE
  ForetagKod = 2000  -- Mall
  AND extra4 IN (11, 12)
ORDER BY 2, 3;

-- END