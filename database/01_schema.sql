-- Zweitbau | Task 4 | SQLite schema aligned to the 14-entity ER model.
-- This is a case-study design, not a production ERP implementation.
PRAGMA foreign_keys = ON;

CREATE TABLE gebaeude (
  gebaeude_id INTEGER PRIMARY KEY,
  adresse TEXT NOT NULL,
  baujahr INTEGER CHECK(baujahr BETWEEN 1800 AND 2100)
);
CREATE TABLE rueckbauprojekt (
  projekt_id INTEGER PRIMARY KEY,
  gebaeude_id INTEGER NOT NULL REFERENCES gebaeude(gebaeude_id),
  startdatum TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('GEPLANT','FREIGEGEBEN','AKTIV','ABGESCHLOSSEN'))
);
CREATE TABLE materialposition (
  material_id INTEGER PRIMARY KEY,
  projekt_id INTEGER NOT NULL REFERENCES rueckbauprojekt(projekt_id),
  erfassungsart TEXT NOT NULL CHECK(erfassungsart IN ('EINZELBAUTEIL','CHARGE')),
  materialart TEXT NOT NULL,
  masse TEXT,
  zustand TEXT,
  baujahr INTEGER,
  anfangsmenge REAL NOT NULL CHECK(anfangsmenge > 0),
  einheit TEXT NOT NULL,
  ausbaudatum TEXT,
  erwartet_verfuegbar_ab TEXT,
  CHECK (erfassungsart <> 'EINZELBAUTEIL' OR (anfangsmenge = 1 AND einheit = 'Stueck'))
);
CREATE TABLE pruefung (
  pruefung_id INTEGER PRIMARY KEY,
  material_id INTEGER NOT NULL REFERENCES materialposition(material_id),
  pruefdatum TEXT NOT NULL,
  ergebnis TEXT NOT NULL CHECK(ergebnis IN ('GEEIGNET','UNGEEIGNET','OFFEN')),
  schadstoffstatus TEXT NOT NULL CHECK(schadstoffstatus IN ('UNBEDENKLICH','BELASTET','UNGEKLAERT')),
  pruefer TEXT NOT NULL
);
CREATE TABLE region (
  region_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE lager (
  lager_id INTEGER PRIMARY KEY,
  region_id INTEGER NOT NULL REFERENCES region(region_id),
  name TEXT NOT NULL
);
CREATE TABLE lagerplatz (
  lagerplatz_id INTEGER PRIMARY KEY,
  lager_id INTEGER NOT NULL REFERENCES lager(lager_id),
  platzcode TEXT NOT NULL,
  UNIQUE(lager_id, platzcode)
);
CREATE TABLE kunde (
  kunde_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  kundentyp TEXT NOT NULL CHECK(kundentyp IN ('BAUHERRSCHAFT','HANDWERK','PRIVAT')),
  region TEXT NOT NULL
);
CREATE TABLE reservierung (
  reservierung_id INTEGER PRIMARY KEY,
  kunde_id INTEGER NOT NULL REFERENCES kunde(kunde_id),
  datum TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('AKTIV','STORNIERT','ERLEDIGT')) DEFAULT 'AKTIV'
);
CREATE TABLE reservierungsposition (
  res_position_id INTEGER PRIMARY KEY,
  reservierung_id INTEGER NOT NULL REFERENCES reservierung(reservierung_id),
  material_id INTEGER NOT NULL REFERENCES materialposition(material_id),
  menge REAL NOT NULL CHECK(menge > 0),
  UNIQUE(reservierung_id, material_id)
);
CREATE TABLE verkauf (
  verkauf_id INTEGER PRIMARY KEY,
  kunde_id INTEGER NOT NULL REFERENCES kunde(kunde_id),
  datum TEXT NOT NULL
);
CREATE TABLE verkaufsposition (
  verk_position_id INTEGER PRIMARY KEY,
  verkauf_id INTEGER NOT NULL REFERENCES verkauf(verkauf_id),
  material_id INTEGER NOT NULL REFERENCES materialposition(material_id),
  res_position_id INTEGER REFERENCES reservierungsposition(res_position_id),
  menge REAL NOT NULL CHECK(menge > 0)
);
CREATE TABLE verwertung (
  verwertung_id INTEGER PRIMARY KEY,
  material_id INTEGER NOT NULL REFERENCES materialposition(material_id),
  verk_position_id INTEGER REFERENCES verkaufsposition(verk_position_id),
  datum TEXT NOT NULL,
  art TEXT NOT NULL CHECK(art IN ('WIEDERVERWENDUNG','ENTSORGUNG')),
  menge REAL NOT NULL CHECK(menge > 0),
  ziel TEXT NOT NULL,
  nachweis TEXT,
  CHECK (art <> 'ENTSORGUNG' OR verk_position_id IS NULL)
);
CREATE TABLE lagerbewegung (
  bewegung_id INTEGER PRIMARY KEY,
  material_id INTEGER NOT NULL REFERENCES materialposition(material_id),
  von_platz_id INTEGER REFERENCES lagerplatz(lagerplatz_id),
  nach_platz_id INTEGER REFERENCES lagerplatz(lagerplatz_id),
  datum TEXT NOT NULL,
  menge REAL NOT NULL CHECK(menge > 0),
  bewegungstyp TEXT NOT NULL CHECK(bewegungstyp IN ('EINLAGERUNG','UMLAGERUNG','AUSLAGERUNG')),
  verk_position_id INTEGER REFERENCES verkaufsposition(verk_position_id),
  verwertung_id INTEGER REFERENCES verwertung(verwertung_id),
  CHECK (von_platz_id IS NOT NULL OR nach_platz_id IS NOT NULL),
  CHECK (von_platz_id IS NULL OR nach_platz_id IS NULL OR von_platz_id <> nach_platz_id),
  CHECK (
    (bewegungstyp = 'EINLAGERUNG' AND von_platz_id IS NULL AND nach_platz_id IS NOT NULL AND verk_position_id IS NULL AND verwertung_id IS NULL) OR
    (bewegungstyp = 'UMLAGERUNG' AND von_platz_id IS NOT NULL AND nach_platz_id IS NOT NULL AND verk_position_id IS NULL AND verwertung_id IS NULL) OR
    (bewegungstyp = 'AUSLAGERUNG' AND von_platz_id IS NOT NULL AND nach_platz_id IS NULL AND (verk_position_id IS NOT NULL) <> (verwertung_id IS NOT NULL))
  )
);
CREATE UNIQUE INDEX uq_auslagerung_verkauf ON lagerbewegung(verk_position_id) WHERE verk_position_id IS NOT NULL;
CREATE UNIQUE INDEX uq_auslagerung_entsorgung ON lagerbewegung(verwertung_id) WHERE verwertung_id IS NOT NULL;
CREATE INDEX idx_bewegung_material ON lagerbewegung(material_id);
CREATE INDEX idx_res_material ON reservierungsposition(material_id);
CREATE INDEX idx_sale_material ON verkaufsposition(material_id);

