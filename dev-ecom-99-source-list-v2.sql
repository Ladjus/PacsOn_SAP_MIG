-- Ecom articles from Jeeves.

/* Change log
v.1: Initial.
v.2: Join ARS for EORD_WERKSplantExclude base-unit of measure.
     Always AR.artbeskrspec from 2000 mallbolaget.
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 > 0.0  -- Mig-flag set
)
SELECT
  CONCAT(al.ArtNr, '#', al.ForetagKod, '#', al.FtgNr, '#', al.InkAvt, '#', al.ArtLevPrior) AS AL_Key,
  LEFT(CONCAT(al.ArtNr, '#', al.ForetagKod, '#', al.FtgNr, '#', al.InkAvt, '#', al.ArtLevPrior), 20) AS EORD_ZEORD,  -- SAP number of source list record
  ar_2000.artbeskrspec AS EORD_MATNR,  -- SAP Product
  CONCAT(CAST(ARS.ForetagKod AS nvarchar(4)), '#', ARS.LagStalle) AS EORD_WERKS,  -- SAP plant
  '2026-03-01' AS EORD_VDATU,  -- SAP valid from date
  '9999-12-31' AS EORD_BDATU,  -- SAP valid to date
  CONCAT(al.FtgNr, '#', al.ForetagKod) AS EORD_LIFNR,  -- SAP supplier
  CASE al.ArtHuvudAvt  -- (char(1))
    WHEN '1' THEN 'X'
    ELSE ''
  END AS EORD_FLIFN  -- SAP indicator: fixed supplier
FROM
/* Remove v.2.
  ar
  INNER JOIN al
    ON al.foretagkod = ar.foretagkod
    AND al.artnr = ar.artnr
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
  INNER JOIN al
    ON al.foretagkod = ar_op.foretagkod
    AND al.artnr = ar_op.artnr
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
  AND ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Change v.2.
ORDER BY 3, 2;

-- END