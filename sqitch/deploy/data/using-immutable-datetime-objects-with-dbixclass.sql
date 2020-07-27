-- Deploy ovid:data/using-immutable-datetime-objects-with-dbixclass to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Immutable DateTime Objects with DBIx::Class',
           'using-immutable-datetime-objects-with-dbixclass',
           'DBIx::Class is a fantastic ORM for Perl, but its standard DateTime inflation is dangerous. Let’s fix that.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