-- Two distinct availability concepts:
-- physischer_bestand = material currently in the warehouse (from movement history)
-- planbar = physically stocked quantity, OR (before first goods receipt) the
-- expected starting quantity of an inspected, reusable component/lot.
-- Pre-arrival reservations are explicitly possible, as required by the case's
-- planning advantage; such items are NOT shown as physical warehouse inventory.
CREATE VIEW v_lagerbestand AS
SELECT m.material_id, m.materialart, m.erfassungsart, m.einheit, m.anfangsmenge,
       COALESCE(SUM(CASE WHEN b.nach_platz_id IS NOT NULL THEN b.menge ELSE 0 END),0)
       - COALESCE(SUM(CASE WHEN b.von_platz_id IS NOT NULL THEN b.menge ELSE 0 END),0) AS physischer_bestand
FROM materialposition m LEFT JOIN lagerbewegung b ON b.material_id = m.material_id
GROUP BY m.material_id;

CREATE VIEW v_verfuegbarkeit AS
SELECT x.*,
 CASE WHEN NOT EXISTS (SELECT 1 FROM lagerbewegung b
                       WHERE b.material_id=x.material_id AND b.bewegungstyp='EINLAGERUNG')
           THEN x.anfangsmenge ELSE x.physischer_bestand END AS planbare_menge,
 COALESCE((
  SELECT SUM(rp.menge - COALESCE((SELECT SUM(vp.menge) FROM verkaufsposition vp
                                 WHERE vp.res_position_id = rp.res_position_id),0))
  FROM reservierungsposition rp JOIN reservierung r ON r.reservierung_id = rp.reservierung_id
  WHERE rp.material_id = x.material_id AND r.status='AKTIV'
),0) AS offen_reserviert,
 (CASE WHEN NOT EXISTS (SELECT 1 FROM lagerbewegung b
                              WHERE b.material_id=x.material_id AND b.bewegungstyp='EINLAGERUNG')
          THEN x.anfangsmenge ELSE x.physischer_bestand END) - COALESCE((
  SELECT SUM(rp.menge - COALESCE((SELECT SUM(vp.menge) FROM verkaufsposition vp
                                 WHERE vp.res_position_id = rp.res_position_id),0))
  FROM reservierungsposition rp JOIN reservierung r ON r.reservierung_id = rp.reservierung_id
  WHERE rp.material_id = x.material_id AND r.status='AKTIV'
),0) AS frei_verfuegbar
FROM v_lagerbestand x;

