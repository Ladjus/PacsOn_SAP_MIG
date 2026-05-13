-- Jeeves extract article data.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/*
3 * SELECT, one per load-file tab:
(1) Tab "Header": structure S_CLF_MAT_KSSK_HEAD.
(2) Tab "Numerical Value Allocation": structure S_CLF_MAT_AUSP_NUM.
(3) Tab "Character Value Allocation": structure S_CLF_MAT_AUSP_CHAR.
*/

/* Change log
v.1: Initial version. Refer:
     dev-ecom-2-class-art-ref-11-12-v2.sql
*/

-- (1) "Header" w structure S_CLF_MAT_KSSK_HEAD
-- Class ART_REF: Article References
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  '#001' AS KSSK_KLART,  -- Class type. # to prevent excel strip leading zero
  'ART_REF' AS KSSK_CLASSNUM,  -- Class name
  ar.artbeskrspec AS KSSK_PRODUCT,
  '1' AS KSSK_STATU  -- Classification status
FROM ar
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
ORDER BY 2, 3, 4;

-- (2) "Numerical Value Allocation" w structure S_CLF_MAT_AUSP_NUM
-- Characteristic ECC_MATNR "ECC Material Nr [MARA.MATNR]"
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  '#001' AS AUSP_NUM_KLART,  -- Class type. # to prevent excel strip leading zero
  'ART_REF' AS AUSP_NUM_CLASSNUM,  -- Class name
  ar.artbeskrspec AS AUSP_NUM_PRODUCT,
  'ECC_MATNR' AS AUSP_NUM_CHARACT,  -- Characteristic name
  '_001' AS AUSP_NUM_POSNR,  -- Item number. _ to prevent excel strip leading zero, remove _ in load-xml.
  ar.q_artnr_pacudo AS AUSP_NUM_ATFLV  -- Numerical Value - From (Floating Point)
FROM ar
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
  AND ar.q_artnr_pacudo IS NOT NULL
ORDER BY 2, 3, 4, 5;

-- (3) "Character Value Allocation" w structure S_CLF_MAT_AUSP_CHAR
-- (3.a) Characteristic JEEVES_ART_ID "Jeeves Artikel ID [AR.artnr]"
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  '#001' AS AUSP_CHAR_KLART,  -- Class type. # to prevent excel strip leading zero
  'ART_REF' AS AUSP_CHAR_CLASSNUM,  -- Class name
  ar.artbeskrspec AS AUSP_CHAR_PRODUCT,
  'JEEVES_ART_ID' AS AUSP_CHAR_CHARACT,  -- Characteristic name
  '_001' AS AUSP_CHAR_POSNR,  -- Item number. _ to prevent excel strip leading zero, remove _ in load-xml.
  ar.artnr AS AUSP_CHAR_ATFLV  -- Characteristic Value Neutral Long
FROM ar
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
  AND ar.artnr IS NOT NULL -- Consistency, should not happen.

UNION ALL  -- Disjoint datasets, different AUSP_NUM_CHARACT, no duplicates.

-- (3.b) Characteristic JEEVES_ART_NR "Jeeves Artikelnr [AR.artbeskrs"
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  '#001' AS AUSP_CHAR_KLART,  -- Class type. # to prevent excel strip leading zero
  'ART_REF' AS AUSP_CHAR_CLASSNUM,  -- Class name
  ar.artbeskrspec AS AUSP_CHAR_PRODUCT,
  'JEEVES_ART_NR' AS AUSP_CHAR_CHARACT,  -- Characteristic name
  '_001' AS AUSP_CHAR_POSNR,  -- Item number. _ to prevent excel strip leading zero, remove _ in load-xml.
  ar.artbeskrspec AS AUSP_CHAR_ATFLV  -- Characteristic Value Neutral Long
FROM ar
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
  AND ar.artbeskrspec IS NOT NULL  -- Consistency, should not happen.

UNION ALL  -- Disjoint datasets, different AUSP_NUM_CHARACT, no duplicates.

-- (3.c) Characteristic JEEVES_ART_PACUDO "Jeeves Pacudo ArtNr [AR.q_artn"
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  '#001' AS AUSP_CHAR_KLART,  -- Class type. # to prevent excel strip leading zero
  'ART_REF' AS AUSP_CHAR_CLASSNUM,  -- Class name
  ar.artbeskrspec AS AUSP_CHAR_PRODUCT,
  'JEEVES_ART_PACUDO' AS AUSP_CHAR_CHARACT,  -- Characteristic name
  '_001' AS AUSP_CHAR_POSNR,  -- Item number. _ to prevent excel strip leading zero, remove _ in load-xml.
  ar.q_artnr_pacudo AS AUSP_CHAR_ATFLV  -- Characteristic Value Neutral Long
FROM ar
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
  AND ar.q_artnr_pacudo IS NOT NULL  -- May happen.

ORDER BY 2, 3, 4, 5;

-- END