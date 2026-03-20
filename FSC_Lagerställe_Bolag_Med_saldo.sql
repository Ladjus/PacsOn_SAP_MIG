SELECT
    ar.ForetagKod,
    ar.artnr,
    ar.ArtBeskr,
    ars.lagstalle,
    xb.lagplatsnamn,
    ar.q_fsc_claim_id,
    ar.q_fsc_status_id,
    fs.q_fsc_status_desc,
    c.q_fsc_claim_desc,
    ar.anskaffningssatt,
    ars.LagSaldo
FROM ar AS ar
LEFT JOIN ars AS ars
    ON ars.foretagkod = ar.foretagkod
   AND ars.artnr = ar.artnr
LEFT JOIN q_fsc_status AS fs
    ON fs.foretagkod = ar.foretagkod
   AND fs.q_fsc_status_id = ar.q_fsc_status_id
LEFT JOIN q_fsc_claims AS c
    ON c.foretagkod = ar.foretagkod
   AND c.q_fsc_claim_id = ar.q_fsc_claim_id
LEFT JOIN (
    SELECT
        foretagkod,
        lagstalle,
        MAX(lagplatsnamn) AS lagplatsnamn
    FROM xb
    WHERE foretagkod = 6000  ---Byt företag här
    GROUP BY foretagkod, lagstalle
) AS xb
    ON xb.foretagkod = ars.foretagkod
   AND xb.lagstalle = COALESCE(CAST(ars.lagstalle AS nvarchar(20)), '0')
WHERE ar.foretagkod = 6000 ---Byt företag här
  AND ars.LagSaldo <> 0
  AND (
       fs.q_fsc_status_desc IS NOT NULL
    OR c.q_fsc_claim_desc IS NOT NULL
  )
ORDER BY ar.artnr, ars.lagstalle;