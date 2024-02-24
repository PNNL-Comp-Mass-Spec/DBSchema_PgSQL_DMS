--
-- Name: get_taxid_taxonomy_table(integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.get_taxid_taxonomy_table(_taxonomyid integer) RETURNS TABLE(rank public.citext, name public.citext, tax_id integer, entry_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Populates a table with the Taxonomy entries for the given TaxonomyID value
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/30/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _parentTaxID int;
    _name citext;
    _rank citext;
BEGIN

    CREATE TEMP TABLE Tmp_Taxonomy (
        Rank citext NOT NULL,
        Name citext NOT NULL,
        Tax_ID int NOT NULL,
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    WHILE _taxonomyID <> 1
    LOOP

        SELECT T.parent_tax_id, T.name,T.Rank
        INTO _parentTaxID, _name, _rank
        FROM ont.t_ncbi_taxonomy_cached T
        WHERE T.tax_id = _taxonomyID;

        If Not FOUND Then
            _taxonomyID := 1;
        Else

            INSERT INTO Tmp_Taxonomy (Rank, Name, Tax_ID)
            VALUES (_rank, _name, _taxonomyID);

            _taxonomyID := _parentTaxID;
        End If;
    END LOOP;

    RETURN QUERY
    SELECT T.Rank, T.Name, T.Tax_ID, T.Entry_ID
    FROM Tmp_Taxonomy T;

    -- If not dropped here, the temporary table will persist until the calling session ends
    DROP TABLE Tmp_Taxonomy;
END
$$;


ALTER FUNCTION ont.get_taxid_taxonomy_table(_taxonomyid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_taxid_taxonomy_table(_taxonomyid integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.get_taxid_taxonomy_table(_taxonomyid integer) IS 'GetTaxIDTaxonomyTable';

