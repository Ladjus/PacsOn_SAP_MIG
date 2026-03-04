-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11.
-- Singelartikel m PH2, behåller artikelnummer = 12.

WITH cte_artnr AS (
    SELECT artnr
    FROM ar
    WHERE ForetagKod = 2000
      AND extra4 IN ('11', '12')
)

SELECT
    AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
    AR.artbeskrspec AS MARC_PRODUCT,
    CONCAT(ARS.ForetagKod, '#', TRIM(ARS.LagStalle)) AS MARC_WERKS,  -- SAP plant

    CASE
        WHEN ARS.anskaffningssatt = 0
            THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)
        WHEN ARS.anskaffningssatt IS NULL
            THEN CASE
                    WHEN AR.anskaffningssatt = 0
                        THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)
                    ELSE AR.anskaffningssatt
                 END
        ELSE ARS.anskaffningssatt
    END AS MARC_DISMM,  -- SAP MRP type

    '#001' AS MARC_DISPO,  -- SAP MRP controller
    'SR' AS MARC_MTVFP,  -- SAP availability check
    AR.ForetagKod AS MARC_PRCTR,  -- SAP profit centre
    '' AS MARC_XCHPF,  -- SAP batch management
    '#0003' AS MARC_LADGR,  -- SAP loading group

    CASE ars.ForetagKod
        WHEN 6000 THEN  -- Öst
            CASE ars.LagStalle
                WHEN '20' THEN 'Åsa Björnskiöld'
                ELSE IIF(ars.InkHandl = 'EB', 'Erik Bergstedt', 'Tobias Wahlström')
            END
        WHEN 9100 THEN ars.InkHandl
        WHEN 9400 THEN
            CASE ars.LagStalle
                WHEN '0' THEN 'Lars Fröberg'
                WHEN '2' THEN 'Eva Östlund'
                WHEN '6' THEN 'Eva Östlund'
                WHEN '4' THEN 'Lars Fröberg'
                WHEN '5' THEN 'Lars Fröberg'
            END
        WHEN 9500 THEN
            CASE ars.LagStalle
                WHEN '5' THEN 'Anette Tengbom'
                WHEN '0' THEN 'Linda Gren'
                WHEN '8' THEN 'Anette Tengbom'
                WHEN '6' THEN 'Anette Tengbom'
            END
    END AS MARC_EKGRP,  -- SAP purchasing group

    'X' AS MARC_KAUTB,  -- SAP auto purchase order
    COALESCE(AR.momskod, '') AS MARC_TAXIM,  -- SAP purchase tax
    ROUND(ARS.LagBestPkt, 3) AS MARC_MINBE,  -- SAP reorder point qty
    'Ref_MARC_DISMM' AS MARC_DISLS,  -- SAP lot size procedure

    -- ÄNDRAD: '' -> NULL (numeriska fält)
    COALESCE(IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), NULL), NULL) AS MARC_BSTMI,  -- SAP minimum lot size
    COALESCE(IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), ROUND(ARS.eoq, 3)), NULL) AS MARC_BSTFE,  -- SAP fixed lot size
    COALESCE(IIF(AL.multipel > 0.0, ROUND(AL.multipel, 3), NULL), NULL) AS MARC_BSTRF,  -- SAP rounding value

    'Ref_MARC_DISMM' AS MARC_BESKZ,  -- SAP procurement type
    CONCAT(ARS.ForetagKod, '#', ARS.LagStalle) AS MARC_LGFSB,  -- SAP storage loc ext procurement

    -- ÄNDRAD: '' -> NULL (numeriskt fält)
    IIF(ARS.LedTid > 0, ARS.LedTid, NULL) AS MARC_PLIFZ,  -- SAP planned delivery time

    'X' AS MARC_PSTATL,  -- Indicator: Storage
    'X' AS MARC_PSTATE,  -- Indicator: Purchasing
    'X' AS MARC_PSTATV,  -- Indicator: Sales

    2 AS MBEW_MLAST,  -- Price Control Determination
    3100 AS MBEW_BKLAS,  -- Valuation Class
    'V' AS MBEW_VPRSV,  -- moving average
    'SEK' AS MBEW_WAERS,  -- Currency

    ROUND(IIF(ARS.ArtKalkBer > 0.0, ARS.ArtKalkBer, AR.ArtKalkBer), 2) AS MBEW_VERPR,  -- Moving average price

    -- Fixad TRY_CAST-syntax
    TRY_CAST(
        ROUND(
            POWER(10.0, IIF(ARS.ArtKalkBer > 0.0, ARS.ArtKalkPer, AR.ArtKalkPer)),
            0
        ) AS INT
    ) AS MBEW_PEINH,  -- Price Unit (quantity)

    'X' AS MBEW_PSTATB  -- Indicator: Accounting

FROM ar
INNER JOIN ARS
    ON ARS.foretagkod = AR.foretagkod
   AND ARS.artnr = AR.artnr
LEFT OUTER JOIN AL
    ON AL.foretagkod = AR.foretagkod
   AND AL.artnr = AR.artnr
   AND AL.ArtHuvudAvt = '1'
WHERE
(
    (ARS.ForetagKod = 6000 AND TRIM(ARS.LagStalle) IN ('20', '30', '101', '102'))
 OR (ARS.ForetagKod = 9100 AND TRIM(ARS.LagStalle) IN ('5000'))
 OR (ARS.ForetagKod = 9400 AND TRIM(ARS.LagStalle) IN ('0', '2', '4', '5', '6'))
 OR (ARS.ForetagKod = 9500 AND TRIM(ARS.LagStalle) IN ('0', '5', '6', '7', '8'))
)
AND AR.artnr IN (SELECT artnr FROM cte_artnr)
ORDER BY 2, 3;