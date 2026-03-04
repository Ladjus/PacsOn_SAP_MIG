-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.
SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MARC_PRODUCT,
  CONCAT(ARS.ForetagKod, '#', ARS.LagStalle) AS MARC_WERKS,  -- SAP plant

  -- COALESCE(ARS.anskaffningssatt, AR.anskaffningssatt, '') AS MARC_DISMM,  -- SAP MRP type
  CASE ARS.anskaffningssatt  -- Jeeves "Anskaffningssätt" (smallint)
    WHEN 0 THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)  -- BP (0) om BP-qty finnes, annars KMB (2).
    WHEN NULL THEN
      CASE AR.anskaffningssatt
        WHEN 0 THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)  -- BP (0) om BP-qty finnes, annars KMB (2).
        ELSE AR.anskaffningssatt  -- KMB (2), etc.
      END
    ELSE ARS.anskaffningssatt  -- KMB (2), etc.
  END AS MARC_DISMM,  -- SAP MRP type

  '#001' AS MARC_DISPO,  -- SAP MRP controller
  'SR' AS MARC_MTVFP,  -- SAP availability check
  AR.ForetagKod AS MARC_PRCTR,  -- SAP profit centre
  '' AS MARC_XCHPF,  -- SAP batch management
  '#0003' AS MARC_LADGR,  -- SAP loading group

  CASE
    WHEN LEN(COALESCE(ARS.InkHandl, '') > 0 THEN ARS.InkHandl  -- When not null and not ''.
    ELSE CONCAT(ARS.ForetagKod, '#', ARS.LagStalle)  -- Fallback: default per plant.
  END AS MARC_EKGRP,  -- SAP purchasing group

  'X' AS MARC_KAUTB,  -- SAP auto purchase order
  AR.momskod AS MARC_TAXIM,  -- SAP purchase tax
  ARS.LagBestPkt AS MARC_MINBE,  -- SAP reorder point qty
  'Ref_MARC_DISMM' AS MARC_DISLS,  -- SAP lot size procedure
  
  IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), '') AS MARC_BSTMI,  -- SAP minimum lot size
  -- ???????????????????????????????????????????????????  AS MARC_BSTFE,  -- SAP fixed lot size
  IIF(AL.multipel > 0.0, ROUND(AL.multipel, 3), '') AS MARC_BSTRF,  -- SAP rounding value
  
  'Ref_MARC_DISMM' AS MARC_BESKZ,  -- SAP procurement type
  CONCAT(ARS.ForetagKod, '#', ARS.LagStalle) AS MARC_LGFSB,  -- SAP storage loc ext procurement
  ARS.LedTid AS MARC_PLIFZ,  -- SAP planned delivery time
  
  'X' AS MARC_PSTATL,  -- Indicator: Storage
  'X' AS MARC_PSTATE,  -- Indicator: Purchasing
  'X' AS MARC_PSTATV,  -- Indicator: Sales

FROM ar
  INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
    AND ARS.artnr = AR.artnr
  OUTER JOIN AL
    ON AL.foretagkod = AR.foretagkod
    AND AL.artnr = AR.artnr
    AND AL.ArtHuvudAvt = '1'  -- Jeeves: endast huvudavtal (char)
WHERE
  -- Specifika lager: ARS.ForetagKod (smallint) och ARS.LagStalle (char)
  -- Ref: "PacsOn Org structure_Final_2.xlsx" URL https://optigroup.sharepoint.com/sites/ASAP-Projektplats/Shared%20Documents/ASAP-%20Projektplats/Arkitektur%20&%20Teknisk%20upps%C3%A4ttning/Org.%20struktur/Pacson%20Org%20structure_Final_2.xlsx
  ( ( AR.ForetagKod = 6000 AND ARS.LagStalle IN ('20', '30', '101', '102') )  -- Öst
    OR
    ( AR.ForetagKod = 9100 AND ARS.LagStalle IN ('5000') )  -- Väst
    OR
    ( AR.ForetagKod = 9400 AND ARS.LagStalle IN ('0', '2', '4', '5', '6') )  -- Norr
    OR
    ( AR.ForetagKod = 9500 AND ARS.LagStalle IN ('0', '5', '6', '7', '8') )  -- Syd
  )
  AND ar.extra4 IN (11, 12)
ORDER BY 2, 3;

-- END