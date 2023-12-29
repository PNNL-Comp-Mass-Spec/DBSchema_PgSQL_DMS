--
-- Name: get_mtdbs_for_peptide_db(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_mtdbs_for_peptide_db(_peptidedbname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a delimited list of MTS AMT tag databases whose source is the specified peptide database
**
**  Return value: comma-separated list
**
**  Auth:   mem
**  Date:   10/18/2012
**          06/21/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(mt_db_name, ', ' ORDER BY mt_db_name)
    INTO _result
    FROM t_mts_mt_dbs_cached
    WHERE peptide_db = _peptideDBName;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_mtdbs_for_peptide_db(_peptidedbname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_mtdbs_for_peptide_db(_peptidedbname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_mtdbs_for_peptide_db(_peptidedbname text) IS 'GetMTDBsForPeptideDB';

