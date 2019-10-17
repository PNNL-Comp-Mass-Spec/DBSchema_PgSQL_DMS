--
-- Name: trig_db_ddl_command_end; Type: EVENT TRIGGER; Schema: -; Owner: d3l243
--

CREATE EVENT TRIGGER trig_db_ddl_command_end ON ddl_command_end
         WHEN TAG IN ('ALTER AGGREGATE', 'ALTER CONVERSION', 'ALTER DOMAIN', 'ALTER EXTENSION', 'ALTER FOREIGN DATA WRAPPER', 'ALTER FOREIGN TABLE', 'ALTER FUNCTION', 'ALTER MATERIALIZED VIEW', 'ALTER OPERATOR', 'ALTER OPERATOR CLASS', 'ALTER OPERATOR FAMILY', 'ALTER POLICY', 'ALTER PROCEDURE', 'ALTER SCHEMA', 'ALTER SEQUENCE', 'ALTER SERVER', 'ALTER TABLE', 'ALTER TEXT SEARCH CONFIGURATION', 'ALTER TEXT SEARCH DICTIONARY', 'ALTER TEXT SEARCH PARSER', 'ALTER TEXT SEARCH TEMPLATE', 'ALTER TRIGGER', 'ALTER TYPE', 'ALTER USER MAPPING', 'ALTER VIEW', 'CREATE AGGREGATE', 'CREATE CAST', 'CREATE CONVERSION', 'CREATE DOMAIN', 'CREATE EXTENSION', 'CREATE FOREIGN DATA WRAPPER', 'CREATE FOREIGN TABLE', 'CREATE FUNCTION', 'CREATE INDEX', 'CREATE MATERIALIZED VIEW', 'CREATE OPERATOR', 'CREATE OPERATOR CLASS', 'CREATE OPERATOR FAMILY', 'CREATE POLICY', 'CREATE PROCEDURE', 'CREATE RULE', 'CREATE SCHEMA', 'CREATE SEQUENCE', 'CREATE SERVER', 'CREATE TABLE', 'CREATE TABLE AS', 'CREATE TEXT SEARCH CONFIGURATION', 'CREATE TEXT SEARCH DICTIONARY', 'CREATE TEXT SEARCH PARSER', 'CREATE TEXT SEARCH TEMPLATE', 'CREATE TRIGGER', 'CREATE TYPE', 'CREATE USER MAPPING', 'CREATE VIEW', 'DROP AGGREGATE', 'DROP CAST', 'DROP CONVERSION', 'DROP DOMAIN', 'DROP EXTENSION', 'DROP FOREIGN DATA WRAPPER', 'DROP FOREIGN TABLE', 'DROP FUNCTION', 'DROP INDEX', 'DROP MATERIALIZED VIEW', 'DROP OPERATOR', 'DROP OPERATOR CLASS', 'DROP OPERATOR FAMILY', 'DROP OWNED', 'DROP POLICY', 'DROP PROCEDURE', 'DROP RULE', 'DROP SCHEMA', 'DROP SEQUENCE', 'DROP SERVER', 'DROP TABLE', 'DROP TEXT SEARCH CONFIGURATION', 'DROP TEXT SEARCH DICTIONARY', 'DROP TEXT SEARCH PARSER', 'DROP TEXT SEARCH TEMPLATE', 'DROP TRIGGER', 'DROP TYPE', 'DROP USER MAPPING', 'DROP VIEW', 'GRANT', 'IMPORT FOREIGN SCHEMA', 'REFRESH MATERIALIZED VIEW', 'REVOKE', 'SECURITY LABEL', 'SELECT INTO')
   EXECUTE FUNCTION public.log_ddl_command_end();


ALTER EVENT TRIGGER trig_db_ddl_command_end OWNER TO d3l243;
