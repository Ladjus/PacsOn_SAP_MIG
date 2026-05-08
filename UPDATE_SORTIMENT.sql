DECLARE @Rows int = 1;

WHILE @Rows > 0
BEGIN
    UPDATE TOP (100) ar9100
    SET ar9100.q_saps4_sortiment = ar2000.q_saps4_sortiment
    FROM ar ar9100 WITH (ROWLOCK, READPAST)
    JOIN ar ar2000 WITH (NOLOCK)
        ON ar2000.artnr = ar9100.artnr
    WHERE ar9100.ForetagKod = 9100
      AND ar2000.ForetagKod = 2000
      AND ar2000.q_saps4_sortiment IS NOT NULL
      AND LTRIM(RTRIM(ar2000.q_saps4_sortiment)) <> ''
      AND ISNULL(ar9100.q_saps4_sortiment, '') <> ar2000.q_saps4_sortiment;

    SET @Rows = @@ROWCOUNT;

    PRINT CONCAT('Uppdaterade rader: ', @Rows);

    WAITFOR DELAY '00:00:02';
END;