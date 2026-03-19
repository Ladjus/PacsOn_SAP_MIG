-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.5: Column MARC_MINBE as type varchar(16).
     Column MARC_BSTMI as type varchar(16).
*/

WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
)
SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MARC_PRODUCT,
  CONCAT(CAST(ARS.ForetagKod AS nvarchar(4)), '#', TRIM(ARS.LagStalle)) AS MARC_WERKS,  -- SAP plant

  CASE  -- Jeeves "Anskaffningssätt". ARS.LagBestPkt (decimal(15,6)).
    -- (1) Från ARS.anskaffningssatt (smallint nullable).
    WHEN ars.anskaffningssatt = 0 AND ars.LagBestPkt > 0.0 THEN 0  -- Om BP (0) och om BP-qty så BP (0)
    WHEN ars.anskaffningssatt = 0 AND NOT ars.LagBestPkt > 0.0 THEN 2  -- Om BP (0) utan BP-qty så KMB (2)
--  WHEN ARS.anskaffningssatt = 0 THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)  -- Om BP (0) och om BP-qty ARS.LagBestPkt (decimal(15,6)) > 0.0 så BP (0), annars KMB (2).
    WHEN ars.anskaffningssatt IS NOT NULL THEN ars.anskaffningssatt  -- KMB (2), etc från ARS.
    -- (2) Från AR.anskaffningssatt (smallint not nullable).
    WHEN ar.anskaffningssatt = 0 AND ars.LagBestPkt > 0.0 THEN 0  -- Om BP (0) och om BP-qty så BP (0)
    WHEN ar.anskaffningssatt = 0 AND NOT ars.LagBestPkt > 0.0 THEN 2  -- Om BP (0) utan BP-qty så KMB (2)
--  WHEN AR.anskaffningssatt = 0 THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)  -- Om BP (0) och om BP-qty ARS.LagBestPkt (decimal(15,6)) > 0.0 så BP (0), annars KMB (2).
    ELSE ar.anskaffningssatt  -- KMB (2), etc från AR.
  END AS MARC_DISMM,  -- SAP MRP type

  '#001' AS MARC_DISPO,  -- SAP MRP controller
  'SR' AS MARC_MTVFP,  -- SAP availability check
  AR.ForetagKod AS MARC_PRCTR,  -- SAP profit centre
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
--  COALESCE(ar.momskod, '') AS MARC_TAXIM,  -- SAP purchase tax. Remove v.5.
  COALESCE(ar.momskod, 1) AS MARC_TAXIM,  -- SAP purchase tax. AR.momskod (smallint nullable). Add v.5.

  -- ROUND(ARS.LagBestPkt, 3) AS MARC_MINBE,  -- SAP reorder point qty. ARS.LagBestPkt (decimal(15,6) not nullable). Remove v.5.
  CASE
    WHEN ars.LagBestPkt > 0.0 THEN CAST(ROUND(ars.LagBestPkt, 3) AS varchar(16))  -- decimal(15,6) not nullable as varchar(16)
    ELSE CAST('' AS varchar(16))
    -- Mix decimal and '' in varchar column
  END AS MARC_MINBE,  -- SAP reorder point qty. Add v.5.

  'Ref_MARC_DISMM' AS MARC_DISLS,  -- SAP lot size procedure
  
--  COALESCE(IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), ''), '') AS MARC_BSTMI,  -- SAP minimum lot size. Coalesce for AL outer join. Remove v.5.
  CASE  -- Add v.5.
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
    WHEN ar.anskaffningssatt = 0 AND ars.LagBestPkt > 0.0 THEN  -- Om BP (0) och om BP-qty så BP (0)
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

  --  COALESCE(IIF(AL.multipel > 0.0, ROUND(AL.multipel, 3), ''), '') AS MARC_BSTRF,  -- SAP rounding value. Coalesce for AL outer join. Remove v.5.
  CASE  -- Add v.5.
    WHEN al.multipel > 0.0 THEN CAST(ROUND(al.multipel, 3) AS varchar(16))  -- decimal(15,6) not nullable as varchar(16)
    ELSE CAST('' AS varchar(16))
    -- Mix decimal and '' in varchar column
  END AS MARC_BSTRF,  -- SAP rounding value. May be NULL cus AL outer join.

  'Ref_MARC_DISMM' AS MARC_BESKZ,  -- SAP procurement type
  CONCAT(CAST(ARS.ForetagKod AS nvarchar(4)), '#', TRIM(ARS.LagStalle)) AS MARC_LGFSB,  -- SAP storage loc ext procurement
  
--  IIF(ARS.LedTid > 0, ARS.LedTid, '') AS MARC_PLIFZ,  -- SAP planned delivery time. Jeeves Ledtid (smallint). Remove v.5.
  CASE WHEN ars.LedTid > 0 THEN ars.LedTid ELSE 0 END AS MARC_PLIFZ,  -- SAP planned delivery time. Jeeves Ledtid (smallint not nullable). Add v.5.
  
  'X' AS MARC_PSTATL,  -- Indicator: Storage
  'X' AS MARC_PSTATE,  -- Indicator: Purchasing
  'X' AS MARC_PSTATV,  -- Indicator: Sales

  2 AS MBEW_MLAST,  -- SAP Price Control Determination = Transaction-based.
  3100 AS MBEW_BKLAS,  -- SAP Valuation Class.
  'V' AS MBEW_VPRSV,  -- SAP Price Control = moving average.
  'SEK' AS MBEW_WAERS,  -- SAP Currency
  ROUND(IIF(ARS.ArtKalkBer > 0.0, ARS.ArtKalkBer, AR.ArtKalkBer), 2) AS MBEW_VERPR,  -- SAP Inventory Price Moving Average
  CAST(ROUND(POWER(10.0, 
    CASE WHEN ars.ArtKalkBer > 0.0 THEN ars.ArtKalkPer ELSE ar.ArtKalkPer END
    ), 0) AS int) AS MBEW_PEINH,  -- SAP Price Unit (quantity)
  'X' AS MBEW_PSTATB  -- Indicator: Accounting

FROM ar
  INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
    AND ars.artnr = ar.artnr
  LEFT JOIN al
    ON al.foretagkod = ar.foretagkod
    AND al.artnr = ar.artnr
    AND al.ArtHuvudAvt = '1'  -- Jeeves: endast huvudavtal (char(1))
WHERE
  -- Specifika lager: ARS.ForetagKod (smallint) och ARS.LagStalle (char)
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  (
       (ars.ForetagKod = 6000 AND ars.LagStalle IN ('20', '30', '101', '102'))  -- Öst
    OR (ars.ForetagKod = 9100 AND ars.LagStalle IN ('5000'))                     -- Väst
    OR (ars.ForetagKod = 9400 AND ars.LagStalle IN ('0', '2', '4', '5', '6'))   -- Norr
    OR (ars.ForetagKod = 9500 AND ars.LagStalle IN ('0', '5', '6', '7', '8'))   -- Syd
  )
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2, 3;

-- END