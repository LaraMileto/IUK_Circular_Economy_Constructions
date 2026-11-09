# Zweitbau — IKT Case C, Task 4 (SQLite)

## Assignment
Implement the ER model as a relational SQLite database and record **five business transactions from one of the three EPC processes**. We chose **Process 2: Reservierung, Verkauf und Verwertung**. All persons, firms, dates, addresses and quantities here are *fictional example data*.

**Source:** `Cases-IKT-HS2026.pdf`, Case C, Task 4 (p. 8); general SQLite requirements (p. 2). Relational tables, PK/FK, constraints and SQL follow `VL04 Datenbanken und BI 2026.pdf`.

## VS Code: rebuild the database

1. Put this directory inside your cloned Git repository, e.g. `database/`.
2. Open the repository in VS Code, then **Terminal → New Terminal**.
3. Run `python3 database/build_db.py` from the repository root (or `python3 build_db.py` if your terminal is already in `database/`). No packages are needed.
4. Run `python3 database/test_db.py` to verify the model and data.
5. Open `database/zweitbau.sqlite` in SQLiteStudio or another SQLite-compatible viewer; use `04_pruefen.sql` to inspect the records.
6. Commit and push with Source Control, or `git add database && git commit -m "Implement Zweitbau SQLite database and five Process 2 transactions" && git push`.

**The `.sqlite` database file is part of the case submission.** Submit it separately from your PowerPoint via Canvas/StudyNet. GitHub is a working repository, not a substitute for the required submission.

## Directory

- `01_schema.sql` — 14 relational tables, primary/foreign keys, checks, views and integrity triggers.
- `02_setup.sql` — master data and two initial warehouse receipts (setup, NOT part of the five business transactions).
- `03_fuenf_geschaeftsvorfaelle.sql` — exactly five separately delimited `BEGIN/COMMIT` business transactions.
- `04_pruefen.sql` — database checks, stock report and labelled business cases.
- `build_db.py` — recreates the `.sqlite` file reproducibly.
- `test_db.py` — assertions for integrity, quantity consistency and invalid transactions.
- `zweitbau.sqlite` — generated SQLite database, ready to open/submit.

## Five Process 2 business transactions

| Business event | Tables changed | Item | Quantity |
|---|---|---|---:|
| GV1 Reservation | reservierung + reservierungsposition | Individual window #101 | 1 Stueck |
| GV2 Reservation | reservierung + reservierungsposition | Brick lot #102 | 150 Stueck |
| GV3 Sale and handover | verkauf + verkaufsposition + lagerbewegung + reservierung | Window #101 | 1 Stueck |
| GV4 Partial sale and handover | verkauf + verkaufsposition + lagerbewegung | Brick lot #102 | 100 Stueck |
| GV5 Documented disposal and removal | verwertung + lagerbewegung | Brick lot #102 | 25 Stueck |

**Expected inventory after GV5:** window 0 in stock; brick lot has **375** physically in stock, **50** remaining reserved, and **325** freely available. Calculation: 500 − 100 sold − 25 disposed = 375; 150 reserved − 100 fulfilled = 50; 375 − 50 = 325.

## Model assumptions & limitations

- The tracked `materialposition` can be `EINZELBAUTEIL` (quantity 1, unit `Stueck`) or `CHARGE` (positive quantity and explicit unit).
- All tracked items belong to one source building through one dismantling project.
- `lagerbewegung` stores source/destination positions; physical stock is *derived* from movements in `v_lagerbestand`.
- `reservierungsposition` tracks promises, not physical stock; sold reserved quantities are derived via `verkaufsposition.res_position_id`.
- Pre-arrival reservation is supported **when an item is inspected/cleared and has not yet had its first warehouse receipt**: promiseable quantity comes from catalogued initial stock; `physischer_bestand` remains zero until receipt. `erwartet_verfuegbar_ab` records anticipated availability; scheduling guarantees are not modelled.
- `verwertung` distinguishes confirmed reuse from disposal. **A sale alone does not prove reuse.** GV5 demonstrates disposal of unsold bricks.
- Views and triggers enforce core demo quantity constraints. This is a prototype: not all possible edit/update/delete workflows or real-world transfers are controlled, and it does not replace a complete production inventory system. For reliable audit history, treat booked movements and transaction lines as immutable.
- One source region and one warehouse reflect Zweitbau's initial scale. More regions/warehouses can be added later for growth modelling.
- In these sample data, all material quantities use `Stueck`. Future reporting must not add quantities in incompatible units (e.g. `m2` plus `Stueck`).

