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
SELECT DISTINCT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MARA_PRODUCT,
  'YYYY-MM-DD' AS MARA_RUN_ID
FROM ar
WHERE
  AR.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2;

-- END