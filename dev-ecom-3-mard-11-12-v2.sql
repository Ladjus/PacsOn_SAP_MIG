WITH cte_artnr AS (
    SELECT artnr
    FROM ar
    WHERE ForetagKod = 2000
      AND extra4 IN (11, 12)
)

-- One storage location per plant.
SELECT
    ar.artnr AS AR_ArtNr,                  -- Jeeves "Artikel ID"
    ar.artbeskrspec AS MARD_PRODUCT,
    CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS,  -- SAP plant
    CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_LGORT   -- SAP storage location
FROM ar
INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
   AND ars.artnr = ar.artnr
WHERE
    (
        (ars.ForetagKod = 6000 AND ars.LagStalle IN ('20', '30', '101', '102'))  -- Öst
        OR (ars.ForetagKod = 9100 AND ars.LagStalle IN ('5000'))                  -- Väst
        OR (ars.ForetagKod = 9400 AND ars.LagStalle IN ('0', '2', '4', '5', '6')) -- Norr
        OR (ars.ForetagKod = 9500 AND ars.LagStalle IN ('0', '5', '6', '7', '8')) -- Syd
    )
    AND ar.artnr IN (SELECT artnr FROM cte_artnr)

UNION ALL

-- Second storage location for 9400#0 Sundsvall: Butik.
SELECT
    ar.artnr AS AR_ArtNr,
    ar.artbeskrspec AS MARD_PRODUCT,
    CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS,
    CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle, 'X') AS MARD_LGORT
FROM ar
INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
   AND ars.artnr = ar.artnr
WHERE ars.ForetagKod = 9400
  AND ars.LagStalle = '0'
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)

UNION ALL

-- Second storage location for 9500#5 Växjö: Butik.
SELECT
    ar.artnr AS AR_ArtNr,
    ar.artbeskrspec AS MARD_PRODUCT,
    CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS,
    CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle, 'X') AS MARD_LGORT
FROM ar
INNER JOIN ars
    ON ars.foretagkod = ar.foretagkod
   AND ars.artnr = ar.artnr
WHERE ars.ForetagKod = 9500
  AND ars.LagStalle = '5'
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)

ORDER BY 2, 3, 4;