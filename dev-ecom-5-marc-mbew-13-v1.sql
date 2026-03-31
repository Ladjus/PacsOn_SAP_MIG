-- Ecom articles from Jeeves.
-- V : Retailvariant
-- V? : Osäker om det kan vara en Retailvariant. Om den inte kan vara en Retailvariant så bör ändå "varianterna" hållas ihop i samma produkt (se P)

/* Change log
v.1: Initial version, ref: dev-ecom-3-marc-mbew-11-12-v6.sql.
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (13)  -- Ska bli generisk-artikel (alltid nytt nummer). Ska bli variant-artikel med samma nummer.
)
SELECT
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  CONCAT('GEN#', ar_2000.artbeskrspec) AS MARC_PRODUCT,  -- SAP Product
  CAST(GETDATE() AS date) AS MARC_RUN_ID,  -- SAP Run ID
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARC_WERKS,  -- SAP plant

  'ND' AS MARC_DISMM,  -- SAP MRP type
  '#001' AS MARC_DISPO,  -- SAP MRP controller
  'SR' AS MARC_MTVFP,  -- SAP availability check
  ar_op.ForetagKod AS MARC_PRCTR,  -- SAP profit centre
  '' AS MARC_XCHPF,  -- SAP batch management
  '#0003' AS MARC_LADGR,  -- SAP loading group

  '' AS MARC_EKGRP,  -- SAP purchasing group

  '' AS MARC_KAUTB,  -- SAP auto purchase order
  COALESCE(ar_2000.momskod, 1) AS MARC_TAXIM,  -- SAP purchase tax. AR.momskod (smallint nullable)

  '' AS MARC_MINBE,  -- SAP reorder point qty
  '' AS MARC_DISLS,  -- SAP lot size procedure
  '' AS MARC_BSTMI,  -- SAP minimum lot size
  '' AS MARC_BSTFE,  -- SAP fixed lot size
  '' AS MARC_BSTRF,  -- SAP rounding value. May be NULL cus AL outer join.
  '' AS MARC_BESKZ,  -- SAP procurement type
  '' AS MARC_LGFSB,  -- SAP storage loc ext procurement

  '' AS MARC_PLIFZ,  -- SAP planned delivery time. Jeeves Ledtid (smallint not nullable)

  'X' AS MARC_PSTATL,  -- Indicator: Storage
  'X' AS MARC_PSTATE,  -- Indicator: Purchasing
  'X' AS MARC_PSTATV,  -- Indicator: Sales

  2 AS MBEW_MLAST,  -- SAP Price Control Determination = Transaction-based.
  3100 AS MBEW_BKLAS,  -- SAP Valuation Class.
  'V' AS MBEW_VPRSV,  -- SAP Price Control = moving average.
  'SEK' AS MBEW_WAERS,  -- SAP Currency
  1 AS MBEW_VERPR,  -- SAP Inventory Price Moving Average
  1 AS MBEW_PEINH,  -- SAP Price Unit (quantity)
  'X' AS MBEW_PSTATB  -- Indicator: Accounting

FROM
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000  -- Mall
    AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS
  INNER JOIN ars
    ON ars.foretagkod = ar_op.foretagkod
    AND ars.artnr = ar_op.artnr
  LEFT OUTER JOIN al
    ON al.foretagkod = ar_op.foretagkod
    AND al.artnr = ar_op.artnr
    AND al.ArtHuvudAvt = '1'  -- Jeeves: endast huvudavtal (char(1))
WHERE
  -- Specifika lager: ARS.ForetagKod (smallint) och ARS.LagStalle (nvarchar(16))
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (  (ars.ForetagKod = 6000 AND ars.LagStalle IN ('20', '30', '101', '102') )  -- Öst
  OR (ars.ForetagKod = 9100 AND ars.LagStalle IN ('5000') )  -- Väst
  OR (ars.ForetagKod = 9400 AND ars.LagStalle IN ('0', '2', '4', '5', '6') )  -- Norr
  OR (ars.ForetagKod = 9500 AND ars.LagStalle IN ('0', '5', '6', '7', '8') )  -- Syd
  )
  AND ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Change v.6.
ORDER BY 2, 3;

-- END