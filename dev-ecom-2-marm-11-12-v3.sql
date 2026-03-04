-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.
-- XARE Alternativ enhet; primärnyckel = ForetagKod + ArtNr + AltEnhetKod
SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.enhetskod AS AR_EnhetsKod,  Jeeves basenhet
  AR.artbeskrspec AS MARM_PRODUCT,
  XARE.AltEnhetKod AS MARM_MEINH,  -- Alternative Unit of Measure
  1 AS MARM_UMREN,  -- Denominator for Conversion to Base Unit
  IIF(FLOOR(XARE.AltEnhetOmrFaktor) = CEILING(XARE.AltEnhetOmrFaktor), CAST(XARE.AltEnhetOmrFaktor AS INT), XARE.AltEnhetOmrFaktor) AS MARM_UMREZ,  -- Numerator for Conversion to Base Unit. Integer if possible.
  ''                     AS MARM_EAN11,  -- GTIN, 1:a per alt-enhet
  'KG' AS MARM_GEWEI,
  'M3' AS MARM_VOLEH
FROM ar
  INNER JOIN xare
    ON ar.foretagkod = xare.foretagkod
      AND ar.artnr = xare.artnr
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
ORDER BY 3, 4;