-- Jeeves extract article data.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.1: Initial version. Merge 3 query for global data MARA (basic data), MARM (alt-units), MEAN (2nd-GTIN) in one SQL-file since the Jeeves data for this is in one (1) table, so extract must be taken at once to enconsistent and taken at once. Refer:
     dev-ecom-2-mara-makt-11-12-v4.sql
     dev-ecom-2-marm-11-12-v7.sql
     dev-ecom-2-mean-11-12-v2.sql
     dev-ecom-EAN-test-v3.sql
     Column MARA_XCHPF from ar.q_livsmedelgodkand.
*/

-- Query 1/3
-- Grunddata (obligatoriskt) / Basic Data (mandatory) [S_MARA]
-- Ytterligare beskrivningar / Additional Descriptions [S_MAKT]
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
    AND LEN(TRIM(arean.ArtNrEAN)) BETWEEN 13 AND 14  -- Only GTIN-13 & GTIN-14, rest is junk.
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
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS MARA_PRODUCT,  -- SAP Product. Jeeves "Artikelnr"
  'HAWA' AS MARA_MTART,  -- SAP Product type
  'Single_00' AS MARA_ATTYP,  -- Article category 00 single article
  CONCAT(ar.artkod, '#', ar.artkat) AS MARA_MATKL,
  LEFT(CONCAT(TRIM(ar.artbeskr), ' ', TRIM(ar.artbeskr2)), 40) AS MARA_MAKTX,  -- Artikelbeskrivning 40 tecken
  'EN' AS MARA_SPRAS,
  ar.enhetskod AS MARA_MEINS,
  cte_ean_bu_rn.MEAN_EAN11 AS MARA_EAN11,  -- SAP GTIN, 1:a för basenhet. (AR.ArtNrEAN är död.)
  'Std_00' AS MARA_SPART,  -- SAP Division
  CASE
    WHEN LEN(TRIM(COALESCE(ar.q_artnr_pacudo, ''))) > 0 THEN TRIM(ar.q_artnr_pacudo)
    ELSE ar.artbeskrspec
  END AS MARA_BISMT,  -- SAP Old mtrl: (1) Pacudo, (2) Jeeves
  CASE ar.q_livsmedelgodkand WHEN '1' THEN 'X' ELSE '' END AS MARA_XCHPF,  -- SAP Batch Management Required
  COALESCE(ar.q_unspsckod, '') AS MARA_EXTWG,  -- SAP External product group
  'NORM' AS MARA_MTPOS_MARA,
  ar.itemstatuscode AS MARA_MSTAE,  -- Cross-Plant Product Status
  ''                AS MARA_MSTDE,  -- Valid-From Date
  CAST(ROUND(
    CASE
      WHEN ar.artbtotvikt > 0.0 THEN ar.artbtotvikt  -- decimal(15,4) not nullable
      WHEN ar.artvikt > 0.0 THEN ar.artvikt  -- decimal(15,4) not nullable
      ELSE 0.0
    END, 3) AS decimal(14,3))
    AS MARA_BRGEW,  -- SAP BU gross weight, decimal(15,4) as decimal(14,3). Change v.4.
  CAST(ROUND(CASE WHEN ar.artvikt > 0.0 THEN ar.artvikt ELSE 0.0 END, 3) AS decimal(14,3))
    AS MARA_NTGEW,  -- SAP BU net weight, decimal(15,4) as decimal(14,3). Change v.4.
  'KG' AS MARA_GEWEI,  -- SAP weight unit
  ROUND(ar.artvolym, 3) AS MARA_VOLUM,  -- Jeeves "Volym kbm" (float)
  'M3' AS MARA_VOLEH,  -- SAP volume unit
  'Standard_0001' AS MARA_TRAGR,  -- SAP Transportation Group
  ar.q_saps4_sortiment AS MARA_MSTAV,  -- SAP Cross-Distribution Chain Product Status
  CAST(GETDATE() AS date) AS MARA_MSTDV,  -- SAP Valid From Date for Status
  '3100' AS MARA_WBKLA,  -- Reference value: Valuation Class
  COALESCE(ar.momskod, 1) AS MARA_TAKLV,  -- Reference value: Tax Classification.
  'Manual_0003' AS MARA_WLADG,  -- Reference value: Loading Group
  'SV' AS MAKT_SPRAS,
  LEFT(CONCAT(TRIM(AR.artbeskr), ' ', TRIM(AR.artbeskr2)), 40) AS MAKT_MAKTX  -- Artikelbeskrivning 40 tecken
FROM ar
  LEFT OUTER JOIN cte_ean_bu_rn
    ON ar.artnr = cte_ean_bu_rn.AR_ArtNr
    AND cte_ean_bu_rn.RN = 1  -- Primär GTIN för basenhet
WHERE
  ar.foretagkod = 2000  -- Mall
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2;

