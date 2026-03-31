-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.1: Initial version, ref: dev-ecom-3-mara-11-12-v2.sql.
*/


WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (13)  -- Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer.
)
SELECT DISTINCT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  CONCAT('GEN#', ar.artbeskrspec) AS MARA_PRODUCT,  -- SAP Product
  CAST(GETDATE() AS date) AS MARA_RUN_ID  -- SAP Run ID
FROM ar
WHERE
  ar.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2;

-- END