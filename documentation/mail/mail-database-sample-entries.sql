--
-- mail-database-sample-entries.sql
--
-- Created by Joel Lopes Da Silva on 1/10/2013.
-- Copyright © 203-2016 Joel Lopes Da Silva. All rights reserved.
--

INSERT INTO domains (domain, aliases, mailboxes, maxquota) VALUES ('foo.com',          true, false, 0);
INSERT INTO domains (domain, aliases, mailboxes, maxquota) VALUES ('active.foo.com',   true, true,  55);
INSERT INTO domains (domain, aliases, mailboxes, maxquota) VALUES ('disabled.foo.com', true, true,  0);
UPDATE domains SET active = false WHERE domain = 'disabled.foo.com';

INSERT INTO aliases (source, destination) VALUES ('first@foo.com',           'destination-1@bar.org');
INSERT INTO aliases (source, destination) VALUES ('second@foo.com',          'destination-2@bar.org');
INSERT INTO aliases (source, destination) VALUES ('third@foo.com',           'destination-3@bar.org');
INSERT INTO aliases (source, destination) VALUES ('first@active.foo.com',    'destination-1@active.bar.org');
INSERT INTO aliases (source, destination) VALUES ('second@active.foo.com',   'destination-2@active.bar.org');
INSERT INTO aliases (source, destination) VALUES ('third@active.foo.com',    'destination-3@active.bar.org');
INSERT INTO aliases (source, destination) VALUES ('first@disabled.foo.com',  'destination-1@disabled.bar.org');
INSERT INTO aliases (source, destination) VALUES ('second@disabled.foo.com', 'destination-2@disabled.bar.org');
INSERT INTO aliases (source, destination) VALUES ('third@disabled.foo.com',  'destination-3@disabled.bar.org');
UPDATE aliases SET active = false WHERE source = 'second@foo.com';
UPDATE aliases SET active = false WHERE source = 'second@active.foo.com';
UPDATE aliases SET active = false WHERE source = 'second@disabled.foo.com';

INSERT INTO mailboxes (address, password, quota) VALUES ('addr-1@foo.com',          'pass1', 0);
INSERT INTO mailboxes (address, password, quota) VALUES ('addr-2@foo.com',          'pass2', 10);
INSERT INTO mailboxes (address, password, quota) VALUES ('addr-3@foo.com',          'pass3', 60);
INSERT INTO mailboxes (address, password, quota) VALUES ('addr-1@active.foo.com',   'pass1', 0);
INSERT INTO mailboxes (address, password, quota) VALUES ('addr-2@active.foo.com',   'pass2', 10);
INSERT INTO mailboxes (address, password, quota) VALUES ('addr-3@active.foo.com',   'pass3', 60);
INSERT INTO mailboxes (address, password, quota) VALUES ('addr-1@disabled.foo.com', 'pass1', 0);
INSERT INTO mailboxes (address, password, quota) VALUES ('addr-2@disabled.foo.com', 'pass2', 10);
INSERT INTO mailboxes (address, password, quota) VALUES ('addr-3@disabled.foo.com', 'pass3', 60);
UPDATE mailboxes SET active = false WHERE address = 'addr-2@foo.com';
UPDATE mailboxes SET active = false WHERE address = 'addr-2@active.foo.com';
UPDATE mailboxes SET active = false WHERE address = 'addr-2@disabled.foo.com';

