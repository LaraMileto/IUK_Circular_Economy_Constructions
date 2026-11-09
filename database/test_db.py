"""Quick assertions for the demo data and integrity rules (no external packages)."""
from pathlib import Path
import sqlite3

path = Path(__file__).resolve().parent / 'zweitbau.sqlite'
with sqlite3.connect(path) as conn:
    conn.execute('PRAGMA foreign_keys=ON')
    assert conn.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    assert conn.execute('PRAGMA foreign_key_check').fetchall() == []
    assert conn.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").fetchone()[0] == 14
    rows = conn.execute('SELECT material_id, physischer_bestand, offen_reserviert, frei_verfuegbar FROM v_verfuegbarkeit ORDER BY material_id').fetchall()
    assert rows == [(101,0.0,0,0.0),(102,375.0,50.0,325.0)], rows
    assert conn.execute('SELECT COUNT(*) FROM reservierung').fetchone()[0] == 2
    assert conn.execute('SELECT COUNT(*) FROM verkauf').fetchone()[0] == 2
    assert conn.execute('SELECT COUNT(*) FROM verwertung').fetchone()[0] == 1
    for sql, args in [
        ('INSERT INTO reservierungsposition VALUES (3,2,102,400)', ()),
        ("INSERT INTO lagerbewegung (material_id,von_platz_id,datum,menge,bewegungstyp,verwertung_id) VALUES (102,2,'2026-11-06',350,'AUSLAGERUNG',1)",()),
    ]:
        try:
            conn.execute(sql,args)
        except sqlite3.IntegrityError:
            pass
        else:
            raise AssertionError('Expected rule to reject invalid transaction: '+sql)
        conn.rollback()
print('ALL TESTS PASSED: 14 tables, 5 cases, quantities, keys, rule enforcement')
