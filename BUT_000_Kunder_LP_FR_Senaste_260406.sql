WITH FR_BASE AS (
    SELECT *
    FROM FR
    WHERE FR.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
      AND FR.q_saps4 = '1'
),
KUS_1 AS (
    SELECT *
    FROM (
        SELECT
            KUS.*,
            ROW_NUMBER() OVER (
                PARTITION BY KUS.ForetagKod, KUS.FtgNr
                ORDER BY KUS.FtgNr
            ) AS rn
        FROM KUS
    ) x
    WHERE x.rn = 1
),
LE_1 AS (
    SELECT *
    FROM (
        SELECT
            LE.*,
            ROW_NUMBER() OVER (
                PARTITION BY LE.ForetagKod, LE.FtgNr
                ORDER BY LE.FtgNr
            ) AS rn
        FROM LE
    ) x
    WHERE x.rn = 1
),
LP_1 AS (
    SELECT *
    FROM (
        SELECT
            LP.*,
            ROW_NUMBER() OVER (
                PARTITION BY LP.ForetagKod, LP.FtgNr
                ORDER BY LP.FtgNr
            ) AS rn
        FROM LP
    ) x
    WHERE x.rn = 1
),
SALJ_1 AS (
    SELECT *
    FROM (
        SELECT
            SALJ.*,
            ROW_NUMBER() OVER (
                PARTITION BY SALJ.ForetagKod, SALJ.saljare
                ORDER BY SALJ.saljare
            ) AS rn
        FROM SALJ
    ) x
    WHERE x.rn = 1
),
X2_1 AS (
    SELECT *
    FROM (
        SELECT
            X2.*,
            ROW_NUMBER() OVER (
                PARTITION BY X2.ForetagKod, X2.BetKod
                ORDER BY X2.BetKod
            ) AS rn
        FROM X2
    ) x
    WHERE x.rn = 1
),
X2E_1 AS (
    SELECT *
    FROM (
        SELECT
            X2E.*,
            ROW_NUMBER() OVER (
                PARTITION BY X2E.ForetagKod, X2E.levvillkkod
                ORDER BY X2E.levvillkkod
            ) AS rn
        FROM X2E
    ) x
    WHERE x.rn = 1
),
XN2_1 AS (
    SELECT *
    FROM (
        SELECT
            XN2.*,
            ROW_NUMBER() OVER (
                PARTITION BY XN2.blockregion
                ORDER BY XN2.blockregion
            ) AS rn
        FROM XN2
    ) x
    WHERE x.rn = 1
)

