--
CREATE OR REPLACE PROCEDURE public.update_sample_request_assignments
(
    _mode text,
    _newValue text,
    _reqIDList text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Changes assignment properties to given new value
**      for given list of requested sample preps
**
**  Arguments:
**    _mode   'priority', 'state', 'assignment', 'delete', 'req_assignment', 'est_completion'
**
**  Auth:   grk
**  Date:   06/14/2005
**          07/26/2005 grk - added 'req_assignment'
**          08/02/2005 grk - assignement also sets state to 'open'
**          08/14/2005 grk - update state changed date
**          03/14/2006 grk - added stuff for estimated completion date
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          02/20/2012 mem - Now using a temporary table to track the requests to update
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          06/18/2014 mem - Now passing default to udfParseDelimitedIntegerList
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/02/2022 mem - Fix bug that treated priority as an integer; instead, should be Normal or High
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _dt timestamp;
    _updateCount int := 0;
    _id int := 0;
    _requestIDNum text;
    _tblRequestsToProcess Table;
    _stID int;
    _usageMessage text := '';
BEGIN
    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Populate a temorary table with the requests to process
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestsToProcess
    (
        RequestID int
    );

    INSERT INTO Tmp_RequestsToProcess (RequestID)
    SELECT Value
    FROM public.parse_delimited_integer_list(_reqIDList, default)
    ORDER BY Value;

    -- Process each request in Tmp_RequestsToProcess
    --
    FOR _id IN
        SELECT RequestID
        FROM Tmp_RequestsToProcess
        ORDER BY RequestID
    LOOP

        _updateCount := _updateCount + 1;
        _requestIDNum := _id::text;

        -------------------------------------------------
        If _mode = 'est_completion' Then
            _dt := _newValue::timestamp;

            UPDATE t_sample_prep_request
            SET estimated_completion = _dt
            WHERE prep_request_id = _id;
        End If;

        -------------------------------------------------
        If _mode = 'priority' Then
            -- Priority should be Normal or High
            --
            If Not _newValue::citext In ('Normal', 'High') Then
                RAISE EXCEPTION 'Priority should be Normal or High; not updating request %', _requestIDNum;
            End If;

            -- Set priority
            --
            UPDATE t_sample_prep_request
            SET priority = _pri
            WHERE prep_request_id = _id;
        End If;

        -------------------------------------------------
        -- This mode is used for web page option 'Assign selected requests to preparer(s)'
        If _mode = 'assignment' Then
            UPDATE t_sample_prep_request
            SET assigned_personnel = _newValue,
                state_changed = CURRENT_TIMESTAMP,
                state_id = 2    -- 'open'
            WHERE prep_request_id = _id;
        End If;

        -------------------------------------------------
        -- This mode is used for web page option "Assign selected requests to requested personnel"
        If _mode = 'req_assignment' Then
            UPDATE t_sample_prep_request
            SET assigned_personnel = requested_personnel,
                state_changed = CURRENT_TIMESTAMP,
                state_id = 2    -- 'open'
            WHERE prep_request_id = _id;
        End If;

        -------------------------------------------------
        If _mode = 'state' Then
            -- Get state ID

            SELECT state_id
            INTO _stID
            FROM t_sample_prep_request_state_name
            WHERE (state_name = _newValue)

            UPDATE t_sample_prep_request
            SET state_id = _stID,
                state_changed = CURRENT_TIMESTAMP
            WHERE prep_request_id = _id;

        End If;

        -------------------------------------------------
        If _mode = 'delete' Then
            -- Deletes are ignored by this procedure
            -- Use DeleteSamplePrepRequest instead
        End If;

        -------------------------------------------------
        If _returnCode <> '' Then
            RAISE EXCEPTION 'Operation failed for for Request ID %', _requestIDNum;
        End If;

    END LOOP;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Updated %s prep %s', _updateCount, public.check_plural(_updateCount, 'request', 'requests'));

    Call post_usage_log_entry ('Update_Sample_Request_Assignments', _usageMessage);

    DROP TABLE Tmp_RequestsToProcess;

END
$$;

COMMENT ON PROCEDURE public.update_sample_request_assignments IS 'UpdateSampleRequestAssignments';
