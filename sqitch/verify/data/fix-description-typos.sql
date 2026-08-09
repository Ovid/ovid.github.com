-- Verify ovid:data/fix-description-typos on sqlite

BEGIN;

-- Fails (division by zero) if any of the typos survive.
SELECT 1 / (
    SELECT count(*) = 0
      FROM articles
     WHERE description LIKE '%Ths %'
        OR description LIKE '%explaine %'
        OR description LIKE '%mathmetician%'
        OR description LIKE '%prorcess%'
        OR description LIKE '%Teenages%'
        OR description LIKE '%millenia%'
        OR description LIKE '%  %'
);

ROLLBACK;
