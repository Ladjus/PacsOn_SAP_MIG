-- Check MRP parameters from Jeeves
-- Product sample: ecom articles

WITH cte_artnr AS (
    SELECT artnr
    FROM ar
    WHERE
        ForetagKod = 2000  -- Mall
        AND extra4 > 0.0
)
SELECT
    AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
    AR.artbeskrspec AS AR_artbeskrspec,
    AR.artbeskr AS AR_artbeskr,
    AR.artbeskr2 AS AR_artbeskr2,
    AR.enhetskod AS AR_enhetskod,
    CONCAT(ARS.ForetagKod, '#', LTRIM(RTRIM(ARS.LagStalle))) AS MARC_WERKS,  -- SAP plant
    ARS.anskaffningssatt AS ARS_anskaffningssatt,
    AR.anskaffningssatt AS AR_anskaffningssatt,
    ARS.LagBestPkt AS ARS_LagBestPkt,
    CASE
        WHEN ARS.anskaffningssatt = 0 AND ARS.LagBestPkt > 0.0 THEN 'ARS_LagBestPkt > 0'
        ELSE 'ARS_LagBestPkt NOLL'
    END AS ARS_LagBestPkt_NOLL,
    ARS.eoq AS ARS_eoq,

    /*
    CASE  -- Jeeves "Anskaffningssätt". AR|ARS.anskaffningssatt (smallint). ARS.LagBestPkt (decimal(15,6)).
        WHEN ARS.anskaffningssatt = 0 THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)
        WHEN ARS.anskaffningssatt IS NOT NULL THEN ARS.anskaffningssatt
        WHEN AR.anskaffningssatt = 0 THEN IIF(ARS.LagBestPkt > 0.0, 0, 2)
        ELSE AR.anskaffningssatt
    END AS MARC_DISMM,
    */

    -- Dito med läsbar output.
    CASE
        WHEN ARS.anskaffningssatt = 0 THEN IIF(ARS.LagBestPkt > 0.0, 'BP_0', 'KMB_2')
        WHEN ARS.anskaffningssatt = 2 THEN 'KMB_2'
        WHEN ARS.anskaffningssatt IS NOT NULL THEN CONCAT('ARS:', ARS.anskaffningssatt)
        WHEN AR.anskaffningssatt = 0 THEN IIF(ARS.LagBestPkt > 0.0, 'BP_0', 'KMB_2')
        WHEN AR.anskaffningssatt = 2 THEN 'KMB_2'
        ELSE CONCAT('AR_:', AR.anskaffningssatt)
    END AS MARC_DISMM,  -- SAP MRP type

    CASE ARS.ForetagKod
        WHEN 6000 THEN
            CASE ARS.LagStalle
                WHEN '20' THEN 'Åsa Björnskiöld'
                ELSE IIF(ARS.InkHandl = 'EB', 'Erik Bergstedt', 'Tobias Wahlström')
            END
        WHEN 9100 THEN ARS.InkHandl
        WHEN 9400 THEN
            CASE ARS.LagStalle
                WHEN '0' THEN 'Lars Fröberg'
                WHEN '2' THEN 'Eva Östlund'
                WHEN '6' THEN 'Eva Östlund'
                WHEN '4' THEN 'Lars Fröberg'
                WHEN '5' THEN 'Lars Fröberg'
            END
        WHEN 9500 THEN
            CASE ARS.LagStalle
                WHEN '5' THEN 'Anette Tengbom'
                WHEN '0' THEN 'Linda Gren'
                WHEN '8' THEN 'Anette Tengbom'
                WHEN '6' THEN 'Anette Tengbom'
                WHEN '7' THEN 'Anette Tengbom'
            END
    END AS MARC_EKGRP,  -- SAP purchasing group

    'X' AS MARC_KAUTB,  -- SAP auto purchase order
    COALESCE(AR.momskod, '') AS MARC_TAXIM,  -- SAP purchase tax
    ROUND(ARS.LagBestPkt, 3) AS MARC_MINBE,  -- SAP reorder point qty
    IIF(ARS.LedTid > 0, ARS.LedTid, '') AS MARC_PLIFZ,  -- SAP planned delivery time

    -- AL primärnyckel: ForetagKod, ArtNr, InkAvt, ArtLevPrior, FtgNr
    CONCAT(AL.ForetagKod, '#', AL.ArtNr, '#', AL.InkAvt, '#', AL.ArtLevPrior, '#', AL.FtgNr) AS AL_PK,
    AL.enhetskod AS AL_enhetskod,
    AL.arthuvudavt AS AL_arthuvudavt,
    AL.artomvfaktor AS AL_artomvfaktor,
    AL.minantalbest AS AL_minantalbest,
    AL.minantalbestextqty AS AL_minantalbestextqty,
    AL.multipelextqty AS AL_multipelextqty,
    AL.multipel AS AL_multipel,
    AL.stockqty2suppqty AS AL_stockqty2suppqty,

    COALESCE(IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), NULL), NULL) AS MARC_BSTMI,
    COALESCE(IIF(AL.minantalbest > 0.0, ROUND(AL.minantalbest, 3), ROUND(ARS.eoq, 3)), NULL) AS MARC_BSTFE,
    COALESCE(IIF(AL.multipel > 0.0, ROUND(AL.multipel, 3), NULL), NULL) AS MARC_BSTRF

FROM ar
    INNER JOIN ARS
        ON ARS.foretagkod = AR.foretagkod
       AND ARS.artnr = AR.artnr
    LEFT JOIN AL
        ON AL.foretagkod = AR.foretagkod
       AND AL.artnr = AR.artnr
       AND AL.ArtHuvudAvt = '1'  -- Jeeves: endast huvudavtal (char(1))
WHERE
    (
        (ARS.ForetagKod = 6000 AND LTRIM(RTRIM(ARS.LagStalle)) IN ('20', '30', '101', '102'))  -- Öst
        OR (ARS.ForetagKod = 9100 AND LTRIM(RTRIM(ARS.LagStalle)) IN ('5000'))                  -- Väst
        OR (ARS.ForetagKod = 9400 AND LTRIM(RTRIM(ARS.LagStalle)) IN ('0', '2', '4', '5', '6')) -- Norr
        OR (ARS.ForetagKod = 9500 AND LTRIM(RTRIM(ARS.LagStalle)) IN ('0', '5', '6', '7', '8')) -- Syd
    )
    AND AR.artnr IN (
        SELECT artnr
        FROM cte_artnr
    )
ORDER BY 2, 3;

-- END