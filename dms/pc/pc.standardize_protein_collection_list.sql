--
-- Name: standardize_protein_collection_list(text); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.standardize_protein_collection_list(_protcollnamelist text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Standardizes the order of protein collection names in a protein
**      collection list, returning them in a canonical order such that
**      internal standard collections (type 5) are listed first,
**      contaminants (type 4) are listed last,
**      and the remaining collections are listed alphabetically in the middle
**
**      Note that this procedure does not validate the protein
**      collection names vs. those in T_Protein_Collections,
**      though it will correct capitalization errors
**
**  Auth:   mem
**  Date:   06/08/2006
**          08/11/2006 mem - Updated to place contaminants collections at the end of the list
**          10/04/2007 mem - Increased _protCollNameList from varchar(2048) to varchar(max)
**          06/24/2013 mem - Now removing duplicate protein collection names in _protCollNameList
**          03/17/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _protCollNameListNew text := '';
    _textToAppend text;
BEGIN
    -- Check for Null values
    _protCollNameList := Coalesce(_protCollNameList, '');

    If _protCollNameList IN ('', 'na') Then
        RETURN _protCollNameList;
    End If;

    ---------------------------------------------------
    -- Populate a temporary table with the protein collections
    -- in _protCollNameList
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Protein_Collections (
        Unique_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Collection_Name text NOT NULL,
        Collection_Type_ID int NOT NULL DEFAULT 1
    );

    -- Split _protCollNameList on commas and populate Tmp_Protein_Collections
    INSERT INTO Tmp_Protein_Collections (Collection_Name)
    SELECT DISTINCT Trim(Value)
    FROM public.parse_delimited_list(_protCollNameList, ',');

    -- Make sure no zero-length records are present in Tmp_Protein_Collections
    DELETE FROM Tmp_Protein_Collections
    WHERE char_length(Collection_Name) = 0;

    -- Determine the Collection_Type_ID values for the entries in Tmp_Protein_Collections
    -- Additionally, correct any capitalization errors
    --
    UPDATE Tmp_Protein_Collections
    SET Collection_Type_ID = PCT.Collection_Type_ID,
        Collection_Name = PC.collection_name
    FROM pc.t_protein_collections PC INNER JOIN
         pc.t_protein_collection_types PCT ON PC.collection_type_id = PCT.collection_type_id
    WHERE Tmp_Protein_Collections.Collection_Name = PC.collection_name;

    -- Populate _protCollNameListNew with any entries that have Collection_Type_ID = 5
    --
    SELECT string_agg(Collection_Name, ',' ORDER BY Collection_Name)
    INTO _textToAppend
    FROM Tmp_Protein_Collections
    WHERE Collection_Type_ID = 5;

    _protCollNameListNew := public.append_to_text(_protCollNameListNew, _textToAppend, _delimiter => ',');

    -- Append any entries with Collection_Type_ID <> 4 and <> 5
    --
    SELECT string_agg(Collection_Name, ',' ORDER BY Collection_Name)
    INTO _textToAppend
    FROM Tmp_Protein_Collections
    WHERE Collection_Type_ID NOT IN (4,5);

     _protCollNameListNew := public.append_to_text(_protCollNameListNew, _textToAppend, _delimiter => ',');

    -- Append any entries with Collection_Type_ID = 4
    --
    SELECT string_agg(Collection_Name, ',' ORDER BY Collection_Name)
    INTO _textToAppend
    FROM Tmp_Protein_Collections
    WHERE Collection_Type_ID = 4;

    _protCollNameListNew := public.append_to_text(_protCollNameListNew, _textToAppend, _delimiter => ',');

    -- Uncomment the following to show a message if _protCollNameListNew differs from _protCollNameList
    --
    -- If Replace(_protCollNameList, ' ', '') <> _protCollNameListNew Then
    --     RAISE INFO 'Protein collection list order has been standardized';
    -- End If;

    DROP TABLE Tmp_Protein_Collections;

    RETURN _protCollNameListNew;
END
$$;


ALTER FUNCTION pc.standardize_protein_collection_list(_protcollnamelist text) OWNER TO d3l243;

--
-- Name: FUNCTION standardize_protein_collection_list(_protcollnamelist text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON FUNCTION pc.standardize_protein_collection_list(_protcollnamelist text) IS 'StandardizeProteinCollectionList';
