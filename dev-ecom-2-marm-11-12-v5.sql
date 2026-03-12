-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.
-- XARE Alternativ enhet; primärnyckel = ForetagKod + ArtNr + AltEnhetKod
--dev-ecom-2-marm-11-12-v5.sql
SELECT
  ar.artnr AS AR_ArtNr,
  ar.enhetskod AS AR_EnhetsKod,
  ar.artbeskrspec AS MARM_PRODUCT,
  xare.AltEnhetKod AS MARM_MEINH,
  1 AS MARM_UMREN,
  CASE
    WHEN FLOOR(xare.AltEnhetOmrFaktor) = CEILING(xare.AltEnhetOmrFaktor)
      THEN CAST(CAST(xare.AltEnhetOmrFaktor AS int) AS varchar(13))
    ELSE CAST(xare.AltEnhetOmrFaktor AS varchar(13))
  END AS MARM_UMREZ,
  CASE
    WHEN xare.AltEnhetOmrFaktor >= 100000.0 THEN 'OVERFLOW'
    WHEN NOT(FLOOR(xare.AltEnhetOmrFaktor) = CEILING(xare.AltEnhetOmrFaktor)) THEN 'DECIMAL'
    ELSE ''
  END AS SAP_ERROR,
  '' AS MARM_EAN11,
  'KG' AS MARM_GEWEI,
  'M3' AS MARM_VOLEH
FROM ar
  INNER JOIN xare
    ON ar.foretagkod = xare.foretagkod
   AND ar.artnr = xare.artnr
WHERE
  ar.foretagkod IN (2000)
  AND ar.extra4 IN (11, 12)
  AND xare.AltEnhetKod <> 'vol'
  AND xare.AltEnhetKod <> ar.enhetskod
ORDER BY 3, 4;