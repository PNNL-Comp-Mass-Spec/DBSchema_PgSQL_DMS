--
-- Name: add_archive_dataset(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_archive_dataset(IN _datasetid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make new entry in t_dataset_archive for the given dataset
**
**  Arguments:
**    _datasetID    Dataset ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          04/04/2006 grk - Added setting holdoff interval
**          01/14/2010 grk - Assign storage path on creation of archive entry
**          01/22/2010 grk - Existing entry in archive table prevents duplicate, but doesn't raise error
**          05/11/2011 mem - Now calling get_instrument_archive_path_for_new_datasets to determine _archivePathID
**          05/12/2011 mem - Now passing _datasetID and _autoSwitchActiveArchive to get_instrument_archive_path_for_new_datasets
**          06/01/2012 mem - Bumped up _holdOffHours to 2 weeks
**          06/12/2012 mem - Now looking up the Purge_Policy in T_Instrument_Name
**          08/10/2018 mem - Do not create an archive task for datasets with state 14
**          12/20/2021 bcg - Look up Purge_Priority and AS_purge_holdoff_date offset in T_Instrument_Name
**          04/24/2023 mem - Ported to PostgreSQL
**                         - Do not create an archive task if 'ArchiveDisabled' has a non-zero value in T_Misc_Options
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/19/2023 mem - Remove redundant parentheses
**          05/30/2023 mem - Use format() for string concatenation
**          06/15/2023 mem - Leave _returnCode as '' if the dataset already exists in t_dataset_archive
**          09/08/2023 mem - Include schema name when calling function
**
*****************************************************/
DECLARE
    _archiveDisabled int;
    _instrumentID int := 0;
    _datasetStateId int := 0;
    _archivePathID int := 0;
    _purgePolicy int := 0;
    _purgePriority int := 0;
    _purgeHoldoffMonths int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetID := Coalesce(_datasetID, 0);

    ---------------------------------------------------
    -- Don't allow duplicate dataset IDs in the table
    ---------------------------------------------------

    If Exists (SELECT dataset_id FROM t_dataset_archive WHERE dataset_id = _datasetID) Then
        _message := format('Dataset ID %s is already in t_dataset_archive', _datasetID);
        RAISE WARNING '%', _message;

        -- Use an empty string for the return code, since do_dataset_completion_actions will rollback the current transaction if the _returnCode is not ''
        _returnCode := '';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check if dataset archiving is diabled
    ---------------------------------------------------

    SELECT Value
    INTO _archiveDisabled
    FROM t_misc_options
    WHERE Name = 'ArchiveDisabled';

    If Not FOUND Then
        _archiveDisabled := 0;
    End If;

    If _archiveDisabled > 0 Then
        _message = 'Dataset archiving is disabled in T_Misc_Options';
        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the Instrument ID and dataset state
    ---------------------------------------------------

    SELECT instrument_id, dataset_state_id
    INTO _instrumentID, _datasetStateId
    FROM t_dataset
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Dataset ID %s not found in t_dataset', _datasetID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _datasetStateId = 14 Then
        _message := format('Cannot create a dataset archive task for Dataset ID %s; dataset state is 14 (Capture Failed, Duplicate Dataset Files)', _datasetID);

        CALL post_log_entry ('Error', _message, 'Add_Archive_Dataset', _duplicateEntryHoldoffHours => 12);

        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get the assigned archive path
    ---------------------------------------------------

    _archivePathID := public.get_instrument_archive_path_for_new_datasets(_instrumentID, _datasetID, _autoSwitchActiveArchive => true, _infoOnly => false);

    If _archivePathID = 0 Then
        _message := format('get_instrument_archive_path_for_new_datasets returned zero for an archive path ID for dataset %s', _datasetID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5105';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the purge policy for this instrument
    ---------------------------------------------------

    SELECT default_purge_policy,
           default_purge_priority,
           storage_purge_holdoff_months
    INTO _purgePolicy, _purgePriority, _purgeHoldoffMonths
    FROM t_instrument_name
    WHERE instrument_id = _instrumentID;

    _purgePolicy := Coalesce(_purgePolicy, 0);
    _purgePriority := Coalesce(_purgePriority, 3);
    _purgeHoldoffMonths := Coalesce(_purgeHoldoffMonths, 1);

    ---------------------------------------------------
    -- Make entry into archive table
    ---------------------------------------------------

    INSERT INTO t_dataset_archive( dataset_id,
                                   archive_state_id,
                                   archive_update_state_id,
                                   storage_path_id,
                                   archive_date,
                                   purge_holdoff_date,
                                   purge_policy,
                                   purge_priority )
    VALUES(_datasetID,
           1,
           1,
           _archivePathID,
           CURRENT_TIMESTAMP,
           CURRENT_TIMESTAMP + make_interval(months => _purgeHoldoffMonths),
           _purgePolicy,
           _purgePriority);

END
$$;


ALTER PROCEDURE public.add_archive_dataset(IN _datasetid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_archive_dataset(IN _datasetid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_archive_dataset(IN _datasetid integer, INOUT _message text, INOUT _returncode text) IS 'AddArchiveDataset';

