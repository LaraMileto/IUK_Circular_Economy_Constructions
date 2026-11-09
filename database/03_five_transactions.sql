-- Exactly five identifiable transactions from Process 2 (P2).
-- All records are fictitious demonstration data.
PRAGMA foreign_keys=ON;

-- GV 1: Customer 1 reserves the individual window (quantity = 1).
BEGIN TRANSACTION;
INSERT INTO reservierung VALUES (1,1,'2026-11-01','AKTIV');
INSERT INTO reservierungsposition VALUES (1,1,101,1);
COMMIT;

-- GV 2: Customer 2 reserves 150 bricks from the lot of 500.
BEGIN TRANSACTION;
INSERT INTO reservierung VALUES (2,2,'2026-11-02','AKTIV');
INSERT INTO reservierungsposition VALUES (2,2,102,150);
COMMIT;

-- GV 3: Window is sold and physically handed over to Customer 1.
BEGIN TRANSACTION;
INSERT INTO verkauf VALUES (1,1,'2026-11-03');
INSERT INTO verkaufsposition VALUES (1,1,101,1,1);
INSERT INTO lagerbewegung (bewegung_id,material_id,von_platz_id,nach_platz_id,datum,menge,bewegungstyp,verk_position_id)
VALUES (3,101,1,NULL,'2026-11-03',1,'AUSLAGERUNG',1);
UPDATE reservierung SET status='ERLEDIGT' WHERE reservierung_id=1;
COMMIT;

-- GV 4: Customer 2 buys 100 of the reserved 150 bricks.
-- Remaining active reservation = 50 bricks; unsold warehouse stock = 400.
BEGIN TRANSACTION;
INSERT INTO verkauf VALUES (2,2,'2026-11-04');
INSERT INTO verkaufsposition VALUES (2,2,102,2,100);
INSERT INTO lagerbewegung (bewegung_id,material_id,von_platz_id,nach_platz_id,datum,menge,bewegungstyp,verk_position_id)
VALUES (4,102,2,NULL,'2026-11-04',100,'AUSLAGERUNG',2);
COMMIT;

-- GV 5: 25 unreserved bricks are disposed of; the disposal route is documented.
-- This is not a confirmed reuse, and is not linked to a sale.
BEGIN TRANSACTION;
INSERT INTO verwertung VALUES (1,102,NULL,'2026-11-05','ENTSORGUNG',25,'Entsorgungsbetrieb Beispiel','Entsorgungsnachweis DEMO-001');
INSERT INTO lagerbewegung (bewegung_id,material_id,von_platz_id,nach_platz_id,datum,menge,bewegungstyp,verwertung_id)
VALUES (5,102,2,NULL,'2026-11-05',25,'AUSLAGERUNG',1);
COMMIT;
