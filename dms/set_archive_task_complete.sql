--
-- Name: set_archive_task_complete(text, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_archive_task_complete(IN _datasetname text, IN _completioncode integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Set archive state to 3 (Complete) if _completionCode is 0 or 100
**      Set archive state to 6 (Operation Failed) if _completionCode is not 0 or 100
**
**  Arguments:
**    _datasetName      Dataset name
**    _completionCode   0=success, 1=failed, 100=success (capture broker); Legacy: anything else = no intermediate files
**
**  Auth:   grk
**  Date:   09/26/2002
**          06/21/2005 grk - Added handling for 'requires_preparation'
**          11/27/2007 dac - Removed _processorname param, which is no longer required
**          03/23/2009 mem - Now updating Last_Successful_Archive when the archive state is 3=Complete (Ticket #726)
**          12/17/2009 grk - Added special success code '100' for use by capture broker
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          07/09/2022 mem - Tabs to spaces
**          06/16/2023 mem - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _datasetID int;
    _archiveState int;
    _doPrep int;
    _archiveStateNew int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Resolve dataset name to ID and archive state
    ---------------------------------------------------

    SELECT DS.Dataset_ID,
           DA.Archive_State_id,
           InstClass.requires_preparation
    INTO _datasetID, _archiveState, _doPrep
    FROM t_dataset DS
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_instrument_class InstClass
           ON InstName.instrument_class = InstClass.instrument_class
         INNER JOIN t_dataset_archive DA
           ON DS.dataset_id = DA.dataset_id
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
    -- Check dataset archive state for 'in progress'
    ---------------------------------------------------

    If _archiveState <> 2 Then
        _message := format('Archive state is not correct for dataset %s (expecting 2 but actually %s)', _datasetName, _archiveState);
        _returnCode := 'U5250';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update dataset archive state
    ---------------------------------------------------

    If _completionCode = 0 Or _completionCode = 100 Then
        -- Task completed successfully

        -- Decide what state is next
        --
        If _completionCode = 100 Then
            _archiveStateNew := 3;
        ElsIf _doPrep = 0 Then
            _archiveStateNew := 3;
        Else
            _archiveStateNew := 11;
        End If;

        -- Update the state
        --
        UPDATE t_dataset_archive
        SET archive_state_id = _archiveStateNew,
            archive_update_state_id = 4,
            last_update = CURRENT_TIMESTAMP,
            last_verify = CURRENT_TIMESTAMP,
            last_successful_archive =
                    CASE WHEN _archiveStateNew = 3
                    THEN CURRENT_TIMESTAMP
                    ELSE last_successful_archive
                    END
        WHERE dataset_id = _datasetID;

    Else
        -- Task completed unsuccessfully

        UPDATE t_dataset_archive
        SET archive_state_id = 6
        WHERE dataset_id = _datasetID;

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('set_archive_task_complete', _usageMessage);

END
$$;


ALTER PROCEDURE public.set_archive_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_archive_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.set_archive_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text) IS 'SetArchiveTaskComplete';

