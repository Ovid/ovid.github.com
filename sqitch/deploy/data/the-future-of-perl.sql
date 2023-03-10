-- Deploy ovid:data/the-future-of-perl to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'The Future of Perl',
           'the-future-of-perl',
           'With the new Corinna object system coming to Perl, many people are wondering what the future looks like for the language.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