SELECT
    CONCAT(FR.FtgNr, '#', FR.ForetagKod) AS KUNNR_LIFNR,
    CASE
        WHEN KUS.FtgNr IS NOT NULL THEN 'CUST'
        WHEN EXISTS (
            SELECT 1
            FROM LP
            WHERE LP.ForetagKod = FR.ForetagKod
              AND LP.OrdLevPlats1 = FR.FtgNr
        ) THEN 'SHPT'
        ELSE ''
    END AS KTOKD,
    COALESCE(NULLIF(KUS.makulerad, ''), '') AS KUS_MAK,
    CASE
        WHEN LE.FtgNr IS NOT NULL THEN 'SUPL'
        ELSE ''
    END AS KTOKK,
    COALESCE(NULLIF(LE.makulerad, ''), '') AS LE_MAK,
    COALESCE(NULLIF(FR.ftgnamn, ''), '') AS NAMORG1,
    COALESCE(NULLIF(FR.ftgpostadr1, ''), '') AS NAMORG2,
    COALESCE(NULLIF(FR.ftgpostadr5, ''), '') AS FTGPOSTADR5,
    COALESCE(NULLIF(FR.comnr, ''), '') AS SORTL,
    CASE
        WHEN NULLIF(FR.orgnr, '') IS NULL THEN ''
        WHEN FR.landskod = 'SE' THEN REPLACE(FR.orgnr, '-', '')
        ELSE FR.orgnr
    END AS FR_orgnr,
    COALESCE(NULLIF(FR.eumomsnr, ''), '') AS FR_eumomsnr,
    COALESCE(NULLIF(FR.ean_loc_code, ''), '') AS FR_EAN_LOC_CODE,
    COALESCE(NULLIF(FR.ftglevpostnr, ''), '') AS FR_FTGLEVPOSTNR,
    COALESCE(NULLIF(FR.ftgpostlevadr3, ''), '') AS FR_FTGPOSTLEVADR3,
    ADR.STREET,
    ADR.POST_CODE1,
    ADR.CITY1,
    ADR.PO_BOX,
    ADR.POST_CODE2,
    ADR.PO_BOX_LOC,
    COALESCE(NULLIF(FR.landskod, ''), '') AS COUNTRY,
    CASE WHEN LEN(FR.ean_loc_code) = 13 THEN LEFT(FR.ean_loc_code, 7) ELSE '' END AS LOCATION_1,
    CASE WHEN LEN(FR.ean_loc_code) = 13 THEN SUBSTRING(FR.ean_loc_code, 8, 5) ELSE '' END AS LOCATION_2,
    CASE WHEN LEN(FR.ean_loc_code) = 13 THEN RIGHT(FR.ean_loc_code, 1) ELSE '' END AS LOCATION_3,
    CONCAT(FR.ftgnr, '#', FR.foretagkod) AS BPEXT,
    COALESCE(NULLIF(FR.landskod, ''), '') AS LANGU_CORR,
    CASE WHEN NULLIF(FR.webadress, '') IS NOT NULL THEN 'HPG' ELSE '' END AS URI_TYP,
    COALESCE(NULLIF(FR.webadress, ''), '') AS URI_ADDR,
    COALESCE(NULLIF(KUS.q_buyer_code, ''), '') AS YY1_CUSTOMERNUMBERFF_CUS,
    COALESCE(NULLIF(KUS.kundklass, ''), '') AS KUS_KUNDKLASS,
    COALESCE(NULLIF(KUS.lagstalle, ''), '') AS KUS_LAGSTALLE,
    COALESCE(NULLIF(KUS.betkod, ''), '') AS KUS_BETKOD,
    COALESCE(NULLIF(KUS.dellevtillaten, ''), '') AS KUS_DELLEVTILLATEN,
    COALESCE(NULLIF(KUS.restbehkod, ''), '') AS KUS_RESTBEHKOD,
    COALESCE(NULLIF(KUS.q_fakt_per, ''), '') AS KUS_FAKT_PER,
    COALESCE(NULLIF(KUS.q_fakt_efaktura_pdf, ''), '') AS KUS_FAKT_EFAKTURA_PDF,
    COALESCE(NULLIF(KUS.samfaktutskr, ''), '') AS KUS_SAMFAKTUTSKR,
    CASE
        WHEN NULLIF(KUS.betkod, '') IS NOT NULL THEN COALESCE(NULLIF(X2.betvillbeskr, ''), '')
        ELSE ''
    END AS KUS_BETVILL_BESKR,
    COALESCE(NULLIF(KUS.levvillkkod, ''), '') AS KUS_LEVVILLK,
    CASE
        WHEN NULLIF(KUS.levvillkkod, '') IS NOT NULL THEN COALESCE(NULLIF(X2E.levvillkbeskr, ''), '')
        ELSE ''
    END AS KUS_LEVVILLK_BESKR,
    COALESCE(NULLIF(FR.blockregion, ''), '') AS FR_BLOCKREGION,
    CASE
        WHEN NULLIF(FR.blockregion, '') IS NOT NULL THEN COALESCE(NULLIF(XN2.regionbeskr, ''), '')
        ELSE ''
    END AS FR_BLOCKREGION_BESKR,
    CASE
        WHEN KUS.saljare IS NOT NULL THEN CONCAT(KUS.saljare, ' ', COALESCE(NULLIF(SALJ.saljarenamn, ''), ''))
        ELSE ''
    END AS KUS_SALJARE,

    -- Nya fält
    COALESCE(NULLIF(KUS.edit, ''), '') AS KUS_EDIT,
    COALESCE(NULLIF(KUS.godsmarke1, ''), '') AS KUS_GODSMARKE1,
    COALESCE(NULLIF(KUS.godsmarke2, ''), '') AS KUS_GODSMARKE2,
    COALESCE(NULLIF(FR.ftgopenhrs, ''), '') AS FR_FTGOPENHRS,
    COALESCE(NULLIF(LP.q_jis_ordlevanvrad1, ''), '') AS LP_Q_JIS_ORDLEVANVRAD1,
    COALESCE(NULLIF(LP.q_jis_ordlevanvrad2, ''), '') AS LP_Q_JIS_ORDLEVANVRAD2

FROM FR_BASE FR
LEFT OUTER JOIN KUS_1 KUS
    ON KUS.ForetagKod = FR.ForetagKod
   AND KUS.FtgNr = FR.FtgNr
