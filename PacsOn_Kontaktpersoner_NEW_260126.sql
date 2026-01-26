SELECT
      kp.ForetagKod
    , kp.FtgNr
    , kp.FtgKontaktNr
    , fr.orgnr
    , fr.ftgnamn
    , fr.ftgpostadr2      -- gata
    , fr.ftgpostnr
    , fr.ftgpostadr3      -- ort

    , MIN(kp.FtgPerson)  AS FtgPerson
    , MIN(kp.avd)        AS Avd
    , MIN(kp.befattkod)  AS BefattKod
    , MIN(kp.ComNr)      AS ComNr
    , MIN(kp.q_kp_default_vid_order) AS q_kp_default_vid_order

    , MAX(CASE WHEN cr.ComKod = 1 THEN cr.ComNr END) AS CR_Telefon
    , MAX(CASE WHEN cr.ComKod = 8 THEN cr.ComNr END) AS CR_Mejl
	  , MAX(CASE WHEN cr.ComKod = 3 THEN cr.ComNr END) AS CR_TelefonPersonlig
    , MAX(CASE WHEN cr.ComKod = 4 THEN cr.ComNr END) AS Telefon_Mobil
	,MAX(CASE WHEN cr.ComKod = 7 THEN cr.ComNr END) AS CR_Mejl_företag
	,MAX(CASE WHEN cr.ComKod = 9 THEN cr.ComNr END) AS CR_Mejl_ECOM

FROM kp
INNER JOIN fr
    ON  fr.ForetagKod = kp.ForetagKod
    AND fr.FtgNr      = kp.FtgNr
    AND fr.q_saps4    = '1'   -- Endast företag som ska exporteras till SAP
LEFT JOIN cr
    ON  cr.ForetagKod    = kp.ForetagKod
    AND cr.FtgNr         = kp.FtgNr
    AND cr.FtgKontaktNr  = kp.FtgKontaktNr
WHERE kp.ForetagKod IN (6000, 9000, 9100, 9400, 9500)   --Alla bolag
GROUP BY
      kp.ForetagKod
    , kp.FtgNr
    , kp.FtgKontaktNr
    , fr.orgnr
    , fr.ftgnamn
    , fr.ftgpostadr2
    , fr.ftgpostnr
    , fr.ftgpostadr3
ORDER BY
      kp.ForetagKod
    , kp.FtgNr
    , kp.FtgKontaktNr;