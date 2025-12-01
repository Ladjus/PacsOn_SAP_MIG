WITH CTE
AS (
	SELECT cr.ForetagKod
		,cr.FtgNr
		,cr.ComKod
		,cr.ComNr
		,ROW_NUMBER() OVER (
			PARTITION BY cr.ForetagKod
			,cr.FtgNr
			,cr.ComKod ORDER BY cr.ComNr
			) AS rn
	FROM cr
	WHERE cr.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
		AND EXISTS (
			SELECT ForetagKod
				,FtgNr
			
			INTERSECT
			
			SELECT ForetagKod
				,FtgNr
			FROM fr
			WHERE fr.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
				AND fr.q_SAP = '1'  --Endast företag som ska exporteras till SAP
			)
		AND cr.FtgKontaktNr IS NULL
		AND cr.ComKod IN (0, 7) --Företagets telefonnummer resp Företagets mailadress
	)
SELECT ForetagKod
	,FtgNr
	,MAX(CASE 
			WHEN ComKod = 0
				AND rn = 1
				THEN ComNr
			END) AS ComNr_0_1  --ComKod = 0 = Företagets telefonnummer
	,MAX(CASE 
			WHEN ComKod = 0
				AND rn = 2
				THEN ComNr
			END) AS ComNr_0_2
	,MAX(CASE 
			WHEN ComKod = 0
				AND rn = 3
				THEN ComNr
			END) AS ComNr_0_3
	,MAX(CASE 
			WHEN ComKod = 7
				AND rn = 1
				THEN ComNr
			END) AS ComNr_7_1  --ComKod = 7 = Företagets mejladress
	,MAX(CASE 
			WHEN ComKod = 7
				AND rn = 2
				THEN ComNr
			END) AS ComNr_7_2
	,MAX(CASE 
			WHEN ComKod = 7
				AND rn = 3
				THEN ComNr
			END) AS ComNr_7_3
FROM CTE
GROUP BY ForetagKod
	,FtgNr
ORDER BY ForetagKod
	,FtgNr;