LEFT OUTER JOIN LE_1 LE
    ON LE.ForetagKod = FR.ForetagKod
   AND LE.FtgNr = FR.FtgNr
LEFT OUTER JOIN LP_1 LP
    ON LP.ForetagKod = FR.ForetagKod
   AND LP.FtgNr = FR.FtgNr
LEFT OUTER JOIN SALJ_1 SALJ
    ON SALJ.ForetagKod = KUS.ForetagKod
   AND SALJ.saljare = KUS.saljare
LEFT OUTER JOIN X2_1 X2
    ON X2.ForetagKod = KUS.ForetagKod
   AND X2.BetKod = KUS.betkod
LEFT OUTER JOIN X2E_1 X2E
    ON X2E.ForetagKod = KUS.ForetagKod
   AND X2E.levvillkkod = KUS.levvillkkod
LEFT OUTER JOIN XN2_1 XN2
    ON XN2.blockregion = FR.blockregion
OUTER APPLY (
    SELECT
        CASE
            WHEN UPPER(LEFT(LTRIM(RTRIM(COALESCE(FR.ftgpostadr2, ''))), 3)) = 'BOX' THEN 1
            ELSE 0
        END AS IsBox
) F
OUTER APPLY (
    SELECT
        CASE
            WHEN F.IsBox = 0 THEN COALESCE(NULLIF(FR.ftgpostadr2, ''), '')
            WHEN F.IsBox = 1 AND FR.ftgpostadr5 IS NOT NULL THEN COALESCE(NULLIF(FR.ftgpostadr5, ''), '')
            WHEN F.IsBox = 1 AND FR.ftgpostadr4 IS NOT NULL THEN COALESCE(NULLIF(FR.ftgpostadr4, ''), '')
            WHEN FR.ftgpostadr2 IS NULL AND FR.ftgpostadr5 IS NOT NULL THEN COALESCE(NULLIF(FR.ftgpostadr5, ''), '')
            ELSE ''
        END AS STREET,
        CASE
            WHEN F.IsBox = 0 THEN
                CASE
                    WHEN FR.landskod = 'SE' AND LEN(FR.ftgpostnr) = 6 THEN COALESCE(NULLIF(FR.ftgpostnr, ''), '')
                    WHEN FR.landskod = 'SE' AND LEN(FR.ftgpostnr) = 5 THEN CONCAT(LEFT(FR.ftgpostnr, 3), ' ', RIGHT(FR.ftgpostnr, 2))
                    ELSE COALESCE(NULLIF(FR.ftgpostnr, ''), '')
                END
            WHEN F.IsBox = 1 AND FR.ftgpostadr5 IS NOT NULL THEN COALESCE(NULLIF(FR.ftglevpostnr, ''), '')
            WHEN F.IsBox = 1 AND FR.ftgpostadr4 IS NOT NULL THEN COALESCE(NULLIF(FR.ftgbespostnr, ''), '')
            WHEN FR.ftgpostadr2 IS NULL AND FR.ftgpostadr5 IS NOT NULL THEN COALESCE(NULLIF(FR.ftglevpostnr, ''), '')
            ELSE ''
        END AS POST_CODE1,
        CASE
            WHEN F.IsBox = 0 THEN COALESCE(NULLIF(FR.ftgpostadr3, ''), '')
            WHEN F.IsBox = 1 AND FR.ftgpostadr5 IS NOT NULL THEN COALESCE(NULLIF(FR.ftgpostlevadr3, ''), '')
            WHEN F.IsBox = 1 AND FR.ftgpostadr4 IS NOT NULL THEN COALESCE(NULLIF(FR.ftgpostbesadr3, ''), '')
            WHEN FR.ftgpostadr2 IS NULL AND FR.ftgpostadr5 IS NOT NULL THEN COALESCE(NULLIF(FR.ftgpostlevadr3, ''), '')
            ELSE ''
        END AS CITY1,
        CASE
            WHEN F.IsBox = 1 THEN COALESCE(NULLIF(FR.ftgpostadr2, ''), '')
            ELSE ''
        END AS PO_BOX,
        CASE
            WHEN F.IsBox = 1 THEN COALESCE(NULLIF(FR.ftgpostnr, ''), '')
            ELSE ''
        END AS POST_CODE2,
        CASE
            WHEN F.IsBox = 1 THEN COALESCE(NULLIF(FR.ftgpostadr3, ''), '')
            ELSE ''
        END AS PO_BOX_LOC
) ADR
ORDER BY 1;