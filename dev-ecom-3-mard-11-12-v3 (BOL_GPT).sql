-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

-- Change log
-- v.2: Update list of existing storage locations, none missing.
--      Second storage location for 9400#0 Sundsvall: Butik.
-- v.3: Always AR.artbeskrspec from 2000 mallbolaget.
--      Refactor with new CTE cte_mard_base.
--      Add column MARD_RUN_ID.

WITH cte_artnr AS (
    SELECT
        artnr
    FROM ar
    WHERE
        ForetagKod = 2000  -- Mallbolag
        AND extra4 IN (11, 12)
),
cte_mard_base AS (
    SELECT
        ar_2000.artnr AS AR_ArtNr,                    -- Jeeves "Artikel ID"
        ar_2000.artbeskrspec AS MARD_PRODUCT,         -- SAP Product, alltid från 2000 mallbolaget
        CAST(GETDATE() AS date) AS MARD_RUN_ID,       -- Kördatum
        ars.ForetagKod AS ARS_ForetagKod,             -- Bolag
        ars.LagStalle AS ARS_LagStalle,               -- Lagerställe
        CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS  -- SAP plant
    FROM ar AS ar_2000
    INNER JOIN ar AS ar_op
        ON ar_2000.artnr = ar_op.artnr
       AND ar_2000.ForetagKod = 2000                  -- Mallbolag
       AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- Operativa bolag: ÖVNS
    INNER JOIN ars
        ON ars.ForetagKod = ar_op.ForetagKod
       AND ars.artnr = ar_op.artnr
    WHERE
        ar_2000.artnr IN (
            SELECT artnr
            FROM cte_artnr
        )
)

-- One storage location per plant.
SELECT
    AR_ArtNr,
    MARD_PRODUCT,
    MARD_RUN_ID,
    MARD_WERKS,
    MARD_WERKS AS MARD_LGORT  -- SAP storage location
FROM cte_mard_base
WHERE
    (
        (ARS_ForetagKod = 6000 AND ARS_LagStalle IN ('20', '30', '101', '102'))  -- Öst
        OR
        (ARS_ForetagKod = 9100 AND ARS_LagStalle IN ('5000'))                     -- Väst
        OR
        (ARS_ForetagKod = 9400 AND ARS_LagStalle IN ('0', '2', '4', '5', '6'))   -- Norr
        OR
        (ARS_ForetagKod = 9500 AND ARS_LagStalle IN ('0', '5', '6', '7', '8'))   -- Syd
    )

UNION ALL

-- Second storage location for 9400#0 Sundsvall: Butik.
SELECT
    AR_ArtNr,
    MARD_PRODUCT,
    MARD_RUN_ID,
    MARD_WERKS,
    CONCAT(CAST(ARS_ForetagKod AS nvarchar(4)), '#', ARS_LagStalle, 'X') AS MARD_LGORT  -- SAP storage location
FROM cte_mard_base
WHERE
    ARS_ForetagKod = 9400
    AND ARS_LagStalle = '0'  -- Norr Sundsvall

UNION ALL

-- Second storage location for 9500#5 Växjö: Butik.
SELECT
    AR_ArtNr,
    MARD_PRODUCT,
    MARD_RUN_ID,
    MARD_WERKS,
    CONCAT(CAST(ARS_ForetagKod AS nvarchar(4)), '#', ARS_LagStalle, 'X') AS MARD_LGORT  -- SAP storage location
FROM cte_mard_base
WHERE
    ARS_ForetagKod = 9500
    AND ARS_LagStalle = '5'  -- Syd Växjö

ORDER BY
    2, 4, 5;

-- END