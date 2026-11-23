# 07 — Database

**Purpose:** Define persistence identity, constraints, migrations, and dangerous operations.

**Confidence note:** no schema, migration, database configuration, or data-access code was found on 2026-11-23. The code wins (see 16).

There is currently no database to document. Before persistence is implemented, specify identity
and ownership, foreign keys, delete behavior, retention, indexes, backups, and migration rollback.
The business requirements explicitly call for retention limits and privacy protection; these must
be concrete schema and operational rules, not assumptions.
