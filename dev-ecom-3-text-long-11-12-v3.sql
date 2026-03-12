-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

-- (1) "Product" tab, structure S_MARA
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS MARA_PRODUCT,
  CAST(GETDATE() AS date) AS MARA_RUN_ID
FROM ar
WHERE
  ar.foretagkod IN (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
ORDER BY 2;

-- (2) "Product text" tab, structure S_PRODUCT
-- Basic text (GRUN).
-- Not in v.1: Purchase text (BEST), Internal note (IVER), Inspection text (PRUE).
-- English UNION ALL Swedish.
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS PRODUCT_PRODUCT,
  CAST(GETDATE() AS date) AS PRODUCT_RUN_ID,
  'GRUN' AS PRODUCT_TDID,  -- SAP Text ID
  'EN' AS PRODUCT_TDSPRAS,  -- SAP language key English
  CONCAT(TRIM(AR.artbeskr), ' ', TRIM(AR.artbeskr2)) AS PRODUCT_LONGTEXT
FROM ar
WHERE
  ar.foretagkod IN (2000)  -- Mall
  AND ar.extra4 IN (11, 12)

UNION ALL

SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS PRODUCT_PRODUCT,
  CAST(GETDATE() AS date) AS PRODUCT_RUN_ID,
  'GRUN' AS PRODUCT_TDID,  -- SAP Text ID
  'SV' AS PRODUCT_TDSPRAS,  -- SAP language key Swedish
  CONCAT(TRIM(AR.artbeskr), ' ', TRIM(AR.artbeskr2)) AS PRODUCT_LONGTEXT
FROM ar
WHERE
  ar.foretagkod IN (2000)  -- Mall
  AND ar.extra4 IN (11, 12)

ORDER BY 2, 4, 5;

-- (3) "MRP text" tab, structure S_MDTXT
-- N/A v.1.

-- (4) "Sales text" tab, structure S_MVKE
-- N/A v.1.

-- END