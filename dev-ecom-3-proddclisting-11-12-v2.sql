-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.1: Initial.
v.2: Always AR.artbeskrspec from 2000 mallbolaget.
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
SELECT
--  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Remove v.2.
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Add v.2.
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS PRODDCLIST_DC,  -- SAP Distribution Center
--  ar.artbeskrspec AS PRODDCLIST_PRODUCT  -- SAP Product. Remove v.2.
  ar_2000.artbeskrspec AS PRODDCLIST_PRODUCT  -- SAP Product. Add v.2.
FROM
/*  Remove v.2.
  ar
  INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
    AND ars.artnr = ar.artnr
*/
-- Add v.2.
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000  -- Mall
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  INNER JOIN ars
    ON ars.foretagkod = ar_op.foretagkod
    AND ars.artnr = ar_op.artnr
WHERE
  -- Specifika lager: ARS.ForetagKod (smallint) och ARS.LagStalle (nvarchar(16))
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  ( ars.ForetagKod = 6000 AND ars.LagStalle IN ('20', '30', '101', '102') )  -- Öst
  OR ( ars.ForetagKod = 9100 AND ars.LagStalle IN ('5000') )  -- Väst
  OR ( ars.ForetagKod = 9400 AND ars.LagStalle IN ('0', '2', '4', '5', '6') )  -- Norr
  OR ( ars.ForetagKod = 9500 AND ars.LagStalle IN ('0', '5', '6', '7', '8') )  -- Syd
  )
--  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Remove v.2.
  AND ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Add v.2.
ORDER BY 2, 3;

-- END