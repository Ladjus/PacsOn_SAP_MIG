-- Ecom articles from Jeeves.

-- (1) "Product hierarchy version" tab, structure S_ASSIGN
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  'ART01' AS ASSIGNMENT_HIER_ID,  -- Hierarchy ID
  '9999-12-31' AS ASSIGNMENT_VER_VLDTO,  -- Valid to
  ar.artbeskrspec AS ASSIGNMENT_RUN_ID  -- Run ID, separate per article.
FROM ar
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 > 0.0  -- Mig-flag set
ORDER BY 4;  -- ASSIGNMENT_RUN_ID

-- (2) "Product assignment" tab, structure S_ASSIGN_PRODUCT
SELECT
  ar.artnr AS AR_ArtNr,  -- Jeeves "Artikel ID"
  'ART01' AS ASSIGN_PROD_HIER_ID,  -- Hierarchy ID
  '9999-12-31' AS ASSIGN_PROD_VER_VLDTO,  -- Valid to
  ar.artbeskrspec AS ASSIGN_PROD_RUN_ID,  -- Run ID, separate per article.
  ar.artbeskrspec AS ASSIGN_PROD_NODE_VALUE,  -- SAP Product. What about cross-reference???
  CONCAT(AR.artkod, '#', AR.artkat) AS ASSIGN_PROD_PARENT_NODE_VALUE  -- SAP Subnode. Jeeves Artikelklass # Artikelkategori.
FROM ar
WHERE
  ar.foretagkod in (2000)  -- Mall
  AND ar.extra4 > 0.0  -- Mig-flag set
ORDER BY 4;  -- ASSIGN_PROD_RUN_ID

-- END