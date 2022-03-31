--
-- Name: gettaxidtaxonomytable(integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.gettaxidtaxonomytable(_taxonomyid integer) RETURNS TABLE(rank public.citext, name public.citext, tax_id integer, entry_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Populates a table with the Taxonomy entries for the given TaxonomyID value
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _parentTaxID int;
    _name citext;
    _rank citext;
BEGIN

    CREATE TEMP TABLE IF NOT EXISTS Tmp_Taxonomy
    (
        Rank citext not NULL,
        Name citext NOT NULL,
        Tax_ID int NOT NULL,
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    -- Since we used "CREATE TEMP TABLE IF NOT EXISTS" we could TRUNCATE here to assure that it is empty
    -- However, since we end this function with DROP TABLE, the truncation is not required
    -- TRUNCATE TABLE Tmp_Taxonomy;

    While _taxonomyID <> 1 Loop

        SELECT T.parent_tax_id, T.name,T.Rank 
        INTO _parentTaxID, _name, _rank 
        FROM ont.t_ncbi_taxonomy_cached T
        WHERE T.tax_id = _taxonomyID;

        If NOT FOUND Then
            _taxonomyID := 1;
        Else

            INSERT INTO Tmp_Taxonomy (Rank, Name, Tax_ID)
            VALUES (_rank, _name, _taxonomyID);

            _taxonomyID := _parentTaxID;
        End If;
    End Loop;

    RETURN QUERY
    SELECT T.Rank, T.Name, T.Tax_ID, T.Entry_ID
    FROM Tmp_Taxonomy T;

    -- If not dropped here, the temporary table will persist until the calling session ends
    DROP TABLE Tmp_Taxonomy;
END
$$;


ALTER FUNCTION ont.gettaxidtaxonomytable(_taxonomyid integer) OWNER TO d3l243;

--
-- Name: FUNCTION gettaxidtaxonomytable(_taxonomyid integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.gettaxidtaxonomytable(_taxonomyid integer) IS 'GetTaxIDTaxonomyTable';

