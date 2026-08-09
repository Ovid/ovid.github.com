-- Revert ovid:data/fix-escape-title from sqlite

BEGIN;

    UPDATE articles
       SET title = 'Escape!-Adventurs in AI Gaming'
     WHERE slug = 'escape-adventurs-in-ai-gaming';

COMMIT;
