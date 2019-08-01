-- Deploy ovid:data/moving-from-oracle-to-postgresql to sqlite

BEGIN;

    INSERT INTO articles (title, directory, slug, created)
         VALUES ( 'Moving from Oracle to PostgreSQL', '/articles/', 'moving-from-oracle-to-postgresql', datetime('now'));

COMMIT;
