-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.
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
  CONCAT(CAST(ARS.ForetagKod AS nvarchar(4), '#', TRIM(ARS.LagStalle)) AS MARC_WERKS,  -- SAP plant

  CASE  -- Jeeves "Anskaffningssätt". ARS.LagBestPkt (decimal(15,6)).
    -- (1) Från ARS.anskaffningssatt (smallint).
    WHEN ARS.anskaffningssatt = 0 THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)  -- Om BP (0) och om BP-qty ARS.LagBestPkt (decimal(15,6)) > 0.0 så BP (0), annars KMB (2).
    WHEN ARS.anskaffningssatt IS NOT NULL THEN ARS.anskaffningssatt  -- KMB (2), etc.
    -- (2) Från AR.anskaffningssatt (smallint).
    WHEN AR.anskaffningssatt  = 0 THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)  -- Om BP (0) och om BP-qty ARS.LagBestPkt (decimal(15,6)) > 0.0 så BP (0), annars KMB (2).
    ELSE AR.anskaffningssatt  -- KMB (2), etc.
  END AS MARC_DISMM,  -- SAP MRP type

  '#001' AS MARC_DISPO,  -- SAP MRP controller
  'SR' AS MARC_MTVFP,  -- SAP availability check
  AR.ForetagKod AS MARC_PRCTR,  -- SAP profit centre
  '' AS MARC_XCHPF,  -- SAP batch management
  '#0003' AS MARC_LADGR,  -- SAP loading group

  CASE ars.ForetagKod
    WHEN 6000 THEN  -- Öst
      CASE ars.LagStalle
        WHEN '20' THEN 'Åsa Björnskiöld'  -- Jordbro: Åsa.
        ELSE IIF(ars.InkHandl = 'EB', 'Erik Bergstedt', 'Tobias Wahlström')
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
  COALESCE(AR.momskod, '') AS MARC_TAXIM,  -- SAP purchase tax
  ROUND(ARS.LagBestPkt, 3) AS MARC_MINBE,  -- SAP reorder point qty. ARS.LagBestPkt (decimal(15,6) not nullable).
  'Ref_MARC_DISMM' AS MARC_DISLS,  -- SAP lot size procedure
  
  COALESCE(IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), ''), '') AS MARC_BSTMI,  -- SAP minimum lot size. Coalesce for AL outer join.
/*
  CASE
    WHEN AL.minantalbest IS NULL THEN ''  -- Check NULL since AL outer join.
    WHEN AL.minantalbest > 0.0 THEN TRY_CAST(ROUND(AL.minantalbest, 3), nvarchar)
    ELSE ''
  END AS MARC_BSTMI,  -- SAP minimum lot size.
*/
  COALESCE(IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), ROUND(ARS.eoq, 3) ), '') AS MARC_BSTFE,  -- SAP fixed lot size. Coalesce for AL outer join.
  COALESCE(IIF(AL.multipel > 0.0, ROUND(AL.multipel, 3), ''), '') AS MARC_BSTRF,  -- SAP rounding value. Coalesce for AL outer join.
  
  'Ref_MARC_DISMM' AS MARC_BESKZ,  -- SAP procurement type
  CONCAT(CAST(ARS.ForetagKod AS nvarchar(4), '#', ARS.LagStalle) AS MARC_LGFSB,  -- SAP storage loc ext procurement
  IIF(ARS.LedTid > 0, ARS.LedTid, '') AS MARC_PLIFZ,  -- SAP planned delivery time. Jeeves Ledtid (smallint)
  
  'X' AS MARC_PSTATL,  -- Indicator: Storage
  'X' AS MARC_PSTATE,  -- Indicator: Purchasing
  'X' AS MARC_PSTATV,  -- Indicator: Sales

  2 AS MBEW_MLAST,  -- SAP Price Control Determination = Transaction-based.
  3100 AS MBEW_BKLAS,  -- SAP Valuation Class.
  'V' AS MBEW_VPRSV,  -- SAP Price Control = moving average.
  'SEK' AS MBEW_WAERS,  -- SAP Currency
  ROUND(IIF(ARS.ArtKalkBer > 0.0, ARS.ArtKalkBer, AR.ArtKalkBer), 2) AS MBEW_VERPR,  -- SAP Inventory Price Moving Average
  TRY_CAST(ROUND(POWER(10.0, 
    CASE WHEN ARS.ArtKalkBer > 0.0 THEN ARS.ArtKalkPer ELSE AR.ArtKalkPer END
    ), 0) AS INT) AS MBEW_PEINH,  -- SAP Price Unit (quantity)
  'X' AS MBEW_PSTATB  -- Indicator: Accounting

FROM ar
  INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
    AND ARS.artnr = AR.artnr
  OUTER JOIN AL
    ON AL.foretagkod = AR.foretagkod
    AND AL.artnr = AR.artnr
    AND AL.ArtHuvudAvt = '1'  -- Jeeves: endast huvudavtal (char(1))
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