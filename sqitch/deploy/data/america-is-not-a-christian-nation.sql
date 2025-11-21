-- Deploy ovid:data/america-is-not-a-christian-nation to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'America is not a Christian Nation',
           'america-is-not-a-christian-nation',
           'Understanding the history of the Treaty of Tripoli shows that America''s Founding Fathers didn''t Intend for the US to be a Christian Nation.',
           (SELECT article_type_id FROM article_types WHERE type = 'blog'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
