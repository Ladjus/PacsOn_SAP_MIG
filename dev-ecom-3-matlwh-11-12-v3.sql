-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.1: Initial version, only structure MATLWH.
v.2: Added query for structure S_MARA.
v.3: Always AR.artbeskrspec from 2000 mallbolaget.
     Add column MARA_RUN_ID.
     Add column MATLWH_RUN_ID.
*/

-- (1) "Basic data" tab, structure S_MARA
WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
SELECT DISTINCT
--  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Remove v.3.
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Add v.3.
--  AR.artbeskrspec AS MARA_PRODUCT  -- SAP Product. Remove v.3.
  ar_2000.artbeskrspec AS MARA_PRODUCT,  -- SAP Product. Add v.3.
  CAST(GETDATE() AS date) AS MARA_RUN_ID  -- Add v.3.
FROM
/* Remove v.3.
  AR
  INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
    AND ARS.artnr = AR.artnr
*/
-- Add v.3.
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000  -- Mall
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  INNER JOIN ars
    ON ars.foretagkod = ar_op.foretagkod
    AND ars.artnr = ar_op.artnr
WHERE
  -- Specifika lager EWM: ARS.ForetagKod (smallint) och ARS.LagStalle (char)
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  ( ars.ForetagKod = 6000 AND ars.LagStalle IN ('20', '30') )  -- Öst: Jordbro 20, Linköping 30.
  OR ( ars.ForetagKod = 9100 AND ars.LagStalle IN ('5000') )  -- Väst: Falköping.
  OR ( ars.ForetagKod = 9400 AND ars.LagStalle IN ('0', '2') )  -- Norr: Sundsvall 0, Skellefteå 2.
  OR ( ars.ForetagKod = 9500 AND ars.LagStalle IN ('0', '5') )  -- Syd: Malmö 0, Växjö 5.
  )
--  AND AR.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Remove v.3.
  AND ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Add v.3.
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
--  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Remove v.3.
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Add v.3.
--  AR.artbeskrspec AS MATLWH_PRODUCT,  -- SAP Product. Remove v.3.
  ar_2000.artbeskrspec AS MATLWH_PRODUCT,  -- SAP Product. Add v.3.
  CAST(GETDATE() AS date) AS MATLWH_RUN_ID,  -- Add v.3.
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MATLWH_LGNUM,  -- SAP Warehouse Number
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MATLWH_ENTITLED  -- SAP Party Entitled to Dispose
FROM
/* Remove v.3.
  AR
  INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
    AND ARS.artnr = AR.artnr
*/
-- Add v.3.
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000  -- Mall
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  INNER JOIN ars
    ON ars.foretagkod = ar_op.foretagkod
    AND ars.artnr = ar_op.artnr
WHERE
  -- Specifika lager EWM: ARS.ForetagKod (smallint) och ARS.LagStalle (char)
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  ( ars.ForetagKod = 6000 AND ars.LagStalle IN ('20', '30') )  -- Öst: Jordbro 20, Linköping 30.
  OR ( ars.ForetagKod = 9100 AND ars.LagStalle IN ('5000') )  -- Väst: Falköping.
  OR ( ars.ForetagKod = 9400 AND ars.LagStalle IN ('0', '2') )  -- Norr: Sundsvall 0, Skellefteå 2.
  OR ( ars.ForetagKod = 9500 AND ars.LagStalle IN ('0', '5') )  -- Syd: Malmö 0, Växjö 5.
  )
--  AND AR.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Remove v.3.
  AND ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Add v.3.
ORDER BY 2, 3;

-- END