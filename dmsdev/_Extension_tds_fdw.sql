--
-- Name: tds_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tds_fdw WITH SCHEMA public;

--
-- Name: EXTENSION tds_fdw; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION tds_fdw IS 'Foreign data wrapper for querying a TDS database (Sybase or Microsoft SQL Server)';

