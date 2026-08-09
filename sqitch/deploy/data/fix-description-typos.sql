-- Deploy ovid:data/fix-description-typos to sqlite

BEGIN;

    UPDATE articles SET description = replace(description, 'Ths is why',   'This is why')    WHERE slug = 'ai-coding-typing-was-never-the-bottleneck';
    UPDATE articles SET description = replace(description, 'I explaine ',  'I explain ')     WHERE slug = 'babylonian-numbers-for-8-year-olds';
    UPDATE articles SET description = replace(description, 'mathmetician', 'mathematician')  WHERE slug = 'the-easy-solution-to-quadratic-equations';
    UPDATE articles SET description = replace(description, 'prorcess',     'process')        WHERE slug = 'life-on-venus';
    UPDATE articles SET description = replace(description, 'Teenages',     'Teenagers')      WHERE slug = 'how-i-got-caught-in-high-school';
    UPDATE articles SET description = replace(description, 'millenia',     'millennia')      WHERE slug = 'is-math-discovered-or-invented';
    UPDATE articles SET description = replace(description, 'you to  use',  'you to use')     WHERE slug = 'introducing-the-arxiv-explorer';

COMMIT;
