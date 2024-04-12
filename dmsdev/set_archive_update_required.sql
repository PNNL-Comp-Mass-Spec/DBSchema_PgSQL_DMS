--
-- Name: set_archive_update_required(text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_archive_update_required(IN _datasetname text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Set archive update state to 2 (Update Required) in t_dataset_archive for the given dataset
**
**  Arguments:
**    _datasetName      Dataset name
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   12/3/2002
**          03/06/2007 grk - Add changes for deep purge (ticket #403)
**          03/07/2007 dac - Fixed incorrect check for 'in progress' update states (ticket #408)
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          07/09/2022 mem - Tabs to spaces
**          06/16/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _archiveState int;
    _updateState int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Resolve dataset name to ID and archive state
    ---------------------------------------------------

    SELECT DS.dataset_id,
           DA.archive_state_id,
           DA.archive_update_state_id
    INTO _datasetID, _archiveState, _updateState
    FROM t_dataset DS
         INNER JOIN t_dataset_archive DA
           ON DS.dataset_id = DA.dataset_id
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_instrument_class InstClass
           ON InstName.instrument_class = InstClass.instrument_class
    WHERE DS.dataset = _datasetName::citext;

    If Not FOUND Then
        SELECT dataset_id
        INTO _datasetID
        FROM t_dataset
        WHERE dataset = _datasetName::citext;

        If Not FOUND Then
            _message := format('Dataset %s not found in t_dataset', Coalesce(_datasetName, '??'));
            _returnCode := 'U5220';
        Else
            _message := format('Dataset ID %s not found in t_dataset_archive (for dataset %s)', _datasetID, Coalesce(_datasetName, '??'));
            _returnCode := 'U5221';
        End If;

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check dataset archive update state for 'in progress'
    ---------------------------------------------------

    If Not _updateState In (1, 2, 4, 5) Then
        _returnCode := 'U5250';
        _message := format('Archive update state for dataset %s is not correct (expecting 1, 2, 4, or 5 but actually %s)', _datasetName, _updateState);
        RETURN;
    End If;

    ---------------------------------------------------
    -- If archive state is 'purged', set it to 'complete'
    -- to allow for re-purging
    ---------------------------------------------------

    If _archiveState = 4 Then
        _archiveState := 3;
    End If;

    ---------------------------------------------------
    -- Update dataset archive state
    ---------------------------------------------------

    UPDATE t_dataset_archive
    SET archive_update_state_id = 2, archive_state_id = _archiveState
    WHERE (dataset_id = _datasetID);

    If Not FOUND Then
        _returnCode := 'U5299';
        _message := format('Dataset ID %s not found in t_dataset_archive', _datasetID);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('set_archive_update_required', _usageMessage);

END
$$;


ALTER PROCEDURE public.set_archive_update_required(IN _datasetname text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_archive_update_required(IN _datasetname text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.set_archive_update_required(IN _datasetname text, INOUT _message text, INOUT _returncode text) IS 'SetArchiveUpdateRequired';

