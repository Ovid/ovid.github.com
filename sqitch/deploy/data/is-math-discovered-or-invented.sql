-- Deploy ovid:data/is-math-discovered-or-invented to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Is Math Discovered or Invented?',
           'is-math-discovered-or-invented',
           'Over the millenia, we have argued back and forth about whether math is discovered or invented. The battle is fascinating and could have profound implications on our understanding of reality.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
