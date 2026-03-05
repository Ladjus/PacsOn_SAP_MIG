-- Ecom articles from Jeeves.
-- V : Retailvariant
-- V? : Osäker om det kan vara en Retailvariant. Om den inte kan vara en Retailvariant så bör ändå "varianterna" hållas ihop i samma produkt (se P)
SELECT
  AR.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  AR.artbeskrspec AS MARA_PRODUCT,
  'HAWA' AS MARA_MTART,
  'Generic_01' AS MARA_ATTYP,  -- Article category 01 generic article
  CONCAT(AR.artkod, '#', AR.artkat) AS MARA_MATKL,
  LEFT(CONCAT(TRIM(AR.artbeskr), ' ', TRIM(AR.artbeskr2)), 40) AS MARA_MAKTX,  -- Artikelbeskrivning 40 tecken
  'SV' AS MARA_SPRAS,
  AR.enhetskod AS MARA_MEINS,
  -- COALESCE(AR.ArtNrEAN, '') AS MARA_EAN11,  -- !!! AR.ArtNrEAN är död, ta från AREAN !!!
  '#00' AS MARA_SPART,  -- Division 00. # to prevent excel strip leading zero
  CASE
    WHEN LEN(TRIM(COALESCE(AR.q_artnr_pacudo, ''))) > 0 THEN CONCAT('GEN#', TRIM(AR.q_artnr_pacudo))
    ELSE CONCAT('GEN#', AR.artbeskrspec)
  END AS MARA_BISMT,  -- Old mtrl: (1) Pacudo, (2) Jeeves
-- MARA_XCHPF,  -- Batch flag
  COALESCE(AR.q_unspsckod, '') AS MARA_EXTWG,
  'SAMM' AS MARA_MTPOS_MARA,
  AR.itemstatuscode AS MARA_MSTAE,  -- Cross-Plant Product Status
  ''                AS MARA_MSTDE,  -- Valid-From Date
/* No weight, volume for generic article migration
  ROUND(AR.artbtotvikt, 3) AS MARA_BRGEW,
  ROUND(AR.artvikt, 3)     AS MARA_NTGEW,
  'KG' AS MARA_GEWEI,
  ROUND(AR.artvolym, 3) AS MARA_VOLUM,  -- Jeeves "Volym kbm"
  'M3' AS MARA_VOLEH,
*/
  '#0001' AS MARA_TRAGR,  -- Transportation Group: On pallets. # to prevent excel strip leading zero
  ' ' AS MARA_SPROF,  -- Pricing Profile for Variants
  '3100' AS MARA_WBKLA,  -- Reference value: Valuation Class
  AR.momskod AS MARA_TAKLV,  -- Reference value: Tax Classification
  '#0003' AS MARA_WLADG,  -- Reference value: Loading Group
  'EN' AS MAKT_SPRAS,
  LEFT(CONCAT(TRIM(AR.artbeskr), ' ', TRIM(AR.artbeskr2)), 40) AS MAKT_MAKTX
FROM ar
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 IN (11, 12)
ORDER BY 2;

/*
# Source-data-for-Product-dev-wire-7-DE01.xml

## Basic data, structure S_MARA

PRODUCT = WIRE-7
MTART = HAWA
ATTYP = 01
MATKL = DE01
MAKTX = Hook up wire 0.34 mm² 777 m
SPRAS = EN
MEINS = rl
SPART = 00
BISMT = WIRE-7
MTPOS_MARA = SAMM
Weights should be blank (unless same for all variants, but that's impossible to know, so not for migrate articles).
Dimensions should be blank (unless same for all variants, but that's impossible to know, so not for migrate articles).
Volume should be blank (unless same for all variants, but that's impossible to know, so not for migrate articles).
BSTME = krt
TRAGR = 0001
SPROF = ' '  -- SAP Pricing Profile for Variants. Default value 2 "All variants have the sales price of the generic material".
             -- CANNOT load blank value "Variants priceable diff.; do not propose GMaterial as ref." via migration cockpit.
             -- MUST update to blank ' ' after load of global data, before any variants are created, to avoid MARA-PMATA in variant articles.
WBKLA = 3100  -- Valuation class
TAKLV = 1  -- Tax classification
WLADG = 0003  -- Loading group

## Additional descriptions, structure S_MAKT
[...]

## Alternative unit of measure, structure S_MARM
[...]

## Class data, structure S_CLASS

PRODUCT = WIRE-7
CLASS = VARIANTS
CLASSTYPE = 300

## Characteristic data, structure S_CHARACT  -- 4 rows

PRODUCT = WIRE-7
CLASS = VARIANTS
CLASSTYPE = 300
ATNAM = COLOUR
POSNR = 001 / 002 / 003 / 004            -- 4 rows
VALUE_CHAR = RED / BLUE / BLACK / WHITE  -- 4 rows
VALUE_NUMC = VALUE_DATE = VALUE_TIME = VALUE_CURR = '' (empty)

## Value for variants, structure S_VARIANT
(empty)

*/

-- END