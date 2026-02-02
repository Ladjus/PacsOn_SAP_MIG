SELECT
    ar.ForetagKod,
    ar.artnr,
    ar.ArtBeskr,
    ar.q_fsc_claim_id,
    ar.q_fsc_status_id,

    fs.q_fsc_status_desc,
    c.q_fsc_claim_desc
FROM ar AS ar
LEFT JOIN q_fsc_status AS fs
  ON fs.foretagkod = ar.foretagkod
 AND fs.q_fsc_status_id = ar.q_fsc_status_id
LEFT JOIN q_fsc_claims AS c
  ON c.foretagkod = ar.foretagkod
 AND c.q_fsc_claim_id = ar.q_fsc_claim_id
WHERE ar.foretagkod IN (6000, 9100, 9400, 9500)
ORDER BY ar.ForetagKod, ar.artnr;


---select * from ar where ar.q_fsc_status_id is not null 