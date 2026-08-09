-- Deploy ovid:data/fix-escape-title to sqlite

-- The template preamble has always said "Adventures", so the page itself
-- renders correctly; only this row carried the typo, which leaked into every
-- generated index listing. The slug keeps the misspelling on purpose -- the
-- URL is published and must not move.

BEGIN;

    UPDATE articles
       SET title = 'Escape!-Adventures in AI Gaming'
     WHERE slug = 'escape-adventurs-in-ai-gaming';

COMMIT;