-- Require documented reuse suitability before a reservation (including pre-arrival).
CREATE TRIGGER trg_reservierungsmenge BEFORE INSERT ON reservierungsposition
BEGIN
  SELECT CASE WHEN NOT EXISTS (
    SELECT 1 FROM pruefung p WHERE p.material_id=NEW.material_id
    AND p.ergebnis='GEEIGNET' AND p.schadstoffstatus='UNBEDENKLICH'
  ) THEN RAISE(ABORT,'Material ist nicht fuer Reservierung freigegeben') END;
  SELECT CASE WHEN NEW.menge > (SELECT frei_verfuegbar FROM v_verfuegbarkeit WHERE material_id=NEW.material_id) + 0.000001
    THEN RAISE(ABORT,'Reservierungsmenge uebersteigt verfuegbaren Bestand') END;
  SELECT CASE WHEN (SELECT status FROM reservierung WHERE reservierung_id=NEW.reservierung_id) <> 'AKTIV'
    THEN RAISE(ABORT,'Reservierung ist nicht aktiv') END;
END;

-- Validate reservation/sale customer, material, remaining reserved quantity,
-- and protect free stock when selling without a reservation.
CREATE TRIGGER trg_verkauf_menge BEFORE INSERT ON verkaufsposition
BEGIN
 SELECT CASE WHEN NEW.res_position_id IS NOT NULL AND (
    (SELECT rp.material_id FROM reservierungsposition rp WHERE rp.res_position_id=NEW.res_position_id) <> NEW.material_id OR
    (SELECT r.kunde_id FROM reservierungsposition rp JOIN reservierung r ON r.reservierung_id=rp.reservierung_id WHERE rp.res_position_id=NEW.res_position_id) <>
    (SELECT kunde_id FROM verkauf WHERE verkauf_id=NEW.verkauf_id) OR
    (SELECT r.status FROM reservierungsposition rp JOIN reservierung r ON r.reservierung_id=rp.reservierung_id WHERE rp.res_position_id=NEW.res_position_id) <> 'AKTIV'
 ) THEN RAISE(ABORT,'Verkauf passt nicht zur aktiven Reservierung') END;
 SELECT CASE WHEN NEW.res_position_id IS NOT NULL AND NEW.menge > (
    SELECT rp.menge - COALESCE((SELECT SUM(vp.menge) FROM verkaufsposition vp WHERE vp.res_position_id=rp.res_position_id),0)
    FROM reservierungsposition rp WHERE rp.res_position_id=NEW.res_position_id
 ) + 0.000001 THEN RAISE(ABORT,'Verkauf uebersteigt offene Reservierung') END;
 SELECT CASE WHEN NEW.res_position_id IS NULL AND NEW.menge > (
    SELECT frei_verfuegbar FROM v_verfuegbarkeit WHERE material_id=NEW.material_id
 ) + 0.000001 THEN RAISE(ABORT,'Unreservierter Verkauf uebersteigt freien Bestand') END;
