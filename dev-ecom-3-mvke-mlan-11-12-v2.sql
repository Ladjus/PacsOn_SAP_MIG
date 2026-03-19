-- Ecom articles from Jeeves.
-- Singelartikel, behåller artikelnummer = 11; AI "Variant/produkt" = S Singelartikel utan "kompisar".
-- Singelartikel m PH2, behåller artikelnummer = 12; AI "Variant/produkt" = P Singelartiklar som ska hållas ihop som en produkt i Artikelhierarki 2.

/* Change log
v.2: Item category group MTPOS:
     (a) Om Ordertyp [ar.ordtyp] = 10 "Direktleverans" så CBNA "3rd party SO w/o SN".
     (b) Om Ordertyp [ar.ordtyp] <> 10 och AR-Anskaffningssätt = 0 "BP" så NORM "Standard item".
     (c) Om Ordertyp [ar.ordtyp] <> 10 och AR-Anskaffningssätt = 2 "KMB" så CBUK "Bought-in".
     Must include condition for Anskaffningssätt 0 "BP" to have reorder-point quantity, but this is stored in ARS-table [ars.LagBestPkt]
     so cannot be checked since MVKE-data is on AR-level!
*/

WITH cte_artnr AS (
    SELECT artnr
    FROM ar
    WHERE ForetagKod = 2000   -- Mall
      AND extra4 IN (11, 12)
)
SELECT
    AR.artnr AS AR_ArtNr,                 -- Jeeves "Artikel ID"
    AR.artbeskrspec AS MVKE_PRODUCT,
    AR.ForetagKod AS MVKE_VKORG,          -- SAP sales org
    10 AS MVKE_VTWEG,                     -- SAP distribution channel
    'ABC' AS MVKE_VMSTA,                  -- SAP sales status per assortment
    '2026-01-01' AS MVKE_VMSTD,           -- SAP sales status date
    CASE
        WHEN AR.artfsgforp > 1.0 THEN ROUND(AR.artfsgforp, 3)
        ELSE NULL
    END AS MVKE_AUMNG,                    -- SAP Minimum Order Quantity in Base UoM
    CASE
        WHEN AR.ordtyp = 10 THEN 'CBNA'   -- "3rd party SO w/o SN"
        ELSE
            CASE AR.anskaffningssatt
                WHEN 0 THEN 'NORM'        -- BP. "Standard item"
                WHEN 2 THEN 'CBUK'        -- KMB. "Bought-in"
                ELSE 'NORM'               -- Default
            END
    END AS MVKE_MTPOS,                    -- SAP Item Category Group
    'Z1' AS MVKE_KTGRM                    -- SAP Account Assignment Group
FROM ar AR
WHERE AR.ForetagKod IN (6000, 9100, 9400, 9500)   -- ÖVNS
  AND AR.artnr IN (SELECT artnr FROM cte_artnr)
ORDER BY 2, 3;


-- Sales tax classification. One (1) country for all locations, select from mallbolaget 2000.
-- (If consistency problems, SELECT DISTINCT from operational companies, but then risk of duplicates if inconsistent AR.momskod.)
SELECT
    AR.artnr AS AR_ArtNr,                 -- Jeeves "Artikel ID"
    AR.artbeskrspec AS MLAN_PRODUCT,
    'SE' AS MLAN_ALAND,
    'TTX1' AS MLAN_TATYP1,
    COALESCE(AR.momskod, '') AS MLAN_TAXM1   -- SAP sales tax
FROM ar AR
WHERE AR.ForetagKod = 2000               -- Mall
  AND AR.extra4 IN (11, 12)
ORDER BY 2, 3;

-- END