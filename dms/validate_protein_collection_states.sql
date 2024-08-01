--
-- Name: validate_protein_collection_states(integer, integer, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_protein_collection_states(INOUT _invalidcount integer DEFAULT 0, INOUT _offlinecount integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validate the collection states for protein collections in temporary table Tmp_ProteinCollections
**
**      The calling procedure must create and populate a temporary table that includes columns Protein_Collection_Name and Collection_State_ID
**      (this procedure updates values in column Collection_State_ID, so the calling procedure need only store protein collection names, but can store 0 for the states)
**
**      CREATE TEMP TABLE Tmp_ProteinCollections (
**          Protein_Collection_Name citext NOT NULL,
**          Collection_State_ID int NOT NULL
**      );
**
**  Arguments:
**    _invalidCount     Output: Number of invalid protein collections (unrecognized name or protein collection with state 5 = Proteins_Deleted)
**    _offlineCount     Output: Number of offline protein collections (protein collection with state 6 = Offline; protein names and sequences are no longer in the pc.t_protein tables)
**    _message          Warning message(s); empty string if no issues
**    _returnCode       Return code; empty string if no issues
**    _showDebug        When true, show _message if not an empty string
**
**  Auth:   mem
**  Date:   07/23/2024 mem - Initial release
**          08/01/2024 mem - Ignore protein collections named 'na'
**
*****************************************************/
DECLARE
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------

    _invalidCount := 0;
    _offlineCount := 0;
    _showDebug    := Coalesce(_showDebug, false);

    --------------------------------------------------------------
    -- Lookup the state of each protein collection name
    --------------------------------------------------------------

    UPDATE Tmp_ProteinCollections
    SET Collection_State_ID = PC.collection_state_id
    FROM pc.t_protein_collections PC
    WHERE Tmp_ProteinCollections.Protein_Collection_Name = PC.collection_name;

    --------------------------------------------------------------
    -- Count collections with specific states
    --------------------------------------------------------------

    SELECT COUNT(*)
    INTO _invalidCount
    FROM Tmp_ProteinCollections
    WHERE Collection_State_ID IN (0, 5) AND Not Protein_Collection_Name IN ('na');

    SELECT COUNT(*)
    INTO _offlineCount
    FROM Tmp_ProteinCollections
    WHERE Collection_State_ID IN (6) AND Not Protein_Collection_Name IN ('na');

    --------------------------------------------------------------
    -- Look for unrecognized protein collections
    --------------------------------------------------------------

    SELECT string_agg(Protein_Collection_Name, ',' ORDER BY Protein_Collection_Name)
    INTO _msg
    FROM Tmp_ProteinCollections
    WHERE Collection_State_ID = 0 AND Not Protein_Collection_Name IN ('na');

    If _msg <> '' Then
        _msg := format('Unrecognized protein %s: %s',
                       CASE WHEN Position(',' IN _msg) > 0 THEN 'collections' ELSE 'collection' END,
                       _msg);

        _message := public.append_to_text(_message, _msg);

        If _returnCode = '' Then
            _returnCode := 'U5480';
        End If;
    End If;

    --------------------------------------------------------------
    -- Look for protein collections with state 'Proteins_Deleted'
    --------------------------------------------------------------

    SELECT string_agg(Protein_Collection_Name, ',' ORDER BY Protein_Collection_Name)
    INTO _msg
    FROM Tmp_ProteinCollections
    WHERE Collection_State_ID = 5;

    If _msg <> '' Then
        _msg := format('Cannot use deleted protein %s: %s',
                       CASE WHEN Position(',' IN _msg) > 0 THEN 'collections' ELSE 'collection' END,
                       _msg);

        _message := public.append_to_text(_message, _msg);

        If _returnCode = '' Then
            _returnCode := 'U5481';
        End If;
    End If;

    --------------------------------------------------------------
    -- Look for protein collections with state 'Offline'
    --------------------------------------------------------------

    SELECT string_agg(Protein_Collection_Name, ',' ORDER BY Protein_Collection_Name)
    INTO _msg
    FROM Tmp_ProteinCollections
    WHERE Collection_State_ID = 6;

    If _msg <> '' Then
        _msg := format('%s: %s (contact an admin to restore the proteins)',
                       CASE WHEN Position(',' IN _msg) > 0
                            THEN 'Cannot use offline protein collections (collections not used recently)'
                            ELSE 'Cannot use an offline protein collection (not used recently)'
                       END,
                       _msg);

        _message := public.append_to_text(_message, _msg);

        If _returnCode = '' Then
            _returnCode := 'U5482';
        End If;
    End If;

    If _showDebug Then
        RAISE INFO '';
        RAISE INFO '%', _message;
    End If;

END
$$;


ALTER PROCEDURE public.validate_protein_collection_states(INOUT _invalidcount integer, INOUT _offlinecount integer, INOUT _message text, INOUT _returncode text, IN _showdebug boolean) OWNER TO d3l243;

