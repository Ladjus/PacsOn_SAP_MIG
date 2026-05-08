-- Jeeves extract article data.
-- !!!PacsOn Väst 9100 only!!!
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.1: Inital version. Select only A-assortment plus B/C for PacsOn Väst. Refer:
     dev-ecom-3-mvke-mlan-11-12-v6.sql
     jea-99-sortiment-bc-9100-v1.sql
     Column MARC_RUN_ID use fixed value 'WEST'. Problem w date is that same article may get multiple records with different dates, then it's a mess.
     Column MVKE_VMSTA from ar.q_saps4_sortiment
     Column MVKE_VMSTD per ar.q_saps4_sortiment
     
*/

-- Sales data (load structure S_MVKE)
WITH cte_artnr_west AS (
  SELECT ar_2000.artnr
  FROM ar AS ar_2000
    LEFT OUTER JOIN ar AS ar_9100
      ON ar_2000.artnr = ar_9100.artnr
      AND ar_9100.ForetagKod = 9100  -- Väst
  WHERE
    ar_2000.ForetagKod = 2000  -- Mall
    AND ar_2000.extra4 IN (11, 12)
    AND (ar_2000.q_saps4_sortiment NOT IN ('B', 'C')  -- Ej B/C-sortiment: alla artiklar.
         OR (ar_2000.q_saps4_sortiment IN ('B', 'C') AND ar_9100.artnr IS NOT NULL))  -- B/C-sortiment: endast artiklar som finns i Väst 9100.
)
SELECT
  ar_2000.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar_2000.artbeskrspec AS MARC_PRODUCT,  -- SAP Product. Jeeves "Artikelnr"
--  CAST(GETDATE() AS date) AS MVKE_RUN_ID,  -- Remove v.1.
  'WEST' AS MVKE_RUN_ID,  -- Add v.1.
  ar_op.ForetagKod AS MVKE_VKORG,  -- SAP sales org
  10 AS MVKE_VTWEG,  -- SAP distribution channel
  COALESCE(ar_2000.q_saps4_sortiment ,'') AS MVKE_VMSTA,  -- SAP sales status per assortment. Change v.1.
  CASE WHEN ar_2000.q_saps4_sortiment IS NOT NULL THEN CAST(GETDATE() AS date) END
    AS MVKE_VMSTD,  -- SAP sales status date. Change v.1.

  CASE ar_op.anskaffningssatt
    WHEN 0 THEN  -- Beställningspunkt (0) ==> tag Förpackningsstorlek försäljning [ar_op.artfsgforp].
      CASE
        WHEN ar_op.artfsgforp > 0.0 AND ar_op.artfsgforp <> 1.0 AND FLOOR(ar_op.artfsgforp) = CEILING(ar_op.artfsgforp)  -- If meaningful integer value.
          THEN CAST(CAST(ar_op.artfsgforp AS int) AS varchar(16))  -- integer as varchar(16).
        WHEN ar_op.artfsgforp > 0.0 THEN CAST(ROUND(ar_op.artfsgforp, 3) AS varchar(16))  -- decimal(15,6) as varchar(16).
        ELSE CAST('' AS varchar(16))
        -- Mix integer, decimal and '' in varchar column
      END
    WHEN 2 THEN  -- Köp mot behov (2) ==> tag Förpackningsstorlek förs ansk [ar_op.q_artfsgforp].
      CASE
        WHEN ar_op.q_artfsgforp > 0.0 AND ar_op.q_artfsgforp <> 1.0 AND FLOOR(ar_op.q_artfsgforp) = CEILING(ar_op.q_artfsgforp)  -- If meaningful integer value.
          THEN CAST(CAST(ar_op.q_artfsgforp AS int) AS varchar(16))  -- integer as varchar(16).
        WHEN ar_op.q_artfsgforp > 0.0 THEN CAST(ROUND(ar_op.q_artfsgforp, 3) AS varchar(16))  -- decimal(15,6) as varchar(16).
        ELSE CAST('' AS varchar(16))
        -- Mix integer, decimal and '' in varchar column
      END
    ELSE CAST('' AS varchar(16))
  END AS MVKE_AUMNG,  -- SAP Minimum Order Quantity in Base UoM

  CASE
    WHEN ar_op.ordtyp = 10 THEN 'CBNA'  -- "3rd party SO w/o SN".
    ELSE  -- ar_op.ordtyp <> 10
      CASE ar_op.anskaffningssatt  -- (smallint not nullable)
        WHEN 0 THEN 'NORM'  -- BP. "Standard item".
        WHEN 2 THEN 'CBUK'  -- KMB. "Bought-in".
        ELSE 'NORM'  -- Default: "Standard item".
      END
  END AS MVKE_MTPOS,  -- SAP Item Category Group

  'Z1' AS MVKE_KTGRM  -- SAP Account Assignment Group
FROM
  ar AS ar_2000  -- Mall
  INNER JOIN ar AS ar_op  -- Operativa bolag
    ON ar_2000.artnr = ar_op.artnr
    AND ar_2000.ForetagKod = 2000
--  AND ar_op.ForetagKod IN (6000, 9100, 9400, 9500)  -- ÖVNS. Remove v.1.
    AND ar_op.ForetagKod IN (9100)  -- Väst. Add v.1.
WHERE
  ar_2000.artnr IN (SELECT artnr FROM cte_artnr_west)  -- AR.extra4 subquery. Change v.1
ORDER BY 2, 3;

-- Sales tax classification (load structure S_MLAN). One (1) country for all locations, select from mallbolaget 2000.
-- (If consistency problems, SELECT DISTINCT from operational companies, but then risk of duplicates if inconsistent AR.momskod.)
WITH cte_artnr_west AS (
  SELECT ar_2000.artnr
  FROM ar AS ar_2000
    LEFT OUTER JOIN ar AS ar_9100
      ON ar_2000.artnr = ar_9100.artnr
      AND ar_9100.ForetagKod = 9100  -- Väst
  WHERE
    ar_2000.ForetagKod = 2000  -- Mall
    AND ar_2000.extra4 IN (11, 12)
    AND (ar_2000.q_saps4_sortiment NOT IN ('B', 'C')  -- Ej B/C-sortiment: alla artiklar.
         OR (ar_2000.q_saps4_sortiment IN ('B', 'C') AND ar_9100.artnr IS NOT NULL))  -- B/C-sortiment: endast artiklar som finns i Väst 9100.
)
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  ar.artbeskrspec AS MLAN_PRODUCT,  -- SAP Product
  'SE' AS MLAN_ALAND,
  'TTX1' AS MLAN_TATYP1,
  COALESCE(ar.momskod, 1) AS MLAN_TAXM1  -- SAP sales tax. AR.momskod (smallint nullable)
FROM ar
WHERE
  ForetagKod = 2000  -- Mall
  AND ar.artnr IN (SELECT artnr FROM cte_artnr_west)  -- AR.extra4 subquery. Change v.1
ORDER BY 2, 3;

-- END