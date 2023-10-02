-- Deploy ovid:data/searching-for-alien-life to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Searching for Alien Life',
           'searching-for-alien-life',
           'The title seems like clickbait, but it''s real. There''s not only amazing research being done on the origin of life, but there are extremely intriguing results out there.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
