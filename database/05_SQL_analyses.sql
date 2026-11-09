-- Task 5 | Zweitbau | Two growth-planning analyses
-- Uses the existing Task 4 database unchanged.
-- Data are fictional, illustrative test data.

-- ANALYSE 1: Verkaufsnachfrage nach Kundenregion und Materialart.
-- At least four tables: verkauf, kunde, verkaufsposition, materialposition.
-- Sales quantities are summed only within the same material measurement unit.
-- 'region' is the CUSTOMER region (demand origin), not necessarily the warehouse region.
SELECT
    k.region AS kundenregion,
    m.materialart,
    m.einheit,
    SUM(vp.menge) AS verkaufte_menge,
    COUNT(DISTINCT v.verkauf_id) AS anzahl_verkaeufe
FROM verkauf AS v
JOIN kunde AS k ON k.kunde_id = v.kunde_id
JOIN verkaufsposition AS vp ON vp.verkauf_id = v.verkauf_id
JOIN materialposition AS m ON m.material_id = vp.material_id
GROUP BY k.region, m.materialart, m.einheit
ORDER BY k.region, verkaufte_menge DESC, m.materialart;

-- ANALYSE 2: Aktueller physischer Lagerbestand nach Lager und Materialart.
-- Movement-based balances avoid confusing reservations with physical stock.
-- INNER JOIN is intentional: show inventory that currently exists in locations,
-- not sold-out historical positions.
-- At least five tables: lagerbewegung, lagerplatz, lager, region, materialposition.
-- Separately aggregate movements per location to avoid counting incoming transfers twice.
WITH platzbestand AS (
    SELECT
        b.material_id,
        b.nach_platz_id AS lagerplatz_id,
        b.menge AS mengenaenderung
    FROM lagerbewegung AS b
    WHERE b.nach_platz_id IS NOT NULL
    UNION ALL
    SELECT
        b.material_id,
        b.von_platz_id AS lagerplatz_id,
        -b.menge AS mengenaenderung
    FROM lagerbewegung AS b
    WHERE b.von_platz_id IS NOT NULL
),
bestand_pro_lager AS (
    SELECT
        l.lager_id,
        l.name AS lager,
        r.name AS lagerregion,
        m.material_id,
        m.materialart,
        m.einheit,
        SUM(pb.mengenaenderung) AS physischer_bestand
    FROM platzbestand AS pb
    JOIN lagerplatz AS lp ON lp.lagerplatz_id = pb.lagerplatz_id
    JOIN lager AS l ON l.lager_id = lp.lager_id
    JOIN region AS r ON r.region_id = l.region_id
    JOIN materialposition AS m ON m.material_id = pb.material_id
    GROUP BY l.lager_id, l.name, r.name, m.material_id, m.materialart, m.einheit
)
SELECT
    lagerregion,
    lager,
    materialart,
    einheit,
    SUM(physischer_bestand) AS lagerbestand
FROM bestand_pro_lager
WHERE physischer_bestand > 0
GROUP BY lagerregion, lager, materialart, einheit
ORDER BY lagerregion, lager, lagerbestand DESC, materialart;
