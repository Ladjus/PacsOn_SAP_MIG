-- Commodity code

-- Ecom articles from Jeeves.
-- P : Singelartiklar som ska hållas ihop  som en produkt  i Artikelhierarki 2 
-- S : Singelartikel utan "kompisar"
-- V : Retailvariant
-- V? : Osäker om det kan vara en Retailvariant. Om den inte kan vara en Retailvariant så bör ändå "varianterna" hållas ihop i samma produkt (se P)

WITH cte_artnr AS (
    SELECT artnr
    FROM ar
    WHERE ForetagKod = 2000  -- Mall
      AND extra4 > 0.0  -- Mig-flag set.
)
SELECT
    AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
    AR.artbeskrspec AS MARITC_MATNR,
    CONCAT(CAST(ARS.ForetagKod AS nvarchar(4)), '#', TRIM(ARS.LagStalle)) AS MARITC_PLANT,  -- SAP plant
    AR.artstatnr                    -- SAP commodity code
FROM ar
  INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
    AND ars.artnr = ar.artnr
WHERE
  -- Specifika lager: ARS.ForetagKod (smallint) och ARS.LagStalle (char)
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  ( ARS.ForetagKod = 6000 AND TRIM(ARS.LagStalle) IN ('20', '30', '101', '102') )  -- Öst
  OR ( ARS.ForetagKod = 9100 AND TRIM(ARS.LagStalle) IN ('5000') )  -- Väst
  OR ( ARS.ForetagKod = 9400 AND TRIM(ARS.LagStalle) IN ('0', '2', '4', '5', '6') )  -- Norr
  OR ( ARS.ForetagKod = 9500 AND TRIM(ARS.LagStalle) IN ('0', '5', '6', '7', '8') )  -- Syd
  )
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2, 3;

-- END