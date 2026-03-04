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
  AR.artnr AS AR_ArtNr,
  AR.artbeskrspec AS MARD_PRODUCT,
  CONCAT(ARS.ForetagKod, '#', TRIM(ARS.LagStalle)) AS MARD_WERKS,
  CONCAT(ARS.ForetagKod, '#', TRIM(ARS.LagStalle)) AS MARD_LGORT
FROM ar
  INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
    AND ARS.artnr = AR.artnr
WHERE
  (  ( ARS.ForetagKod = 6000 AND TRIM(ARS.LagStalle) IN ('20', '30', '101', '102') )
  OR ( ARS.ForetagKod = 9100 AND TRIM(ARS.LagStalle) IN ('5000') )
  OR ( ARS.ForetagKod = 9400 AND TRIM(ARS.LagStalle) IN ('0', '2', '4', '5') )
  OR ( ARS.ForetagKod = 9500 AND TRIM(ARS.LagStalle) IN ('0', '5', '7') )
  )
  AND AR.artnr IN (SELECT artnr FROM cte_artnr)

UNION ALL

-- Second storage location in 9500#5 Växjö.
SELECT
  AR.artnr AS AR_ArtNr,
  AR.artbeskrspec AS MARD_PRODUCT,
  CONCAT(ARS.ForetagKod, '#', TRIM(ARS.LagStalle)) AS MARD_WERKS,
  CONCAT(ARS.ForetagKod, '#', TRIM(ARS.LagStalle), 'X') AS MARD_LGORT
FROM ar
  INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
    AND ARS.artnr = AR.artnr
WHERE
  ARS.ForetagKod = 9500
  AND TRIM(ARS.LagStalle) = '5'
  AND AR.artnr IN (SELECT artnr FROM cte_artnr)

ORDER BY 2, 3, 4;