-- Verify ovid:data/fix-escape-title on sqlite

BEGIN;

-- Fails (division by zero) unless exactly one row carries the fixed title.
SELECT 1 / (
    SELECT count(*) = 1
      FROM articles
     WHERE slug  = 'escape-adventurs-in-ai-gaming'
       AND title = 'Escape!-Adventures in AI Gaming'
);

ROLLBACK;
