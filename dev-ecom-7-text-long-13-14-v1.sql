-- Ecom articles from Jeeves.
-- V : Retailvariant
-- V? : Osäker om det kan vara en Retailvariant. Om den inte kan vara en Retailvariant så bör ändå "varianterna" hållas ihop i samma produkt (se P)

/* Change log
v.1: Initial, ref: dev-ecom-3-text-long-11-12-v4.sql.
*/

-- (1) "Product" tab, structure S_MARA
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS MARA_PRODUCT,
  CAST(GETDATE() AS date) AS MARA_RUN_ID
FROM ar
WHERE
  ar.foretagkod IN (2000)  -- Mall
  AND ar.extra4 IN (13, 14)  -- #13: Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer. & #14: Ska bli variant-artikel med samma nummer.
ORDER BY 2;

-- (2) "Product text" tab, structure S_PRODUCT
-- Basic text (GRUN).
-- Internal note (IVER)
-- Not in v.4: Purchase text (BEST), Inspection text (PRUE).
-- English UNION ALL Swedish.
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS PRODUCT_PRODUCT,
  CAST(GETDATE() AS date) AS PRODUCT_RUN_ID,
  'GRUN' AS PRODUCT_TDID,  -- SAP Text ID: Basic text (GRUN)
  'EN' AS PRODUCT_TDSPRAS,  -- SAP language key English
  CONCAT(TRIM(ar.artbeskr), ' ', TRIM(ar.artbeskr2)) AS PRODUCT_LONGTEXT
FROM ar
WHERE
  ar.foretagkod IN (2000)  -- Mall
  AND ar.extra4 IN (13, 14)  -- #13: Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer. & #14: Ska bli variant-artikel med samma nummer.

UNION ALL

SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS PRODUCT_PRODUCT,
  CAST(GETDATE() AS date) AS PRODUCT_RUN_ID,
  'GRUN' AS PRODUCT_TDID,  -- SAP Text ID: Basic text (GRUN)
  'SV' AS PRODUCT_TDSPRAS,  -- SAP language key Swedish
  CONCAT(TRIM(ar.artbeskr), ' ', TRIM(ar.artbeskr2)) AS PRODUCT_LONGTEXT
FROM ar
WHERE
  ar.foretagkod IN (2000)  -- Mall
  AND ar.extra4 IN (13, 14)  -- #13: Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer. & #14: Ska bli variant-artikel med samma nummer.

UNION ALL

SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS PRODUCT_PRODUCT,
  CAST(GETDATE() AS date) AS PRODUCT_RUN_ID,
  'IVER' AS PRODUCT_TDID,  -- SAP Text ID: Internal note (IVER)
  'SV' AS PRODUCT_TDSPRAS,  -- SAP language key Swedish
  TRIM(ar.q_interntext) AS PRODUCT_LONGTEXT  -- Jeeves Interntext, nvarchar(100) nullable
FROM ar
WHERE
  ar.foretagkod IN (2000)  -- Mall
  AND ar.extra4 IN (13, 14)  -- #13: Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer. & #14: Ska bli variant-artikel med samma nummer.
  AND LEN(TRIM(COALESCE(ar.q_interntext, ''))) > 0  -- Only if filled.

ORDER BY 2, 4, 5;

-- (3) "MRP text" tab, structure S_MDTXT
-- N/A v.4.

-- (4) "Sales text" tab, structure S_MVKE
-- N/A v.4.

-- END