END;

-- An outbound movement must correspond to exactly one sales position or disposal record.
CREATE TRIGGER trg_auslagerung BEFORE INSERT ON lagerbewegung
WHEN NEW.bewegungstyp='AUSLAGERUNG'
BEGIN
 -- Disposal must not consume quantities promised to customers.
 SELECT CASE WHEN NEW.verwertung_id IS NOT NULL AND NEW.menge >
   (SELECT frei_verfuegbar FROM v_verfuegbarkeit WHERE material_id=NEW.material_id) + 0.000001
 THEN RAISE(ABORT,'Entsorgung wuerde reservierten Bestand verbrauchen') END;
 SELECT CASE WHEN NEW.menge > COALESCE((
   SELECT SUM(CASE WHEN b.nach_platz_id=NEW.von_platz_id THEN b.menge ELSE -b.menge END)
   FROM lagerbewegung b WHERE b.material_id=NEW.material_id AND
      (b.nach_platz_id=NEW.von_platz_id OR b.von_platz_id=NEW.von_platz_id)
 ),0) + 0.000001 THEN RAISE(ABORT,'Nicht genug physischer Bestand am Lagerplatz') END;
 SELECT CASE WHEN NEW.verk_position_id IS NOT NULL AND NOT EXISTS (
   SELECT 1 FROM verkaufsposition vp WHERE vp.verk_position_id=NEW.verk_position_id
   AND vp.material_id=NEW.material_id AND vp.menge=NEW.menge
 ) THEN RAISE(ABORT,'Auslagerung passt nicht zur Verkaufsposition') END;
 SELECT CASE WHEN NEW.verwertung_id IS NOT NULL AND NOT EXISTS (
   SELECT 1 FROM verwertung v WHERE v.verwertung_id=NEW.verwertung_id AND v.material_id=NEW.material_id
   AND v.menge=NEW.menge AND v.art='ENTSORGUNG'
 ) THEN RAISE(ABORT,'Auslagerung passt nicht zur Entsorgung') END;
END;

CREATE TRIGGER trg_umlagerung BEFORE INSERT ON lagerbewegung
WHEN NEW.bewegungstyp='UMLAGERUNG'
BEGIN
 SELECT CASE WHEN NEW.menge > COALESCE((
   SELECT SUM(CASE WHEN b.nach_platz_id=NEW.von_platz_id THEN b.menge ELSE -b.menge END)
   FROM lagerbewegung b WHERE b.material_id=NEW.material_id AND
      (b.nach_platz_id=NEW.von_platz_id OR b.von_platz_id=NEW.von_platz_id)
 ),0) + 0.000001 THEN RAISE(ABORT,'Nicht genug Bestand fuer Umlagerung') END;
END;

-- Incoming stock from outside must not exceed the original catalogued quantity.
CREATE TRIGGER trg_einlagerung BEFORE INSERT ON lagerbewegung
WHEN NEW.bewegungstyp='EINLAGERUNG'
BEGIN
 SELECT CASE WHEN NEW.menge + COALESCE((SELECT SUM(menge) FROM lagerbewegung
   WHERE material_id=NEW.material_id AND bewegungstyp='EINLAGERUNG'),0) >
   (SELECT anfangsmenge FROM materialposition WHERE material_id=NEW.material_id) + 0.000001
 THEN RAISE(ABORT,'Einlagerung uebersteigt katalogisierte Anfangsmenge') END;
END;
