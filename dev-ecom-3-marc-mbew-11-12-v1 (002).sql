---dev-ecom-3-marc-mbew-11-12-v2.sql

SELECT 
  AR.artnr AS AR_ArtNr,
  AR.artbeskrspec AS MARC_PRODUCT,
  CONCAT(ARS.ForetagKod, '#', LTRIM(RTRIM(ARS.LagStalle))) AS MARC_WERKS,

  CASE ARS.anskaffningssatt
    WHEN 0 THEN IIF(TRY_CONVERT(decimal(18,3), ARS.LagBestPkt) > 0.0, 0, 2)
    ELSE ARS.anskaffningssatt
  END AS MARC_DISMM,

  '#001' AS MARC_DISPO,
  'SR'   AS MARC_MTVFP,
  AR.ForetagKod AS MARC_PRCTR,
  '' AS MARC_XCHPF,
  '#0003' AS MARC_LADGR,

  CASE
    WHEN LEN(COALESCE(ARS.InkHandl, '')) > 0 THEN ARS.InkHandl
    ELSE CONCAT(ARS.ForetagKod, '#', LTRIM(RTRIM(ARS.LagStalle)))
  END AS MARC_EKGRP,

  'X' AS MARC_KAUTB,
  AR.momskod AS MARC_TAXIM,

  TRY_CONVERT(decimal(18,3), ARS.LagBestPkt) AS MARC_MINBE,
  'Ref_MARC_DISMM' AS MARC_DISLS,

  CASE 
    WHEN TRY_CONVERT(decimal(18,3), AL.minantalbest) > 0.0
      THEN ROUND(TRY_CONVERT(decimal(18,3), AL.minantalbest), 3)
    ELSE NULL
  END AS MARC_BSTMI,

  CASE 
    WHEN TRY_CONVERT(decimal(18,3), AL.multipel) > 0.0
      THEN ROUND(TRY_CONVERT(decimal(18,3), AL.multipel), 3)
    ELSE NULL
  END AS MARC_BSTRF,

  'Ref_MARC_DISMM' AS MARC_BESKZ,
  CONCAT(ARS.ForetagKod, '#', LTRIM(RTRIM(ARS.LagStalle))) AS MARC_LGFSB,
  ARS.LedTid AS MARC_PLIFZ,

  'X' AS MARC_PSTATL,
  'X' AS MARC_PSTATE,
  'X' AS MARC_PSTATV

FROM ar
JOIN ARS
  ON ARS.foretagkod = AR.foretagkod
 AND ARS.artnr      = AR.artnr
LEFT JOIN AL
  ON AL.foretagkod  = AR.foretagkod
 AND AL.artnr       = AR.artnr
 AND AL.ArtHuvudAvt = '1'
WHERE
  (
       ( ARS.ForetagKod = 6000 AND LTRIM(RTRIM(ARS.LagStalle)) IN ('20','30','101','102') )
    OR ( ARS.ForetagKod = 9100 AND LTRIM(RTRIM(ARS.LagStalle)) IN ('5000') )
    OR ( ARS.ForetagKod = 9400 AND LTRIM(RTRIM(ARS.LagStalle)) IN ('0','2','4','5','6') )
    OR ( ARS.ForetagKod = 9500 AND LTRIM(RTRIM(ARS.LagStalle)) IN ('0','5','6','7','8') )
  )
  -- OBS: extra4-filter borttaget eftersom din debug visade bara 0/NULL i detta urval
ORDER BY 2, 3;