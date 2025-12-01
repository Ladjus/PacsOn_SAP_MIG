SELECT kp.ForetagKod
	,kp.FtgNr
	,kp.FtgKontaktNr
	,kp.FtgPerson
	,cr_34.ComNr AS [ESend Batch Invoice]
	,cr_37.ComNr AS [ESend Batch Reminder]
FROM kp
OUTER APPLY (
	SELECT ComNr
	FROM cr
	WHERE ForetagKod = kp.ForetagKod
		AND FtgNr = kp.FtgNr
		AND FtgKontaktNr = kp.FtgKontaktNr
		AND GodsAvisKod IN (34)
	) AS cr_34
OUTER APPLY (
	SELECT ComNr
	FROM cr
	WHERE ForetagKod = kp.ForetagKod
		AND FtgNr = kp.FtgNr
		AND FtgKontaktNr = kp.FtgKontaktNr
		AND GodsAvisKod IN (37)
	) AS cr_37
WHERE kp.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
	AND EXISTS (
		SELECT FtgNr
		
		INTERSECT
		
		SELECT FtgNr
		FROM fr
		WHERE fr.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
			AND fr.q_SAP = '1'  --Endast företag som ska exporteras till SAP
		)
	AND (
		cr_34.ComNr IS NOT NULL
		OR cr_37.ComNr IS NOT NULL
		);
