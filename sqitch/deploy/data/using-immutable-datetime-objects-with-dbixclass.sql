-- Deploy ovid:data/using-immutable-datetime-objects-with-dbixclass to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'Why Do We Want Immutable Objects?',
           'using-immutable-datetime-objects-with-dbixclass',
           'I’m building a new object-oriented system to ship with the Perl language. It tries to default to immutable objects. Why is that?',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
