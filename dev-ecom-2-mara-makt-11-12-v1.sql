SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MARA_PRODUCT,
  'HAWA' AS MARA_MTART,
  '#00' AS MARA_ATTYP,  -- Article category 00 single article. # to prevent excel strip leading zero
  CONCAT(AR.artkod, '#', AR.artkat) AS MARA_MATKL,

  LEFT(CONCAT(TRIM(AR.artbeskr), ' ', TRIM(AR.artbeskr2)), 40) AS MARA_MAKTX,

  'SV' AS MARA_SPRAS,
  AR.enhetskod AS MARA_MEINS,
  COALESCE(AR.ArtNrEAN, '') AS MARA_EAN11,
  '#00' AS MARA_SPART,  -- Division 00. # to prevent excel strip leading zero

  CASE
    WHEN LEN(TRIM(COALESCE(AR.q_artnr_pacudo, ''))) > 0 THEN TRIM(AR.q_artnr_pacudo)
    ELSE AR.artbeskrspec
  END AS MARA_BISMT,  -- Old mtrl: (1) Pacudo, (2) Jeeves

  COALESCE(AR.q_unspsckod, '') AS MARA_EXTWG,
  'NORM' AS MARA_MTPOS_MARA,
  AR.itemstatuscode AS MARA_MSTAE,  -- Cross-Plant Product Status
  '' AS MARA_MSTDE,  -- Valid-From Date

  ROUND(AR.artbtotvikt, 3) AS MARA_BRGEW,
  ROUND(AR.artvikt, 3) AS MARA_NTGEW,
  'KG' AS MARA_GEWEI,
  ROUND(AR.artvolym, 3) AS MARA_VOLUM,
  'M3' AS MARA_VOLEH,

  '#0001' AS MARA_TRAGR,  -- Transportation Group
  '3100' AS MARA_WBKLA,  -- Valuation Class
  AR.momskod AS MARA_TAKLV,
  '#0003' AS MARA_WLADG,

  'EN' AS MAKT_SPRAS,

  LEFT(CONCAT(TRIM(AR.artbeskr), ' ', TRIM(AR.artbeskr2)), 40) AS MAKT_MAKTX

FROM ar
WHERE
  ar.foretagkod IN (2000)
  AND ar.extra4 IN (11, 12)

ORDER BY 2;
