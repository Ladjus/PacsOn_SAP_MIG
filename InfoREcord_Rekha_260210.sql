SELECT 
    al.foretagkod   AS 'COMPANY CODE',
    al.artnr        AS 'ARTICLE NUMBER',
    al.ledtid       AS 'LEADTIME',
    al.arthuvudavt  AS 'MAIN AGREEMENT',
    ar1.artbeskr    AS 'ARTICLE DESCRIPTION',
    al.ftgnr        AS 'SUPPLIER ID',
    fr1.ftgnamn     AS 'SUPPLIER NAME',
    al.artnrlev     AS 'SUPPLIER ARTICLE NUMBER',
    al.vb_inpris    AS 'PURCH PRICE',
    al.valkod       AS 'CURRENCY CODE',
	al.enhetskod    AS 'U o M',
	al.minantalbest AS 'MIN QTY BEST'
FROM al
LEFT JOIN (
    SELECT artnr, MAX(artbeskr) AS artbeskr
    FROM ar
    GROUP BY artnr
) ar1
    ON ar1.artnr = al.artnr
LEFT JOIN (
    SELECT ftgnr, MAX(ftgnamn) AS ftgnamn
    FROM fr
    GROUP BY ftgnr
) fr1
    ON fr1.ftgnr = al.ftgnr
WHERE al.foretagkod IN (2000,6000,9100,9400,9500)
order by ars.artnr 

-----------------------
SELECT
    ars.foretagkod   AS 'COMPANY CODE',
    ars.artnr        AS 'ARTICLE NUMBER',
    ars.lagstalle    AS 'STORAGE LOCATION',
    ars.inkhandl     AS 'PURCHASER ID',
    ihdl1.inkhandlbeskr AS 'PURCHASER DESCRIPTION',
    ar1.artbeskr     AS 'ARTICLE DESCRIPTION'
FROM ars
LEFT JOIN (
    SELECT artnr, MAX(artbeskr) AS artbeskr
    FROM ar
    GROUP BY artnr
) ar1
    ON ar1.artnr = ars.artnr
LEFT JOIN (
    SELECT inkhandl, MAX(inkhandlbeskr) AS inkhandlbeskr
    FROM ihdl
    GROUP BY inkhandl
) ihdl1
    ON ihdl1.inkhandl = ars.inkhandl
WHERE ars.foretagkod IN (6000, 9100, 9400, 9500)
ORDER BY ars.artnr;
