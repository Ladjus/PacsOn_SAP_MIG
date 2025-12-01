SELECT ar.artnr
	,ar.artbeskr
	,ar.artbeskrspec
	,ar.artbeskr2
	,ar.levnr
	,fr.ftgnamn
	,al.artnrlev
	,ar.itemstatuscode
	,xits.itemstatusdescr
	,ar.ordtyp
	,x6.OrdTypBeskr
	,ar.q_web_productid
	,q_web_product.q_web_productname
	,ar.foretagkod
	,ar.RowCreatedDt
	,ft.FaktDat
FROM ar WITH (READUNCOMMITTED)
OUTER APPLY (SELECT MAX(FaktDat) AS FaktDat FROM ft WITH (READUNCOMMITTED) WHERE ft.ForetagKod = ar.ForetagKod
	AND ft.ArtNr = ar.ArtNr) AS ft
JOIN xits WITH (READUNCOMMITTED) ON xits.ForetagKod = ar.ForetagKod
	AND xits.ItemStatusCode = ar.ItemStatusCode
LEFT JOIN q_web_product WITH (READUNCOMMITTED) ON q_web_product.ForetagKod = ar.ForetagKod
	AND q_web_product.q_web_productid = ar.q_web_productid
LEFT JOIN al WITH (READUNCOMMITTED) ON al.ForetagKod = ar.ForetagKod
	AND al.ArtNr = ar.ArtNr
	AND al.FtgNr = ar.LevNr
LEFT JOIN fr WITH (READUNCOMMITTED) ON fr.ForetagKod = al.ForetagKod
	AND fr.FtgNr = al.FtgNr
LEFT JOIN x6 WITH (READUNCOMMITTED) ON x6.foretagkod = ar.foretagkod
	AND x6.OrdTyp = ar.OrdTyp
--fakturerade från 20230101 och artiklar som är nyskapade efter 20250101
WHERE (ar.RowCreatedDt >= '20250101'
	OR ft.faktdat >= '20230101')
	AND ar.ForetagKod = 9100