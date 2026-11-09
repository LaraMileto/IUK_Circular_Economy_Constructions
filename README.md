# IUK_Circular_Economy_Constructions
# Zweitbau — Circular Economy in Construction

**University of St. Gallen (HSG)**  
**Course:** Informations- und Kommunikationstechnologien (IKT)  
**Semester:** Autumn 2026  
**Case C: Zweitbau**

## 1. Project Overview

Zweitbau is a fictional Swiss company specialising in the recovery, preparation, storage, and resale of reusable building components from demolition projects.

Its core value proposition is the **end-to-end traceability of construction materials**, from their original building through dismantling, inspection, warehousing, reservation, and sale to their eventual reuse or disposal.

The company initially operates one warehouse and handles approximately two dismantling projects per month. Its long-term objective is to expand into three regions within four years.

This project develops a business process, data, and IT architecture concept to support that growth.

## 2. Project Objectives

The project addresses seven tasks:

1. **Business scope and assumptions:** Define the relevant business activities and modelling assumptions.
2. **Business process modelling:** Design three Event-driven Process Chains (EPCs).
3. **Data modelling:** Develop an Entity-Relationship (ER) model.
4. **Database implementation:** Implement a relational SQLite database and five business transactions.
5. **SQL analyses:** Develop two analyses to support growth planning.
6. **Enterprise Architecture Management:** Identify scaling risks and corresponding architecture principles.
7. **Critical AI reflection:** Document and critically evaluate the use of AI throughout the project.

## 3. Business Processes

Three business processes form the basis of the information system.

### Process 1 — Component Recovery and Warehousing

*Bauteilgewinnung und Einlagerung*

Covers component identification, cataloguing, inspections, selective dismantling, preparation, transportation, and warehousing.

### Process 2 — Reservation, Sales and Material Destination

*Reservierung, Verkauf und Verwertung*

Covers customer inquiries, availability checks, reservations, sales, and the documentation of material reuse or disposal.

### Process 3 — Management Information Provision

*Managementinformationsversorgung*

Aggregates operational data into management information supporting inventory planning, regional expansion, and strategic decision-making.

The processes are modelled using EPC notation introduced in the course.

## 4. Data Model

The database is based on an ER model containing **14 entities**, covering:

- Buildings and dismantling projects
- Building components and material lots
- Inspections
- Regions, warehouses, and storage locations
- Warehouse movements
- Customers and reservations
- Sales and sale positions
- Material reuse and disposal

### Hybrid Material Tracking

Zweitbau uses a hybrid tracking approach:

- **Individual components:** Windows, doors, and other individually identifiable items are registered separately.
- **Material lots:** Homogeneous materials, such as bricks, can be registered in quantities and sold or reserved partially.

Each tracked component or material lot receives a unique material identifier.

This design supports inventory management and material traceability while accommodating different material types.

## 5. SQLite Database Implementation

The conceptual ER model was transformed into a relational SQLite database.

The implementation includes:

- 14 relational tables
- Primary and foreign keys
- Integrity constraints and triggers
- Warehouse movement records
- Reservations and sales
- SQL views for inventory and availability calculations
- Five fictional business transactions

### Database Files

| File | Description |
|---|---|
| `01_schema.sql` | Creates tables, constraints, triggers, and views |
| `02_setup.sql` | Inserts initial reference and inventory data |
| `03_fuenf_geschaeftsvorfaelle.sql` | Implements five business transactions |
| `04_pruefen.sql` | Contains verification queries |
| `05_wachstumsanalysen.sql` | Contains the two SQL analyses |
| `build_db.py` | Builds the SQLite database |
| `test_db.py` | Runs automated validation tests |
| `zweitbau.sqlite` | Implemented SQLite database |

All database files are located in the `database/` directory.

## 6. Reproducing the Database

### Requirements

- Python 3 with the built-in `sqlite3` module
- A terminal or an IDE such as Visual Studio Code
- An optional SQLite viewer for inspecting the database

No additional Python packages are required for the database scripts.

### Build the Database

From the repository root, run:

`python3 database/build_db.py`

This creates or rebuilds `database/zweitbau.sqlite` using the SQL scripts.

### Run Validation Tests

`python3 database/test_db.py`

The tests verify the implemented tables, business transactions, quantities, keys, and selected integrity rules.

The five test transactions have been executed successfully in the development environment.

## 7. Five Business Transactions

The database demonstrates Process 2 using fictional test data.

| ID | Transaction | Quantity |
|---|---|---|
| GV1 | Reservation of an individual window | 1 unit |
| GV2 | Reservation of reclaimed bricks | 150 units |
| GV3 | Sale and handover of the window | 1 unit |
| GV4 | Partial sale of the reserved brick lot | 100 units |
| GV5 | Disposal of unsold bricks | 25 units |

### Example: Brick Inventory

Initial quantity: **500 bricks**

- Sold: 100 bricks
- Disposed of: 25 bricks
- Remaining physical stock: 375 bricks
- Still reserved: 50 bricks
- Freely available: **325 bricks**

The implementation distinguishes physical stock from active reservations, supporting quantity-based inventory management.

## 8. SQL Analyses for Growth Planning

Two SQL analyses were developed.

### Analysis 1 — Regional Demand

Identifies which material categories are purchased in different customer regions.

The query combines customer, sale, sale-position, and material information.

**Management purpose:** Identify regional demand patterns and support decisions about potential expansion markets.

### Analysis 2 — Regional Warehouse Inventory

Calculates physical material quantities stored in regional warehouses using inventory movement records.

**Management purpose:** Evaluate regional stock distribution and support warehouse and stock-transfer planning.

Both queries use multiple relational tables and can be found in `database/05_wachstumsanalysen.sql`.

The current results are based on fictional data from one region and are intended to demonstrate analytical functionality, not to justify actual expansion investments.

## 9. Enterprise Architecture Principles

Three architecture risks were identified for Zweitbau's planned expansion.

| Architecture risk | Proposed principle |
|---|---|
| Inconsistent or redundant data | Shared data model and unique identifiers |
| Complex integration with external partners | Standardised interfaces and loose coupling |
| Limited scalability | Modular and extensible system architecture |

These principles provide guidelines for the company's future IT architecture.

They represent proposed architectural decisions, not features fully implemented in the SQLite prototype.


## 11. Project Limitations

This implementation is an academic prototype rather than a production-ready enterprise system.

Important limitations include:

- Fictional test data
- One region and warehouse represented in the initial dataset
- Limited transaction volumes
- No implemented external partner APIs
- No production deployment or performance testing
- Business rules validated for the implemented test scenarios, not every possible operational exception

The purpose is to demonstrate the feasibility of the proposed information system and support the analysis of Zweitbau's growth requirements.

## 12. Academic Context

Developed as an individual case project for the course **Informations- und Kommunikationstechnologien (IKT)** at the University of St. Gallen, Autumn Semester 2026.

The Zweitbau business case and academic requirements originate from the course assignment *Cases-IKT-HS2026.pdf*.

All company records and transactions used in the implementation are fictional and intended exclusively for educational purposes.