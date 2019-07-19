-- Deploy ovid:data/project-500 to sqlite

BEGIN;

    INSERT INTO articles (title, directory, slug, created)
         VALUES ( 'Case Study: 500 TPS', '/articles/', 'project-500', datetime('now'));

COMMIT;
