--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE d3l243;
ALTER ROLE d3l243 WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS
CREATE ROLE dmsreader;
ALTER ROLE dmsreader WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS
CREATE ROLE dmswebuser;
ALTER ROLE dmswebuser WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS
CREATE ROLE gibb166;
ALTER ROLE gibb166 WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS
CREATE ROLE lcmsnetuser;
ALTER ROLE lcmsnetuser WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS
CREATE ROLE pceditor;
ALTER ROLE pceditor WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS
CREATE ROLE pgdms;
ALTER ROLE pgdms WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS
CREATE ROLE pgwatch2;
ALTER ROLE pgwatch2 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS CONNECTION LIMIT 50
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS
CREATE ROLE readaccess;
ALTER ROLE readaccess WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE "svc-dms";
ALTER ROLE "svc-dms" WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS
CREATE ROLE writeaccess;
ALTER ROLE writeaccess WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;

--
-- User Configurations
--


--
-- Role memberships
--

GRANT pg_monitor TO pgwatch2 WITH INHERIT TRUE GRANTED BY postgres;
GRANT readaccess TO dmsreader WITH INHERIT TRUE GRANTED BY postgres;
GRANT readaccess TO dmswebuser WITH INHERIT TRUE GRANTED BY postgres;
GRANT readaccess TO lcmsnetuser WITH INHERIT TRUE GRANTED BY postgres;
GRANT readaccess TO pceditor WITH INHERIT TRUE GRANTED BY postgres;
GRANT readaccess TO pgdms WITH INHERIT TRUE GRANTED BY postgres;
GRANT readaccess TO pgwatch2 WITH INHERIT TRUE GRANTED BY postgres;
GRANT readaccess TO "svc-dms" WITH INHERIT TRUE GRANTED BY postgres;
GRANT writeaccess TO dmswebuser WITH INHERIT TRUE GRANTED BY postgres;
GRANT writeaccess TO pgdms WITH INHERIT TRUE GRANTED BY postgres;
GRANT writeaccess TO "svc-dms" WITH INHERIT TRUE GRANTED BY postgres;






--
-- PostgreSQL database cluster dump complete
--

