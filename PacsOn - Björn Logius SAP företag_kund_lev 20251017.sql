SELECT fr.ftgnr [Ftgnr]
	,fr.ftgnamn [Företagsnamn]
	,fr.rowcreatedby [Skapad av]
	,fr.rowcreateddt [Skapad datum]
	,CASE 
		WHEN kus.ftgnr IS NULL
			THEN 'Nej'
		ELSE 'Ja'
		END [Är kund]
	,CASE 
		WHEN le.ftgnr IS NULL
			THEN 'Nej'
		ELSE 'Ja'
		END [Är leverantör]
	,oh1.orddatumMax [Senaste order]
	,oh2.orddatumMax [Senaste order med Lev.plats]
	,ofh1.offertdatumMax [Senaste Offert]
	,bh1.[Beställningsdatum MAX] [Senaste Beställning]
	,lr.[LevFaktDat MAX] AS [Senaste Levfaktura]
	,CASE 
		WHEN oh1.orddatumMax IS NULL
			AND oh2.orddatumMax IS NULL
			AND ofh1.offertdatumMax IS NULL
			THEN 'Nej'
		ELSE 'Ja'
		END [Har använts i order/offert]
FROM fr WITH (READUNCOMMITTED)
LEFT OUTER JOIN kus WITH (READUNCOMMITTED) ON kus.foretagkod = fr.foretagkod
	AND kus.ftgnr = fr.ftgnr
LEFT OUTER JOIN le WITH (READUNCOMMITTED) ON le.foretagkod = fr.foretagkod
	AND le.ftgnr = fr.ftgnr
LEFT OUTER JOIN (
	SELECT oh.foretagkod
		,max(oh.orddatum) orddatumMax
		,oh.ftgnr
	FROM oh WITH (READUNCOMMITTED)
	GROUP BY oh.foretagkod
		,oh.ftgnr
	) AS oh1 ON oh1.foretagkod = fr.foretagkod
	AND oh1.ftgnr = fr.ftgnr
LEFT OUTER JOIN (
	SELECT oh.foretagkod
		,max(oh.orddatum) orddatumMax
		,oh.OrdLevPlats1
	FROM oh WITH (READUNCOMMITTED)
	GROUP BY oh.foretagkod
		,oh.OrdLevPlats1
	) AS oh2 ON oh2.foretagkod = fr.foretagkod
	AND oh2.OrdLevPlats1 = fr.ftgnr
LEFT OUTER JOIN (
	SELECT ofh.foretagkod
		,max(ofh.offertdat) offertdatumMax
		,ofh.ftgnr
	FROM ofh WITH (READUNCOMMITTED)
	GROUP BY ofh.foretagkod
		,ofh.ftgnr
	) AS ofh1 ON ofh1.foretagkod = fr.foretagkod
	AND ofh1.ftgnr = fr.ftgnr
LEFT OUTER JOIN (
	SELECT bh.foretagkod
		,max(bh.regdat) [Beställningsdatum MAX]
		,bh.ftgnr
	FROM bh WITH (READUNCOMMITTED)
	GROUP BY bh.foretagkod
		,bh.ftgnr
	) AS bh1 ON bh1.foretagkod = fr.foretagkod
	AND bh1.ftgnr = fr.ftgnr
LEFT OUTER JOIN (
	SELECT lr.foretagkod
		,max(lr.LevFaktDat) [LevFaktDat MAX]
		,lr.ftgnr
	FROM lr WITH (READUNCOMMITTED)
	GROUP BY lr.foretagkod
		,lr.ftgnr
	) AS lr ON lr.foretagkod = fr.foretagkod
	AND lr.ftgnr = fr.ftgnr
WHERE fr.foretagkod = ???
ORDER BY fr.ftgnamn
