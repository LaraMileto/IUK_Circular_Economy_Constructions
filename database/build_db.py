"""Build the reproducible Zweitbau case-study database. Python standard library only."""
from pathlib import Path
import sqlite3

folder = Path(__file__).resolve().parent
target = folder / "zweitbau.sqlite"
if target.exists():
    target.unlink()
with sqlite3.connect(target) as conn:
    conn.execute("PRAGMA foreign_keys=ON")
    for name in ("01_schema.sql", "02_setup.sql", "03_fuenf_geschaeftsvorfaelle.sql"):
        conn.executescript((folder / name).read_text(encoding="utf-8"))
    integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
    fk_errors = conn.execute("PRAGMA foreign_key_check").fetchall()
    assert integrity == "ok" and not fk_errors, (integrity, fk_errors)
    print(f"Created {target}")
    print("Material | Physical | Open reservations | Available to promise")
    for record in conn.execute("SELECT materialart, physischer_bestand, offen_reserviert, frei_verfuegbar FROM v_verfuegbarkeit ORDER BY material_id"):
        print(" | ".join(map(str, record)))
    print("Integrity check: OK; foreign keys: OK")
