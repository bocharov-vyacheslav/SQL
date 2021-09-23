	WITH res AS ( 
		SELECT ank.idrec, ank.mo, mu.name, ank.profil, prof.codename AS profil_name, ank.typehelp, ank.org_type, ank.org_kod, ank.year, ank.month, FLOOR((ank.month + 2) / 3) AS quarter,
			(CASE
				WHEN (ank.org_type = 2) THEN '2-' || TRIM(smo.name)
				WHEN (ank.org_type = 4) THEN '4-' || TRIM(fil.name)
				WHEN (ank.org_type = 5) THEN '5-ИД'
			END) AS org
		FROM (
			SELECT *
			FROM ANKETASURVEY ank
			WHERE ank.typesurvey = 1 AND ((:orgType IN (0, ank.org_type)) AND (:orgKod IN (0, ank.org_kod))) 
				AND (ank.year > :periodBeginYear OR (ank.year = :periodBeginYear AND ank.month >= :periodBeginMonth))
				AND (ank.year < :periodEndYear OR (ank.year = :periodEndYear AND ank.month <= :periodEndMonth))
		) ank 
		INNER JOIN (
			SELECT mu.*
			FROM (
				SELECT *
				FROM (
					SELECT sp.code, sp.terr, (CASE WHEN (sp.shortname IS NULL OR sp.shortname = '') THEN sp.name ELSE sp.shortname END) AS name, sp.dend, MAX(sp.dend) OVER (PARTITION BY sp.code) AS maxdend 
					FROM SPMU sp 
					WHERE (:mo IN (0, sp.code)) AND sp.dend >= :periodBegin AND sp.dbegin <= :periodEnd
				) mu
				WHERE mu.dend = mu.maxdend
			) mu
			INNER JOIN ( 
				SELECT *
				FROM (
					SELECT sp.code, sp.dend, MAX(sp.dend) OVER (PARTITION BY sp.code) AS maxdend 
					FROM SPTERR sp 
					WHERE (:fil IN (0, sp.fil)) AND sp.dend >= :periodBegin AND sp.dbegin <= :periodEnd
				) terr
				WHERE terr.dend = terr.maxdend
			) terr ON mu.terr = terr.code
		) mu ON ank.mo = mu.code
		INNER JOIN (
			SELECT *
			FROM (
				SELECT surv.code, surv.codename, surv.dend, MAX(surv.dend) OVER (PARTITION BY surv.code) AS maxdend  
				FROM SPSURVEY surv 
				WHERE surv.idgroup = 1 AND surv.dend >= :periodBegin AND surv.dbegin <= :periodEnd 
			) surv
			WHERE surv.dend = surv.maxdend
		) prof ON prof.code = ank.profil
		LEFT JOIN (
			SELECT sp.code, sp.name
			FROM SPSMO sp 
			WHERE sp.code = sp.headsmo AND :periodEnd BETWEEN sp.dbegin AND sp.dend
		) smo ON smo.code = ank.org_kod
		LEFT JOIN (
			SELECT sp.code, sp.name
			FROM SPFIL sp 
			WHERE :periodEnd BETWEEN sp.dbegin AND sp.dend
		) fil ON fil.code = ank.org_kod
	)
	
	SELECT r.mo, r.name, r.profil_name AS profil, (r.quarter || ' квартал ' ||  r.year || ' года') AS period, r.org, 
		COUNT(CASE WHEN (r.typehelp = 1) THEN r.idrec END) AS kss_count,
		COUNT(CASE WHEN (r.typehelp = 2) THEN r.idrec END) AS szp_count,
		COUNT(CASE WHEN (r.typehelp = 3) THEN r.idrec END) AS app_count
	FROM res r 
	GROUP BY r.mo, r.name, r.profil, r.profil_name, r.year, r.quarter, r.org_type, r.org_kod, r.org 
	ORDER BY r.mo, r.profil, r.year, r.quarter, r.org