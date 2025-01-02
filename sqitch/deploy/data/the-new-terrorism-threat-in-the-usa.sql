-- Deploy ovid:data/the-new-terrorism-threat-in-the-usa to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'The New Terrorism Threat in the USA',
           'the-new-terrorism-threat-in-the-usa',
           'When Luigi Mangione murdered Brian Thompson, the CEO of UnitedHealthcare, it was a form of terrorism the US rarely sees.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
