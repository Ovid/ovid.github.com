-- Deploy ovid:data/agile-is-not-the-problem to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Agile is Not the Problem',
           'agile-is-not-the-problem',
           'Agile is getting a bad rap. It''s not agile who''s at fault, it''s the agile industrial complex.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
