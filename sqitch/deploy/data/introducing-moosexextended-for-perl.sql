-- Deploy ovid:data/introducing-moosexextended-for-perl to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Introducing MooseX::Extended for Perl',
           'introducing-moosexextended-for-perl',
           'MooseX::Extended provides safe defaults, best practices, and useful features for Moose.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
