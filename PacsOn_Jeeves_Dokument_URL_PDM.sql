




SELECTForetagKod
, jeevesparamstring
FROM jvss
WHEREJeevesParamName = 'EDMPDM004'


SELECT 
    pdm.ForetagKod,
	pdm.ArtNr,
    pdm.dokdir,
    pdm.FtgNr,
	pdm.OrderNr,
	pdm.bestnr,
	pdm.FileName,
	pdm.*
FROM pdm WITH (READUNCOMMITTED)
WHERE pdm.ForetagKod IN (9500)
  AND pdm.ValidPdm = 1;