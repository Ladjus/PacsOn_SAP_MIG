SELECT 
     kp.ForetagKod 
    ,kp.FtgNr
    ,kp.FtgKontaktNr
    ,MIN(kp.FtgPerson) AS FtgPerson
    ,MIN(kp.avd) AS Avd
    ,MIN(kp.befattkod) AS BefattKod  -- Ska BefattKod eller BefattBeskr exporteras?
    ,MIN(kp.ComNr) AS ComNr
    ,MIN(kp.q_kp_default_vid_order) AS q_kp_default_vid_order

    -- Kommunikation från cr
    ,MAX(CASE 
            WHEN cr.ComKod = 0
                THEN cr.ComNr
        END) AS CR_Telefon_0

    ,MAX(CASE 
            WHEN cr.ComKod = 1
                THEN cr.ComNr
        END) AS CR_Telefon_1

    ,MAX(CASE 
            WHEN cr.ComKod = 2
                THEN cr.ComNr
        END) AS CR_Telefon_2

    ,MAX(CASE 
            WHEN cr.ComKod = 3
                THEN cr.ComNr
        END) AS CR_Telefon_3

    ,MAX(CASE 
            WHEN cr.ComKod = 4
                THEN cr.ComNr
        END) AS CR_Telefon_4

    ,MAX(CASE 
            WHEN cr.ComKod = 8
                THEN cr.ComNr
        END) AS CR_Mejl

    ,MIN(kp.q_kat_industriemb) AS [ZF_Fakturamottagare]
    ,MIN(kp.q_kat_hygien) AS [ZK_Key_account_manager]
    ,MIN(kp.q_kat_stadprod) AS [SE_Sales_employee]
    ,MIN(kp.q_kat_servering) AS [ER_Responsible_employee]
    ,MIN(kp.q_kat_butiksemb) AS [ZL_Leveransinfo]
    ,MIN(kp.q_kat_kontorsmtrl) AS [ZO_Orderbekräftelse]
    ,MIN(kp.q_kat_skyddsprod) AS [ZS_Data_safety_sheet]

FROM kp

LEFT JOIN cr 
    ON cr.ForetagKod = kp.ForetagKod
    AND cr.FtgNr = kp.FtgNr
    AND cr.FtgKontaktNr = kp.FtgKontaktNr

WHERE kp.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
    AND EXISTS (
        SELECT 
             kp.ForetagKod
            ,kp.FtgNr

        INTERSECT

        SELECT 
             fr.ForetagKod
            ,fr.FtgNr
        FROM fr
        WHERE fr.ForetagKod IN (6000, 9000, 9100, 9400, 9500)
            AND fr.q_saps4 = '1'  -- Endast företag som ska exporteras till SAP
    )

GROUP BY 
     kp.ForetagKod
    ,kp.FtgNr
    ,kp.FtgKontaktNr

ORDER BY 
     kp.ForetagKod
    ,kp.FtgNr
    ,kp.FtgKontaktNr;