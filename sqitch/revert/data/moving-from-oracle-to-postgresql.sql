-- Revert ovid:data/moving-from-oracle-to-postgresql to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'moving-from-oracle-to-postgresql';

COMMIT;
