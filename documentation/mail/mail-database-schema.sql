--
-- mail-database-schema.sql
--
-- Created by Joel Lopes Da Silva on 1/10/2013.
-- Copyright © 2131-2016 Joel Lopes Da Silva. All rights reserved.
--

DROP TABLE IF EXISTS domains;
DROP TABLE IF EXISTS aliases;
DROP TABLE IF EXISTS mailboxes;


CREATE TABLE domains (
    domain      varchar(255) NOT NULL, 
    aliases     boolean      NOT NULL   DEFAULT true, 
    mailboxes   boolean      NOT NULL   DEFAULT false, 
    maxquota    bigint       NOT NULL   DEFAULT 0, 
    active      boolean      NOT NULL   DEFAULT true, 
    created     timestamptz  NOT NULL   DEFAULT current_timestamp, 
    modified    timestamptz  NOT NULL   DEFAULT current_timestamp, 
    PRIMARY KEY (domain)
);

CREATE TABLE aliases (
    source      varchar(255) NOT NULL, 
    destination text         NOT NULL, 
    active      boolean      NOT NULL   DEFAULT true, 
    created     timestamptz  NOT NULL   DEFAULT current_timestamp, 
    modified    timestamptz  NOT NULL   DEFAULT current_timestamp, 
    PRIMARY KEY (source)
);

CREATE TABLE mailboxes (
    address     varchar(255) NOT NULL, 
    password    varchar(255) NOT NULL, 
    quota       bigint       NOT NULL   DEFAULT 0, 
    active      boolean      NOT NULL   DEFAULT true, 
    created     timestamptz  NOT NULL   DEFAULT current_timestamp, 
    modified    timestamptz  NOT NULL   DEFAULT current_timestamp, 
    PRIMARY KEY (address)
);


GRANT CONNECT ON DATABASE mail TO dovecot;
GRANT SELECT ON TABLE domains TO dovecot;
GRANT SELECT ON TABLE mailboxes TO dovecot;
GRANT CONNECT ON DATABASE mail TO postfix;
GRANT SELECT ON TABLE domains TO postfix;
GRANT SELECT ON TABLE aliases TO postfix;

