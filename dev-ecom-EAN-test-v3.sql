-- Test v.2 to get EAN-codes with row-number per article and unit of measure.
-- ROW_NUMBER() per article and unit for sequential number.
-- ROW_NUMBER() = 1: Primary EAN per unit.
-- ROW_NUMBER() > 1: Secondary EAN per unit.

/* Change log
v.2: Only EAN with length 13 or 14 (GTIN-13 & GTIN-14), rest presumed to be junk, ref CB 2026-04-15.
     Test subsets (a), (b), (c). Union should equal first query.
v.3: Rewrite, more CTE and various fixes.
*/

-- 1. Alla EAN med RN per artikel + enhet
WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
),
cte_ean AS (  -- EAN for all units.
  SELECT
    ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
    ar.artbeskrspec AS MEAN_PRODUCT,  -- SAP Product. Jeeves "Artikelnr"
    COALESCE(arean.AltEnhetKod, ar.EnhetsKod, 'ERROR') AS MEAN_MEINH,  -- SAP unit. Jeeves AltEnhetKod nullable (basenhet); EnhetsKod not nullable.
    CAST(TRIM(arean.ArtNrEAN) AS varchar(18)) AS MEAN_EAN11  -- SAP GTIN char(18). Jeeves nvarchar(60) not nullable.
  FROM ar
    INNER JOIN arean
      ON ar.foretagkod = arean.foretagkod
     AND ar.artnr = arean.artnr
  WHERE
    ar.foretagkod = 2000  -- Mall
    AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
    AND LEN(TRIM(arean.ArtNrEAN)) BETWEEN 13 AND 14  -- Only GTIN-13 & GTIN-14, rest is junk. Add v.2.
),
cte_ean_rn AS (  -- ROW_NUMBER() AS RN
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY AR_ArtNr, MEAN_MEINH
      ORDER BY MEAN_EAN11
    ) AS RN
  FROM cte_ean
)
SELECT
  AR_ArtNr,
  MEAN_PRODUCT,
  MEAN_MEINH,
  MEAN_EAN11,
  RN
FROM cte_ean_rn
ORDER BY MEAN_PRODUCT, MEAN_MEINH, RN;

-- (a) EAN för basenhet (ej alt-enhet), primär RN = 1, för MARA-GTIN
WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
),
cte_ean_bu AS (  -- EAN for base units (not alt-units).
  SELECT
    ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
    ar.artbeskrspec AS MEAN_PRODUCT,  -- SAP Product. Jeeves "Artikelnr"
    COALESCE(arean.AltEnhetKod, ar.EnhetsKod, 'ERROR') AS MEAN_MEINH,  -- SAP unit. Jeeves AltEnhetKod nullable (basenhet); EnhetsKod not nullable.
    CAST(TRIM(arean.ArtNrEAN) AS varchar(18)) AS MEAN_EAN11  -- SAP GTIN char(18). Jeeves nvarchar(60) not nullable.
  FROM ar
    INNER JOIN arean
      ON ar.foretagkod = arean.foretagkod
     AND ar.artnr = arean.artnr
     AND arean.AltEnhetKod IS NULL  -- Basenhet
  WHERE
    ar.foretagkod = 2000  -- Mall
    AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
    AND LEN(TRIM(arean.ArtNrEAN)) BETWEEN 13 AND 14  -- Only GTIN-13 & GTIN-14, rest is junk. Add v.2.
),
cte_ean_bu_rn AS (  -- ROW_NUMBER() AS RN
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY AR_ArtNr, MEAN_MEINH
      ORDER BY MEAN_EAN11
    ) AS RN
  FROM cte_ean_bu
)
SELECT
  AR_ArtNr,
  MEAN_PRODUCT,
  MEAN_MEINH,
  MEAN_EAN11,
  RN
FROM cte_ean_bu_rn
WHERE RN = 1  -- Primär GTIN
ORDER BY MEAN_PRODUCT, MEAN_MEINH, RN;

-- (b) EAN för alt-enhet (ej basenhet), primär RN = 1, för MARM-GTIN
WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
),
cte_ean_au AS (  -- EAN for alt-units (not base unit).
  SELECT
    ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
    ar.artbeskrspec AS MEAN_PRODUCT,  -- SAP Product. Jeeves "Artikelnr"
    COALESCE(arean.AltEnhetKod, ar.EnhetsKod, 'ERROR') AS MEAN_MEINH,  -- SAP unit. Jeeves AltEnhetKod nullable (basenhet); EnhetsKod not nullable.
    CAST(TRIM(arean.ArtNrEAN) AS varchar(18)) AS MEAN_EAN11  -- SAP GTIN char(18). Jeeves nvarchar(60) not nullable.
  FROM ar
    INNER JOIN arean
      ON ar.foretagkod = arean.foretagkod
     AND ar.artnr = arean.artnr
     AND arean.AltEnhetKod <> ar.EnhetsKod  -- Alternativ enhet
  WHERE
    ar.foretagkod = 2000  -- Mall
    AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
    AND LEN(TRIM(arean.ArtNrEAN)) BETWEEN 13 AND 14  -- Only GTIN-13 & GTIN-14, rest is junk. Add v.2.
),
cte_ean_au_rn AS (  -- ROW_NUMBER() AS RN
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY AR_ArtNr, MEAN_MEINH
      ORDER BY MEAN_EAN11
    ) AS RN
  FROM cte_ean_au
)
SELECT
  AR_ArtNr,
  MEAN_PRODUCT,
  MEAN_MEINH,
  MEAN_EAN11,
  RN
FROM cte_ean_au_rn
WHERE RN = 1  -- Primär GTIN
ORDER BY MEAN_PRODUCT, MEAN_MEINH, RN;

-- (c) EAN för basenhet och altenhet, sekundär RN > 1, för MEAN-GTIN
WITH cte_artnr AS (
  SELECT artnr
  FROM ar
  WHERE
    ForetagKod = 2000  -- Mall
    AND extra4 IN (11, 12)
),
cte_ean AS (  -- EAN for all units.
  SELECT
    ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
    ar.artbeskrspec AS MEAN_PRODUCT,  -- SAP Product. Jeeves "Artikelnr"
    COALESCE(arean.AltEnhetKod, ar.EnhetsKod, 'ERROR') AS MEAN_MEINH,  -- SAP unit. Jeeves AltEnhetKod nullable (basenhet); EnhetsKod not nullable.
    CAST(TRIM(arean.ArtNrEAN) AS varchar(18)) AS MEAN_EAN11  -- SAP GTIN char(18). Jeeves nvarchar(60) not nullable.
  FROM ar
    INNER JOIN arean
      ON ar.foretagkod = arean.foretagkod
     AND ar.artnr = arean.artnr
  WHERE
    ar.foretagkod = 2000  -- Mall
    AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
    AND LEN(TRIM(arean.ArtNrEAN)) BETWEEN 13 AND 14  -- Only GTIN-13 & GTIN-14, rest is junk. Add v.2.
),
cte_ean_rn AS (  -- ROW_NUMBER() AS RN
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY AR_ArtNr, MEAN_MEINH
      ORDER BY MEAN_EAN11
    ) AS RN
  FROM cte_ean
)
SELECT
  AR_ArtNr,
  MEAN_PRODUCT,
  MEAN_MEINH,
  MEAN_EAN11,
  RN
FROM cte_ean_rn
WHERE RN > 1
ORDER BY MEAN_PRODUCT, MEAN_MEINH, RN;

-- END