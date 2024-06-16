--
-- Name: get_taxid_child_count(integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.get_taxid_child_count(_taxonomyid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**  	Counts the number of nodes with Parent_Tax_ID equal to _taxonomyID
**
**  Return value: integer; 0 if no children
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/29/2022 mem - Ported to PostgreSQL
**          05/19/2023 mem - Remove redundant parentheses
**          07/11/2023 mem - Use COUNT(tax_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _count int;
BEGIN
    SELECT COUNT(tax_id)
    INTO _count
    FROM ont.t_ncbi_taxonomy_nodes
    WHERE parent_tax_id = _taxonomyID;

    RETURN _count;
END
$$;


ALTER FUNCTION ont.get_taxid_child_count(_taxonomyid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_taxid_child_count(_taxonomyid integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.get_taxid_child_count(_taxonomyid integer) IS 'GetTaxIDChildCount';

