-- Deploy ovid:data/wardley-maps-in-a-nutshell to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Wardley Maps In a Nutshell',
           'wardley-maps-in-a-nutshell',
           'Wardley Maps are an amazing business tool for planning, but you can suffer information overload when you read about them online. Read this quickstart to get up and running with them.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
