-- Alternative enheter
Select AR.artbeskrspec,    -- "Artikelnr"
       AR.artbeskr,    -- Artikelbeskrivning
       AR.artbeskr2,    -- Artikelbeskr 2
       XARE.*
from AR
inner join XARE
    on AR.foretagkod = XARE.foretagkod
    and AR.artnr = XARE.artnr    -- "Artikel Id"
where AR.foretagkod in ('2000')    -- Mall
    and AR.artbeskrspec        -- "Artikelnr"
        in (
'1008763',
'1046867',
'1079813',
'1080072',
'1080073',
'1080260',
'1082468',
'1087912',
'1089672',
'1090074',
'1095598',
'1100190',
'1102193',
'1105825',
'11069663',
'13069602',
'15069601',
'18012500',
'18012503',
'187020',
'187607',
'300207',
'300226',
'41417',
'500104',
'540-015',
'893683',
'896778',
'898057',
'902-843',
'9100-893683',
'SCL100ML',
'SP86074',
'SP86075'
)
order by 1
