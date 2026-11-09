-- Initial data: master records and starting warehouse stock.
-- NOT counted among the five Process 2 transactions.
PRAGMA foreign_keys=ON;
BEGIN TRANSACTION;
INSERT INTO gebaeude VALUES (1,'Beispielstrasse 12, St. Gallen',1975);
INSERT INTO rueckbauprojekt VALUES (1,1,'2026-10-05','AKTIV');
INSERT INTO region VALUES (1,'Ostschweiz');
INSERT INTO lager VALUES (1,1,'Regionallager Ost');
INSERT INTO lagerplatz VALUES (1,1,'A-01');
INSERT INTO lagerplatz VALUES (2,1,'B-01');
INSERT INTO materialposition VALUES (101,1,'EINZELBAUTEIL','Fenster','120 x 140 cm','GUT',1975,1,'Stueck','2026-10-21','2026-10-25');
INSERT INTO materialposition VALUES (102,1,'CHARGE','Backsteine',NULL,'GUT',1975,500,'Stueck','2026-10-21','2026-10-25');
INSERT INTO pruefung VALUES (1,101,'2026-10-20','GEEIGNET','UNBEDENKLICH','Externe Fachpruefung');
INSERT INTO pruefung VALUES (2,102,'2026-10-20','GEEIGNET','UNBEDENKLICH','Externe Fachpruefung');
INSERT INTO kunde VALUES (1,'Bauherrschaft Beispiel AG','BAUHERRSCHAFT','Ostschweiz');
INSERT INTO kunde VALUES (2,'Handwerk Muster GmbH','HANDWERK','Ostschweiz');
INSERT INTO lagerbewegung (bewegung_id,material_id,von_platz_id,nach_platz_id,datum,menge,bewegungstyp)
VALUES (1,101,NULL,1,'2026-10-25',1,'EINLAGERUNG');
INSERT INTO lagerbewegung (bewegung_id,material_id,von_platz_id,nach_platz_id,datum,menge,bewegungstyp)
VALUES (2,102,NULL,2,'2026-10-25',500,'EINLAGERUNG');
COMMIT;
