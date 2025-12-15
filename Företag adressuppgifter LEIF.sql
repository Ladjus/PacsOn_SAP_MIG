Select
-- SAP S/4: BP - Kund/Customer / Allmänna data (obligatoriskt) / General Data (mandatory) [S_CUST_GEN]
    concat(FR.ftgnr, '#', FR.foretagkod) as KUNNR,    -- Unique key
    case 
			WHEN kus.FtgNr IS NOT NULL THEN 'CUST'  --"om det är en ”riktig” kund KUS-tabell så 'CUST' (Customer)"
			WHEN lp.OrdLevPlats1 IS NOT NULL THEN 'SHPT'  --"om det är en leveransplatskund LP-tabell så 'SHPT'(Customer: Ship-to party, only)"
         else ''
    end as KTOKD,    -- Customer Account Group
    case 
			WHEN le.FtgNr IS NOT NULL THEN 'SUPL'  --"om leverantör LE-tabell så 'SUPL' (Supplier)"
         else ''
    end as KTOKK,    -- Supplier Account Group
    FR.ftgnamn as NAMORG1,        -- Företagsnamn
    FR.ftgpostadr1 as NAMORG2,    -- C/O-adress field contains Name2 data
    FR.comnr as SORTL,    -- Sökbegrepp
    --FR.q_fr_sokord as MCOD2,    -- Söknamn
    FR.orgnr,    -- Organisationsnummer
    FR.eumomsnr,    -- VAT reg no
    -- Gatuadress
    case
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) <> 'BOX' THEN FR.ftgpostadr2
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' AND FR.ftgpostadr5 IS NOT NULL THEN FR.ftgpostadr5
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' AND FR.ftgpostadr4 IS NOT NULL THEN FR.ftgpostadr4
			WHEN FR.ftgpostadr2 IS NULL AND FR.ftgpostadr5 IS NOT NULL THEN FR.ftgpostadr5
        else ''
		end
    as STREET,    -- Gatuadress gata
    case 
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) <> 'BOX' THEN FR.ftgpostnr
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' AND FR.ftgpostadr5 IS NOT NULL THEN FR.ftglevpostnr
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' AND FR.ftgpostadr4 IS NOT NULL THEN FR.ftgbespostnr
			WHEN FR.ftgpostadr2 IS NULL AND FR.ftgpostadr5 IS NOT NULL THEN FR.ftglevpostnr
        else ''
		end
    as POST_CODE1,    -- Gatuadress postnummer
    case 
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) <> 'BOX' THEN FR.ftgpostadr3
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' AND FR.ftgpostadr5 IS NOT NULL THEN FR.ftgpostlevadr3
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' AND FR.ftgpostadr4 IS NOT NULL THEN FR.ftgpostbesadr3
			WHEN FR.ftgpostadr2 IS NULL AND FR.ftgpostadr5 IS NOT NULL THEN FR.ftgpostlevadr3
        else ''
		end
    as CITY1,    -- Gatuadress stad
    -- Boxadress
    case 
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' THEN FR.ftgpostadr2
        else ''
		end
    as PO_BOX,    -- Boxadress box
    case 
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' THEN FR.ftgpostnr
        else ''
		end
    as POST_CODE2,    -- Boxadress postnummer
    case 
			WHEN UPPER(LEFT(TRIM(FR.ftgpostadr2),3)) = 'BOX' THEN FR.ftgpostadr3
        else ''
		end
    as PO_BOX_LOC,    -- Boxadress stad
    FR.landskod as COUNTRY,    -- Land
    
    case
			WHEN LEN(FR.ean_loc_code) = 13 THEN LEFT(FR.ean_loc_code,7)  -- GS1/GLN-nummer: "om FR.ean_loc_code innehåller 13 siffror så tag tecken 1-7"
        else ''
		end
    as LOCATION_1,    -- International Location Number  (Part 1)
    case 
			WHEN LEN(FR.ean_loc_code) = 13 THEN SUBSTRING(FR.ean_loc_code, 8, 5)  -- GS1/GLN-nummer: "om FR.ean_loc_code innehåller 13 siffror så tag tecken 8-12"
        else ''
		end
    as LOCATION_2,    -- International Location Number  (Part 1)
    case 
			WHEN LEN(FR.ean_loc_code) = 13 THEN RIGHT(FR.ean_loc_code, 1)  -- GS1/GLN-nummer: "om FR.ean_loc_code innehåller 13 siffror så tag tecken 13"
        else ''
		end
    as LOCATION_3,    -- International Location Number  (Part 1)
    concat(FR.ftgnr, '#', FR.foretagkod) as BPEXT,    -- External business-partner number
    FR.landskod as LANGU_CORR,    -- Språk SE --> SV etc
    case when LEN(FR.webadress) > 1 then 'HPG'  -- Webb-URL och "HPG" om inte ett skräptecken
         else ''
    end as URI_TYP,
    case when LEN(FR.webadress) > 1 then FR.webadress
         else ''
    end as URI_ADDR,
    KUS.q_buyer_code as YY1_CUSTOMERNUMBERFF_CUS    -- Factor France Customer Number
from FR
	LEFT OUTER JOIN KUS ON   -- Ref KUS.q_buyer_code
KUS.ForetagKod = FR.ForetagKod AND
KUS.FtgNr = FR.FtgNr
	LEFT OUTER JOIN lp ON
lp.ForetagKod = FR.ForetagKod AND
lp.OrdLevPlats1 = FR.FtgNr
	LEFT OUTER JOIN le ON
le.ForetagKod = FR.ForetagKod AND
le.FtgNr = FR.FtgNr
where FR.ForetagKod IN (6000, 9000, 9100, 9400, 9500)    -- Ö, AB, V, N, S
    and FR.q_saps4 = '1'    -- Aktivt företag, kund och/eller leverantör
order by KUNNR
