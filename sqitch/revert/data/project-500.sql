-- Revert ovid:data/project-500 to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'project-500';

COMMIT;
