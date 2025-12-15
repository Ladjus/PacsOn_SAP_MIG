-- Jeeves företag organisationsnummer och EU-momsnummer
Select
-- SAP S/4: BP - Kund/Customer / Momsregistreringsnummer / Tax Numbers [S_CUST_TAXNUMBERS]
    concat(FR.ftgnr, '#', FR.foretagkod) as KUNNR,    -- Unique key
    -- Jeeves Organisationsnummer
    case FR.landskod
        when 'BE' then 'BE1'    -- Belgium: Enterprise Number
        when 'DE' then 'DE1'    -- Germany: Tax Number (e.g. for §48 EStG)
        when 'DK' then 'DK2'    -- Denmark: Tax Number
        when 'SE' then 'SE2'    -- Sweden: Organization Registration Number, format NNNNNNNNNN (ej NNNNNN-NNNN)
        else concat(FR.landskod, '_ORG')
    end as TAXTYPE,    -- Tax Number Category
    case FR.landskod
        when 'SE' then REPLACE(FR.orgnr, '-', '')  --"formel som tar bort '-' t.ex. replace(FR.orgnr, '-', ''), men det kanske finns något smartare"
        else FR.orgnr
    end as TAXNUM    -- Tax Number
from FR
where FR.ForetagKod IN (6000, 9000, 9100, 9400, 9500)    -- Ö, AB, V, N, S
    and FR.q_saps4 = '1'    -- Aktivt företag, kund och/eller leverantör
    and COALESCE(FR.orgnr, '') <> ''  -- "är inte null och är inte tomt '' och är inte sträng av blanksteg"
union
select
    concat(FR.ftgnr, '#', FR.foretagkod) as KUNNR,    -- Unique key
    -- Jeeves EU-momsnummer
    case 
        when FR.landskod IN ('AT', 'BE', 'BG', 'CN', 'CZ', 'DE', 'DK', 'EE', 'ES', 'FI', 'FR', 'GB', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'MC', 'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK') then concat(FR.landskod, '0')    -- Austria, etcetera: VAT Registration Number
        when FR.landskod = 'NO' then 'NO1'    -- Norway : VAT Number
        when FR.landskod = 'CH' then 'CH2'    -- Switzerland: VAT Number
        else concat(FR.landskod, '_EU')
    end as TAXTYPE,    -- Tax Number Category
    FR.eumomsnr as TAXNUM    -- Tax Number
from FR
where FR.ForetagKod IN (6000, 9000, 9100, 9400, 9500)    -- Ö, AB, V, N, S
    and FR.q_saps4 = '1'    -- Aktivt företag, kund och/eller leverantör
    and COALESCE(FR.eumomsnr, '') <> ''  --"är inte null och är inte tomt '' och är inte sträng av blanksteg"
order by KUNNR