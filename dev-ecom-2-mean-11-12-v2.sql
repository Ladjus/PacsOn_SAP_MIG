-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.
-- AREAN Alternativ EAN; primärnyckel = ForetagKod + ArtNr + ArtNrEAN
SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MEAN_PRODUCT,
--  AREAN.AltEnhetKod AS MEAN_MEINH,  -- Alternative Unit of Measure
  COALESCE(AREAN.AltEnhetKod, AR.enhetskod, "ERROR") AS MEAN_MEINH,  -- Alternative Unit of Measure. If AREAN has NULL, then ref AR base unit.
  AREAN.ArtNrEAN AS MEAN_EAN11, -- -- GTIN, 2:a per alt-enhet
FROM ar
  INNER JOIN arean
    ON ar.foretagkod = arean.foretagkod 
      AND ar.artnr = arean.artnr
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
ORDER BY 2, 3;