-- Query 2/3
-- Alternativa mängdenheter / Alternative Units of Measure [S_MARM]
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
    AND LEN(TRIM(arean.ArtNrEAN)) BETWEEN 13 AND 14  -- Only GTIN-13 & GTIN-14, rest is junk.
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
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.enhetskod AS AR_EnhetsKod,  -- Jeeves basenhet
  ar.artbeskrspec AS MARM_PRODUCT,  -- SAP Product. Jeeves "Artikelnr"
  xare.AltEnhetKod AS MARM_MEINH,  -- Alternative Unit of Measure
  1 AS MARM_UMREN,  -- Denominator for Conversion to Base Unit
  CASE
    WHEN FLOOR(xare.AltEnhetOmrFaktor) = CEILING(xare.AltEnhetOmrFaktor)  -- If integer value
      THEN CAST(CAST(xare.AltEnhetOmrFaktor AS int) AS varchar(13))  -- integer as varchar(13)
    ELSE CAST(xare.AltEnhetOmrFaktor AS varchar(13))  -- decimal(12,6) as varchar(13)
    -- Mix integer and decimal in varchar column.
  END AS MARM_UMREZ,  -- Numerator for Conversion to Base Unit
  CASE
    WHEN xare.AltEnhetOmrFaktor >= 100000.0 THEN 'OVERFLOW'  -- SAP maximum 5 digits!
    WHEN NOT(FLOOR(xare.AltEnhetOmrFaktor) = CEILING(xare.AltEnhetOmrFaktor)) THEN 'DECIMAL'  -- SAP fractions must be with UMREN <> 1!
    ELSE ''
  END AS SAP_ERROR,  -- Problem i SAP S/4!
  cte_ean_au_rn.MEAN_EAN11 AS MARM_EAN11,  -- SAP GTIN, 1:a för alt-enhet.
  CAST(ROUND(xare.AltEnhetOmrFaktor *  -- decimal(12,6) nullable
    CASE
      WHEN ar.artbtotvikt > 0.0 THEN ar.artbtotvikt  -- decimal(15,4) not nullable
      WHEN ar.artvikt > 0.0 THEN ar.artvikt  -- decimal(15,4) not nullable
      ELSE 0.0
    END, 3) AS decimal(14,3))
    AS MARM_BRGEW,  -- SAP alt-unit gross weight, as decimal(14,3)
  'KG' AS MARM_GEWEI,  -- SAP weight unit
  'M3' AS MARM_VOLEH  -- SAP volume unit
FROM
  ar
  INNER JOIN xare
    ON ar.foretagkod = xare.foretagkod
    AND ar.artnr = xare.artnr
  LEFT OUTER JOIN cte_ean_au_rn
    ON ar.artnr = cte_ean_au_rn.AR_ArtNr
    AND cte_ean_au_rn.RN = 1  -- Primär GTIN för alternativ enhet
WHERE
  ar.foretagkod = 2000  -- Mall
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
  AND xare.AltEnhetKod <> ar.enhetskod  -- Exclude base-unit of measure.
  AND xare.AltEnhetKod <> 'fpall'  -- Exclude fpall "fraktpall".
  AND xare.AltEnhetKod <> 'vol'  -- Exclude vol (junk).
ORDER BY 3, 4;

-- Query 3/3
-- Ytterligare GTIN / Additional GTINs [S_MEAN]
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
    COALESCE(arean.AltEnhetKod, ar.EnhetsKod, 'ERROR') AS MEAN_MEINH,  -- SAP unit. Jeeves AltEnhetKod nullable (basenhet); EnhetsKod not nullable.
    CAST(TRIM(arean.ArtNrEAN) AS varchar(18)) AS MEAN_EAN11  -- SAP GTIN char(18). Jeeves nvarchar(60) not nullable.
  FROM ar
    INNER JOIN arean
      ON ar.foretagkod = arean.foretagkod
     AND ar.artnr = arean.artnr
  WHERE
    ar.foretagkod = 2000  -- Mall
    AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
    AND LEN(TRIM(arean.ArtNrEAN)) BETWEEN 13 AND 14  -- Only GTIN-13 & GTIN-14, rest is junk.
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
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS MEAN_PRODUCT,  -- SAP Product. Jeeves "Artikelnr"
  cte_ean_rn.MEAN_MEINH,  -- SAP unit
  cte_ean_rn.MEAN_EAN11,  -- SAP GTIN, 2:a för basenhet och alt-enhet.
  cte_ean_rn.RN AS INFO_RN
FROM ar
  INNER JOIN cte_ean_rn
    ON ar.artnr = cte_ean_rn.AR_ArtNr
    AND cte_ean_rn.RN > 1  -- Sekundär GTIN för bas- och alternativ enhet
WHERE
  ar.foretagkod = 2000  -- Mall
  AND ar.artnr IN (SELECT artnr FROM cte_artnr)  -- AR.extra4 subquery.
ORDER BY 2, 3, 4;

-- END