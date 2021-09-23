	WITH res AS ( 
		SELECT ank.idrec, ank.mo, mu.name, ans.codevopros, ans.ansvervopros 
		FROM ( 
			SELECT *
			FROM ANKETASURVEY ank
			WHERE ank.typesurvey = 1 AND ank.typehelp = 3 AND ((:orgType IN (0, ank.org_type)) AND (:orgKod IN (0, ank.org_kod))) 
				AND (ank.year > :periodBeginYear OR (ank.year = :periodBeginYear AND ank.month >= :periodBeginMonth))
				AND (ank.year < :periodEndYear OR (ank.year = :periodEndYear AND ank.month <= :periodEndMonth))
		) ank 
		INNER JOIN ANSVERVOPROS ans ON ans.idrec = ank.idrec 
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
	)
	
	SELECT agr.name, ROUND(agr.gr2 / agr.count, 2) AS gr2, ROUND(agr.gr3 / agr.count, 2) AS gr3, 
		ROUND(agr.gr4 / agr.count, 2) AS gr4, ROUND(agr.gr5 / agr.count, 2) AS gr5, ROUND(agr.gr6 / agr.count, 2) AS gr6, 
		ROUND(agr.gr7 / agr.count, 2) AS gr7, ROUND(agr.gr8 / agr.count, 2) AS gr8, ROUND(agr.gr9 / agr.count, 2) AS gr9, 
		ROUND(agr.gr10 / agr.count, 2) AS gr10, ROUND(agr.gr11 / agr.count, 2) AS gr11, 
		ROUND((ROUND(agr.gr2 / agr.count, 2) + ROUND(agr.gr3 / agr.count, 2) + ROUND(agr.gr4 / agr.count, 2) 
			+ ROUND(agr.gr5 / agr.count, 2) + ROUND(agr.gr6 / agr.count, 2) + ROUND(agr.gr7 / agr.count, 2) 
			+ ROUND(agr.gr8 / agr.count, 2) + ROUND(agr.gr9 / agr.count, 2) + ROUND(agr.gr10 / agr.count, 2) 
			+ ROUND(agr.gr11 / agr.count, 2)) / 10, 2) AS total 
	FROM ( 
		SELECT ('[' || TO_CHAR(660000 + r.mo) || '] ' || r.name) AS name, 
			(SELECT COUNT(DISTINCT(res.idrec)) FROM res WHERE res.mo = r.mo) AS count, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 7 AND res.ANSVERVOPROS IN (1, 2))) AS gr2, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 8 AND res.ANSVERVOPROS IN (1, 2))) AS gr3, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 9 AND res.ANSVERVOPROS IN (1, 2))) AS gr4, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 10 AND res.ANSVERVOPROS IN (1, 2))) AS gr5, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 11 AND res.ANSVERVOPROS IN (1, 2))) AS gr6, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 12 AND res.ANSVERVOPROS IN (1, 2))) AS gr7, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 13 AND res.ANSVERVOPROS IN (1, 2))) AS gr8, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 14 AND res.ANSVERVOPROS IN (1, 2))) AS gr9, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 15 AND res.ANSVERVOPROS IN (1, 2))) AS gr10, 
			(100 * (SELECT COUNT(*) FROM res WHERE res.mo = r.mo AND res.codevopros = 16 AND res.ANSVERVOPROS IN (1, 2))) AS gr11 
		FROM res r 
		GROUP BY r.mo, r.name 
	) agr 
	ORDER BY agr.name