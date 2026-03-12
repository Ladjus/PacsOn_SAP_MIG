-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

-- (1) "Basic data" tab, structure S_MARA
WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
SELECT DISTINCT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MARA_PRODUCT
FROM AR
  INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
    AND ARS.artnr = AR.artnr
WHERE
  -- Specifika lager EWM: ARS.ForetagKod (smallint) och ARS.LagStalle (char)
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  ( ARS.ForetagKod = 6000 AND TRIM(ARS.LagStalle) IN ('20', '30') )  -- Öst: Jordbro 20, Linköping 30.
  OR ( ARS.ForetagKod = 9100 AND TRIM(ARS.LagStalle) IN ('5000') )  -- Väst: Falköping.
  OR ( ARS.ForetagKod = 9400 AND TRIM(ARS.LagStalle) IN ('0', '2') )  -- Norr: Sundsvall 0, Skellefteå 2.
  OR ( ARS.ForetagKod = 9500 AND TRIM(ARS.LagStalle) IN ('0', '5') )  -- Syd: Malmö 0, Växjö 5.
  )
  AND AR.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2;

-- (2) "Warehouse product" tab, structure S_MATLWH
WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MATLWH_PRODUCT,
  CONCAT(CAST(ARS.ForetagKod AS nvarchar(4)), '#', TRIM(ARS.LagStalle)) AS MATLWH_LGNUM,  -- SAP Warehouse Number
  CONCAT(CAST(ARS.ForetagKod AS nvarchar(4)), '#', TRIM(ARS.LagStalle)) AS MATLWH_ENTITLED  -- SAP Party Entitled to Dispose
FROM AR
  INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
    AND ARS.artnr = AR.artnr
WHERE
  -- Specifika lager EWM: ARS.ForetagKod (smallint) och ARS.LagStalle (char)
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  ( ARS.ForetagKod = 6000 AND TRIM(ARS.LagStalle) IN ('20', '30') )  -- Öst: Jordbro 20, Linköping 30.
  OR ( ARS.ForetagKod = 9100 AND TRIM(ARS.LagStalle) IN ('5000') )  -- Väst: Falköping.
  OR ( ARS.ForetagKod = 9400 AND TRIM(ARS.LagStalle) IN ('0', '2') )  -- Norr: Sundsvall 0, Skellefteå 2.
  OR ( ARS.ForetagKod = 9500 AND TRIM(ARS.LagStalle) IN ('0', '5') )  -- Syd: Malmö 0, Växjö 5.
  )
  AND AR.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2, 3;

-- END