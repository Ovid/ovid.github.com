-- Revert ovid:data/fix-description-typos from sqlite

BEGIN;

    UPDATE articles SET description = replace(description, 'This is why',   'Ths is why')   WHERE slug = 'ai-coding-typing-was-never-the-bottleneck';
    UPDATE articles SET description = replace(description, 'I explain ',    'I explaine ')  WHERE slug = 'babylonian-numbers-for-8-year-olds';
    UPDATE articles SET description = replace(description, 'mathematician', 'mathmetician') WHERE slug = 'the-easy-solution-to-quadratic-equations';
    UPDATE articles SET description = replace(description, 'process',       'prorcess')     WHERE slug = 'life-on-venus';
    UPDATE articles SET description = replace(description, 'Teenagers',     'Teenages')     WHERE slug = 'how-i-got-caught-in-high-school';
    UPDATE articles SET description = replace(description, 'millennia',     'millenia')     WHERE slug = 'is-math-discovered-or-invented';
    UPDATE articles SET description = replace(description, 'you to use',    'you to  use')  WHERE slug = 'introducing-the-arxiv-explorer';

COMMIT;
