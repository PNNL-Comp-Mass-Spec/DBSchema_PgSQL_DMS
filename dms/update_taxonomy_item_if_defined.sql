--
-- Name: update_taxonomy_item_if_defined(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_taxonomy_item_if_defined(IN _rank text, INOUT _value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      This procedure is called via get_taxonomy_value_by_taxonomy_id
**      (Note that get_taxonomy_value_by_taxonomy_id is called by add_update_organisms when auto-defining taxonomy)
**
**  The calling procedure must create table Tmp_TaxonomyInfo
**
**      CREATE TEMP TABLE Tmp_TaxonomyInfo (
**          Entry_ID int not null,
**          Rank text not null,
**          Name text not null
**      );
**
**  Arguments:
**    _rank    Taxonomy rank: 'superkingdom', 'kingdom', 'subphylum', 'phylum', etc.
**    _value   Input/output variable: updated if Tmp_TaxonomyInfo contains a value for the given rank
**
**  Auth:   mem
**  Date:   03/02/2016
**          10/25/2022 mem - Ported to PostgreSQL
**          01/15/2024 mem - Trim leading and trailing whitespace
**
*****************************************************/
DECLARE
    _taxonomyName text := '';
BEGIN
    SELECT Name
    INTO _taxonomyName
    FROM  Tmp_TaxonomyInfo
    WHERE Rank::citext = _rank::citext;

    If FOUND And Trim(Coalesce(_taxonomyName, '')) <> '' Then
        _value := Trim(_taxonomyName);
    End If;
END
$$;


ALTER PROCEDURE public.update_taxonomy_item_if_defined(IN _rank text, INOUT _value text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_taxonomy_item_if_defined(IN _rank text, INOUT _value text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_taxonomy_item_if_defined(IN _rank text, INOUT _value text) IS 'UpdateTaxonomyItemIfDefined';

