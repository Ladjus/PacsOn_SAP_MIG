SELECT kp.ForetagKod
	,kp.FtgNr
	,kp.FtgKontaktNr
	,MIN(kp.FtgPerson) AS FtgPerson
	,MIN(kp.avd) AS Avd
	,MIN(kp.befattkod) AS BefattKod  --Ska BefattKod eller BefattBeskr exporteras?
	,MIN(kp.ComNr) AS ComNr
	,MIN(kp.q_kp_default_vid_order) AS q_kp_default_vid_order
	,MAX(CASE 
			WHEN cr.ComKod = 1
				THEN cr.ComNr
			END) AS CR_Telefon
	,MAX(CASE 
			WHEN cr.ComKod = 8
				THEN cr.ComNr
			END) AS CR_Mejl
FROM kp
LEFT JOIN cr ON cr.ForetagKod = kp.ForetagKod
	AND cr.FtgNr = kp.FtgNr
	AND cr.FtgKontaktNr = kp.FtgKontaktNr
WHERE kp.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
	AND EXISTS (
		SELECT kp.ForetagKod
			,kp.FtgNr
		
		INTERSECT
		
		SELECT ForetagKod
			,FtgNr
		FROM fr
		WHERE fr.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
			AND fr.q_saps4 = '1'  --Endast företag som ska exporteras till SAP
		)
GROUP BY kp.ForetagKod
	,kp.FtgNr
	,kp.FtgKontaktNr
ORDER BY kp.ForetagKod
	,kp.FtgNr
	,kp.FtgKontaktNr;

