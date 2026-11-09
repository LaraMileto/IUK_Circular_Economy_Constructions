PRAGMA foreign_keys=ON;
-- Should return "ok".
PRAGMA integrity_check;
-- Should return NO rows.
PRAGMA foreign_key_check;
-- Expected: window=0/0/0; bricks=375/50/325 (physical/reserved/free).
SELECT material_id, materialart, physischer_bestand, offen_reserviert, frei_verfuegbar FROM v_verfuegbarkeit ORDER BY material_id;
-- Five business events: 2 reservations, 2 sales, 1 disposal.
SELECT 'GV1: Fenster reserviert' AS geschaeftsvorfall, r.datum, rp.material_id, rp.menge FROM reservierung r JOIN reservierungsposition rp ON rp.reservierung_id=r.reservierung_id WHERE r.reservierung_id=1
UNION ALL SELECT 'GV2: Backsteine reserviert',r.datum,rp.material_id,rp.menge FROM reservierung r JOIN reservierungsposition rp ON rp.reservierung_id=r.reservierung_id WHERE r.reservierung_id=2
UNION ALL SELECT 'GV3: Fenster verkauft',v.datum,vp.material_id,vp.menge FROM verkauf v JOIN verkaufsposition vp ON vp.verkauf_id=v.verkauf_id WHERE v.verkauf_id=1
UNION ALL SELECT 'GV4: Backsteine verkauft',v.datum,vp.material_id,vp.menge FROM verkauf v JOIN verkaufsposition vp ON vp.verkauf_id=v.verkauf_id WHERE v.verkauf_id=2
UNION ALL SELECT 'GV5: Backsteine entsorgt',x.datum,x.material_id,x.menge FROM verwertung x WHERE x.verwertung_id=1;
-- Audit: sales and disposal have corresponding warehouse outbound movements.
SELECT 'Unmatched sale lines' AS pruefung, COUNT(*) AS fehler FROM verkaufsposition vp LEFT JOIN lagerbewegung b ON b.verk_position_id=vp.verk_position_id WHERE b.bewegung_id IS NULL
UNION ALL SELECT 'Unmatched disposals',COUNT(*) FROM verwertung v LEFT JOIN lagerbewegung b ON b.verwertung_id=v.verwertung_id WHERE v.art='ENTSORGUNG' AND b.bewegung_id IS NULL;
