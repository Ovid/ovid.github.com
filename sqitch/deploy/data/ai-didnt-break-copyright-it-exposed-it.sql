-- Deploy ovid:data/ai-didnt-break-copyright-it-exposed-it to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'AI didn''t break copyright. It exposed it',
           'ai-didnt-break-copyright-it-exposed-it',
           'Many people are upset about AI and copyright violations. The copyright mess is far more complicated than they think.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
