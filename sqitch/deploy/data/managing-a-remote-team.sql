-- Deploy ovid:data/managing-a-remote-team to sqlite

BEGIN;

    INSERT INTO articles (title, directory, slug, created)
         VALUES ( 'Managing a Remote Team', '/articles/', 'managing-a-remote-team', datetime('now'));

COMMIT;
