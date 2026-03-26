-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.5: Column MARC_TAXIM update.
     Column MARC_MINBE as type varchar(16).
     Column MARC_BSTMI as type varchar(16).
v.6: Always AR.artbeskrspec from 2000 mallbolaget. Other columns from operational company alias AR_OP, except tax classification.
     Add column MARC_RUN_ID.
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
SELECT
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID". Change v.6.
  ar_2000.artbeskrspec AS MARC_PRODUCT,  -- SAP Product. Change v.6.
  CAST(GETDATE() AS date) AS MARC_RUN_ID,  -- Add v.3.
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARC_WERKS,  -- SAP plant

  CASE  -- Jeeves "Anskaffningssätt". ARS.LagBestPkt (decimal(15,6)).
    -- (1) Från ARS.anskaffningssatt (smallint nullable).
    WHEN ars.anskaffningssatt = 0 AND ars.LagBestPkt > 0.0 THEN 0  -- Om BP (0) och om BP-qty så BP (0)
    WHEN ars.anskaffningssatt = 0 AND NOT ars.LagBestPkt > 0.0 THEN 2  -- Om BP (0) utan BP-qty så KMB (2)
    WHEN ars.anskaffningssatt IS NOT NULL THEN ars.anskaffningssatt  -- KMB (2), etc från ARS.
    -- (2) Från AR.anskaffningssatt (smallint not nullable).
    WHEN ar_op.anskaffningssatt = 0 AND ars.LagBestPkt > 0.0 THEN 0  -- Om BP (0) och om BP-qty så BP (0). Change v.6.
    WHEN ar_op.anskaffningssatt = 0 AND NOT ars.LagBestPkt > 0.0 THEN 2  -- Om BP (0) utan BP-qty så KMB (2). Change v.6.
    ELSE ar_op.anskaffningssatt  -- KMB (2), etc från AR. Change v.6.
  END AS MARC_DISMM,  -- SAP MRP type

  '#001' AS MARC_DISPO,  -- SAP MRP controller
  'SR' AS MARC_MTVFP,  -- SAP availability check
  ar_op.ForetagKod AS MARC_PRCTR,  -- SAP profit centre. Change v.6.
  '' AS MARC_XCHPF,  -- SAP batch management
  '#0003' AS MARC_LADGR,  -- SAP loading group

  CASE ars.ForetagKod  -- (smallint not nullable)
    WHEN 6000 THEN  -- Öst
      CASE ars.LagStalle  -- (nvarchar(16))
        WHEN '20' THEN 'Åsa Björnskiöld'  -- Jordbro: Åsa.
        ELSE
          CASE WHEN ars.InkHandl = 'EB' THEN 'Erik Bergstedt' ELSE 'Tobias Wahlström' END
      END
    WHEN 9100 THEN ars.InkHandl -- Väst: Map from Jeeves inköpshandläggare.
    WHEN 9400 THEN  -- Norr, per lager.
      CASE ars.LagStalle
        WHEN '0' THEN 'Lars Fröberg'
        WHEN '2' THEN 'Eva Östlund'
        WHEN '6' THEN 'Eva Östlund'
        WHEN '4' THEN 'Lars Fröberg'
        WHEN '5' THEN 'Lars Fröberg'
      END
    WHEN 9500 THEN  -- Syd, per lager.
      CASE ars.LagStalle
        WHEN '5' THEN 'Anette Tengbom'
        WHEN '0' THEN 'Linda Gren'
        WHEN '8' THEN 'Anette Tengbom'
        WHEN '6' THEN 'Anette Tengbom'
        WHEN '7' THEN 'Anette Tengbom'  -- Add v.4.
      END
  END AS MARC_EKGRP,  -- SAP purchasing group

  'X' AS MARC_KAUTB,  -- SAP auto purchase order
  COALESCE(ar_2000.momskod, 1) AS MARC_TAXIM,  -- SAP purchase tax. AR.momskod (smallint nullable). Change v.5. Change v.6.

  CASE  -- Change v.5.
    WHEN ars.LagBestPkt > 0.0 THEN CAST(ROUND(ars.LagBestPkt, 3) AS varchar(16))  -- decimal(15,6) not nullable as varchar(16)
    ELSE CAST('' AS varchar(16))
    -- Mix decimal and '' in varchar column
  END AS MARC_MINBE,  -- SAP reorder point qty.

  'Ref_MARC_DISMM' AS MARC_DISLS,  -- SAP lot size procedure

  CASE  -- Change v.5.
    WHEN al.minantalbest > 0.0 THEN CAST(ROUND(al.minantalbest, 3) AS varchar(16))  -- decimal(15,6) not nullable as varchar(16)
    ELSE CAST('' AS varchar(16))
    -- Mix decimal and '' in varchar column
  END AS MARC_BSTMI,  -- SAP minimum lot size. May be NULL cus AL outer join.

