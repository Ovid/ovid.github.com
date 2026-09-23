-- Deploy ovid:data/paads-test-roadmap-instant-test-suites to sqlite

BEGIN;

    INSERT INTO articles (title, slug, description, article_type_id, sort_order)
         VALUES (
           'PAAD''s Test Roadmap: Instant Test Suites!',
           'paads-test-roadmap-instant-test-suites',
           'After training many development teams on writing production quality code with AI, the primary blocker for legacy systems was the lack of a test suite. Now, you can create one almost immediately with PAAD''s test roadmap skill. Unfortunately, it keeps finding-zero-day exploits.',
           (SELECT article_type_id FROM article_types WHERE type = 'article'),
           (SELECT max(sort_order) FROM articles) + 1 
         );

COMMIT;
