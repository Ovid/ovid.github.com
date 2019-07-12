-- Revert ovid:data/managing-a-remote-team to sqlite

BEGIN;

    DELETE FROM articles WHERE slug = 'managing-a-remote-team';

COMMIT;