--  COALESCE(IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), ROUND(ARS.eoq, 3) ), '') AS MARC_BSTFE,  -- SAP fixed lot size. Coalesce for AL outer join. Remove v.5.
  -- Fixed lot size only for reorder-point articles with FX lot size. Must check MRP type; repeat logic above for MARC_DISMM.
  CASE  -- Add v.5.
    -- (1) Från ARS.anskaffningssatt (smallint nullable).
    WHEN ars.anskaffningssatt = 0 AND ars.LagBestPkt > 0.0 THEN  -- Om BP (0) och om BP-qty så BP (0)
      -- Fixed lot size: (1) AL.minantalbest if > 0, else (2) ARS.eoq if > 0, else (3) default 1.
      CASE
        WHEN al.minantalbest > 0.0 THEN CAST(ROUND(al.minantalbest, 3) AS varchar(16))  -- decimal(15,6) as varchar(16)
        ELSE
          CASE
            WHEN ars.eoq > 0.0 THEN CAST(ROUND(ars.eoq, 3) AS varchar(16))  -- decimal(15,6) as varchar(16)
            ELSE CAST(1.000 AS varchar(16))
          END
      END
    WHEN ars.anskaffningssatt = 0 AND NOT ars.LagBestPkt > 0.0 THEN  -- Om BP (0) utan BP-qty så KMB (2)
      CAST('' AS varchar(16))  -- N/A
    WHEN ars.anskaffningssatt IS NOT NULL THEN                       -- KMB (2), etc från ARS.
      CAST('' AS varchar(16))  -- N/A
    -- (2) Från AR.anskaffningssatt (smallint not nullable).
    WHEN ar_op.anskaffningssatt = 0 AND ars.LagBestPkt > 0.0 THEN  -- Om BP (0) och om BP-qty så BP (0)
      -- Fixed lot size: (1) AL.minantalbest if > 0, else (2) ARS.eoq if > 0, else (3) default 1.
      CASE
        WHEN al.minantalbest > 0.0 THEN CAST(ROUND(al.minantalbest, 3) AS varchar(16))  -- decimal(15,6) as varchar(16)
        ELSE
          CASE
            WHEN ars.eoq > 0.0 THEN CAST(ROUND(ars.eoq, 3) AS varchar(16))  -- decimal(15,6) as varchar(16)
            ELSE CAST(1.000 AS varchar(16))
          END
      END
    ELSE CAST('' AS varchar(16))  -- N/A
    -- Mix decimal and '' in varchar column
  END AS MARC_BSTFE,  -- SAP fixed lot size

  CASE  -- Change v.5.
    WHEN al.multipel > 0.0 THEN CAST(ROUND(al.multipel, 3) AS varchar(16))  -- decimal(15,6) not nullable as varchar(16)
    ELSE CAST('' AS varchar(16))
    -- Mix decimal and '' in varchar column
  END AS MARC_BSTRF,  -- SAP rounding value. May be NULL cus AL outer join.

  'Ref_MARC_DISMM' AS MARC_BESKZ,  -- SAP procurement type
  CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARC_LGFSB,  -- SAP storage loc ext procurement

  CASE WHEN ars.LedTid > 0 THEN ars.LedTid ELSE 0 END AS MARC_PLIFZ,  -- SAP planned delivery time. Jeeves Ledtid (smallint not nullable). Change v.5.
  
  'X' AS MARC_PSTATL,  -- Indicator: Storage
  'X' AS MARC_PSTATE,  -- Indicator: Purchasing
  'X' AS MARC_PSTATV,  -- Indicator: Sales

  2 AS MBEW_MLAST,  -- SAP Price Control Determination = Transaction-based.
  3100 AS MBEW_BKLAS,  -- SAP Valuation Class.
  'V' AS MBEW_VPRSV,  -- SAP Price Control = moving average.
  'SEK' AS MBEW_WAERS,  -- SAP Currency
  ROUND(CASE WHEN ars.ArtKalkBer > 0.0 THEN ars.ArtKalkBer ELSE ar_op.ArtKalkBer END, 2) AS MBEW_VERPR,  -- SAP Inventory Price Moving Average
  CAST(ROUND(POWER(10.0, 
    CASE WHEN ars.ArtKalkBer > 0.0 THEN ars.ArtKalkPer ELSE ar_op.ArtKalkPer END
    ), 0) AS int) AS MBEW_PEINH,  -- SAP Price Unit (quantity)
  'X' AS MBEW_PSTATB  -- Indicator: Accounting

FROM
/* Remove v.6.
  ar
  INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
    AND ars.artnr = ar.artnr
  LEFT OUTER JOIN al
    ON al.foretagkod = ar.foretagkod
    AND al.artnr = ar.artnr
    AND al.ArtHuvudAvt = '1'  -- Jeeves: endast huvudavtal (char(1))
*/
-- Add v.6.
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
  (  ( ars.ForetagKod = 6000 AND ars.LagStalle IN ('20', '30', '101', '102') )  -- Öst
  OR ( ars.ForetagKod = 9100 AND ars.LagStalle IN ('5000') )  -- Väst
  OR ( ars.ForetagKod = 9400 AND ars.LagStalle IN ('0', '2', '4', '5', '6') )  -- Norr
  OR ( ars.ForetagKod = 9500 AND ars.LagStalle IN ('0', '5', '6', '7', '8') )  -- Syd
  )
  AND ar_2000.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery. Change v.6.
ORDER BY 2, 3;

-- END