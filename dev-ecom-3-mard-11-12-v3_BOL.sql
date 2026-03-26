WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000
    AND extra4 IN (11, 12)
),
cte_mard_base AS (
  SELECT
    ar_2000.artnr AS AR_ArtNr,
    ar_2000.artbeskrspec AS MARD_PRODUCT,
    CAST(GETDATE() AS date) AS MARD_RUN_ID,
    ars.ForetagKod,
    ars.LagStalle,
    CONCAT(CAST(ars.ForetagKod AS nvarchar(4)), '#', ars.LagStalle) AS MARD_WERKS
  FROM
    ar AS ar_2000
    INNER JOIN ar AS ar_op
      ON ar_2000.artnr = ar_op.artnr
      AND ar_2000.ForetagKod = 2000
      AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)
    INNER JOIN ars
      ON ars.foretagkod = ar_op.foretagkod
      AND ars.artnr = ar_op.artnr
  WHERE
    ar_2000.artnr IN (SELECT artnr FROM cte_artnr)
)

SELECT
  AR_ArtNr,
  MARD_PRODUCT,
  MARD_RUN_ID,
  MARD_WERKS,
  MARD_WERKS AS MARD_LGORT
FROM
  cte_mard_base
WHERE
  (  (ForetagKod = 6000 AND LagStalle IN ('20', '30', '101', '102'))
  OR (ForetagKod = 9100 AND LagStalle IN ('5000'))
  OR (ForetagKod = 9400 AND LagStalle IN ('0', '2', '4', '5', '6'))
  OR (ForetagKod = 9500 AND LagStalle IN ('0', '5', '6', '7', '8'))
  )

UNION ALL

SELECT
  AR_ArtNr,
  MARD_PRODUCT,
  MARD_RUN_ID,
  MARD_WERKS,
  CONCAT(MARD_WERKS, 'X') AS MARD_LGORT
FROM
  cte_mard_base
WHERE
  ForetagKod = 9400 AND LagStalle = '0'

UNION ALL

SELECT
  AR_ArtNr,
  MARD_PRODUCT,
  MARD_RUN_ID,
  MARD_WERKS,
  CONCAT(MARD_WERKS, 'X') AS MARD_LGORT
FROM
  cte_mard_base
WHERE
  ForetagKod = 9500 AND LagStalle = '5'

ORDER BY 2, 4, 5;