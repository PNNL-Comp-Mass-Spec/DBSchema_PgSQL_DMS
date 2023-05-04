--
-- Name: update_prep_lc_run_work_package_list(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_prep_lc_run_work_package_list(IN _preplcrunid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the work package list for a single prep LC run or for all prep LC runs
**
**  Arguments:
**    _prepLCRunID   If 0, update all rows in T_Prep_LC_Run
**
**  Auth:   mem
**  Date:   03/09/2023 mem - Initial version
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _continue boolean;
    _currentPrepRunID int;
    _samplePrepRequestIDs text;
    _wpList text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _prepLCRunID := Coalesce(_prepLCRunID, 0);

        ---------------------------------------------------
        -- Create a temporary table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_SamplePrepRequests_for_WP_List (
            Prep_Request_ID int NOT NULL
        );

        ---------------------------------------------------
        -- Update the work package list for each Prep LC Run
        ---------------------------------------------------

        _continue := true;

        If _prepLCRunID = 0 Then
            _currentPrepRunID := -1;
        Else
            _currentPrepRunID := _prepLCRunID - 1;
        End If;

        WHILE _continue
        LOOP
            ---------------------------------------------------
            -- Get next prep LC run to update
            ---------------------------------------------------

            SELECT prep_run_id, sample_prep_requests
            INTO _currentPrepRunID, _samplePrepRequestIDs
            FROM T_Prep_LC_Run
            WHERE prep_run_id > _currentPrepRunID
            ORDER BY prep_run_id
            LIMIT 1;

            If Not FOUND Then
                -- Break out of the while loop
                EXIT;
            End If;

            _wpList = Null;

            If Coalesce(_samplePrepRequestIDs, '') <> '' Then
                ---------------------------------------------------
                -- Populate the temporary table with the sample prep request ID(s)
                ---------------------------------------------------

                DELETE FROM Tmp_SamplePrepRequests_for_WP_List;

                INSERT INTO Tmp_SamplePrepRequests_for_WP_List (Prep_Request_ID)
                SELECT DISTINCT Value
                FROM public.parse_delimited_integer_list ( _samplePrepRequestIDs, ',' );

                ---------------------------------------------------
                -- Construct the list of work packages for the prep request IDs
                ---------------------------------------------------

                SELECT string_agg(DistinctQ.Work_Package, ', ' ORDER BY DistinctQ.Work_Package)
                INTO _wpList
                FROM ( SELECT DISTINCT Work_Package
                       FROM T_Sample_Prep_Request SPR
                            INNER JOIN Tmp_SamplePrepRequests_for_WP_List NewIDs
                              ON SPR.prep_request_id = NewIDs.prep_request_id) As DistinctQ;

                If Coalesce(_wpList, '') = '' Then
                    _wpList := null;
                End If;
            End If;

            -- Update the table if _wpList differs from the existing value
            --
            UPDATE T_Prep_LC_Run
            SET Sample_Prep_Work_Packages = _wpList
            WHERE prep_run_id = _currentPrepRunID And
                Sample_Prep_Work_Packages IS DISTINCT FROM _wpList;

            If _prepLCRunID > 0 Then
                _continue := false;
            End If;

        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_SamplePrepRequests_for_WP_List;
END
$$;


ALTER PROCEDURE public.update_prep_lc_run_work_package_list(IN _preplcrunid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

