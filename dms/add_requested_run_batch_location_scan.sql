--
-- Name: add_requested_run_batch_location_scan(integer, timestamp without time zone, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_requested_run_batch_location_scan(IN _locationid integer, IN _scandate timestamp without time zone, IN _batchidlist text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds a location scan to t_requested_run_batch_location_history for one or more requested run batches
**
**  Arguments:
**    _locationId           Location ID (row in in t_material_locations)
**    _scanDate             Scan date/time
**    _batchIdList          Requested run batch IDs (comma separated list)
**    _message              Error message (output); empty string if no error
**    _returnCode           Return code
**
**  Auth:   bcg
**  Date:   05/19/2023 bcg - Initial version
**          05/23/2023 mem - Add missing error message and additional validation
**          05/24/2023 mem - Update _message if any batch IDs are unrecognized, but continue processing
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _raiseExceptions boolean := true;
    _logErrors boolean := false;
    _matchCount int;
    _firstInvalid text;
    _invalidIDs text;
    _validIDs text;

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
        -- Validate input fields
        ---------------------------------------------------

        _locationId  := Coalesce(_locationId, 0);
        _scanDate    := Coalesce(_scanDate, CURRENT_TIMESTAMP);
        _batchIdList := Coalesce(_batchIdList, '');

        If Not Exists (SELECT location_id FROM t_material_locations WHERE location_id = _locationId) Then
            _message := format('Location ID not found in T_Material_Locations: %s', _locationId);
            _returnCode := 'U5201';

            If _raiseExceptions Then
                RAISE EXCEPTION '%', _message;
            Else
                RAISE WARNING '%', _message;
                RETURN;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Create temporary table for requests in list
        ---------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_BatchIDs (
            BatchIDText text NULL,
            Batch_ID int NULL,
            Valid boolean DEFAULT false
        );

        ---------------------------------------------------
        -- Populate temporary table from list
        ---------------------------------------------------
        --
        INSERT INTO Tmp_BatchIDs (BatchIDText)
        SELECT DISTINCT Value
        FROM public.parse_delimited_list(_batchIDList, ',');

        ---------------------------------------------------
        -- Convert Batch IDs to integers
        ---------------------------------------------------
        --
        UPDATE Tmp_BatchIDs
        SET Batch_ID = try_cast(BatchIDText, null::int);

        If Exists (Select * FROM Tmp_BatchIDs WHERE Batch_ID Is Null) Then

            SELECT BatchIDText
            INTO _firstInvalid
            FROM Tmp_BatchIDs
            WHERE Batch_ID Is Null
            LIMIT 1;

            _logErrors := false;
            _message := format('Batch IDs must be integers, not names; first invalid item: %s', _firstInvalid);
            _returnCode := 'U5204';

            If _raiseExceptions Then
                RAISE EXCEPTION '%', _message;
            Else
                RAISE WARNING '%', _message;
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Check status of supplied batch IDs
        ---------------------------------------------------

        -- Do all batch IDs in list actually exist?
        --
        UPDATE Tmp_BatchIDs
        SET Valid = true
        FROM T_Requested_Run_Batches RRB
        WHERE Tmp_BatchIDs.Batch_ID = RRB.batch_id;

        SELECT COUNT(*)
        INTO _matchCount
        FROM Tmp_BatchIDs
        WHERE Not Valid;

        If _matchCount > 0 Then
            SELECT string_agg(BatchIDText, ', ' ORDER BY BatchIDText)
            INTO _invalidIDs
            FROM Tmp_BatchIDs
            WHERE Not Valid;

            _message := format('Batch ID list contains %s: %s',
                               CASE WHEN Position(',' In _invalidIDs) > 0
                                    THEN 'batch IDs that do not exist'
                                    ELSE 'a batch ID that does not exist'
                               END,
                               _invalidIDs);

            RAISE WARNING '%', _message;

            DELETE FROM Tmp_BatchIDs
            WHERE Not Valid;

            If Not Exists (SELECT * FROM Tmp_BatchIDs) Then
                -- No valid Batch IDs remain

                _logErrors := false;
                _message := format('%s; did not find any valid Batch IDs', _message);
                _returnCode := 'U5206';

                If _raiseExceptions Then
                    RAISE EXCEPTION '%', _message;
                Else
                    RAISE WARNING '%', _message;
                    RETURN;
                End If;

            End If;

            SELECT string_agg(BatchIDText, ', ' ORDER BY BatchIDText)
            INTO _validIDs
            FROM Tmp_BatchIDs;

            _message := format('%s; updating location for Batch %s %s',
                               _message,
                               CASE WHEN Position(',' IN _validIDs) > 0 THEN 'IDs' ELSE 'ID' END,
                               _validIDs);
        End If;

        ---------------------------------------------------
        -- Add/update the location history
        ---------------------------------------------------

        MERGE INTO t_requested_run_batch_location_history AS t
        USING (SELECT _locationID AS location_id, batch_id
               FROM Tmp_BatchIDs) AS s
        ON (t.batch_id = s.batch_id AND t.location_id = s.location_id )
        WHEN MATCHED AND (t.first_scan_date < _scanDate OR t.last_scan_date IS NULL OR t.last_scan_date < _scanDate) THEN
            UPDATE SET
                last_scan_date =  CASE
                                    WHEN t.last_scan_date IS NULL AND _scanDate < t.first_scan_date THEN t.first_scan_date
                                    WHEN t.last_scan_date IS NULL OR t.last_scan_date < _scanDate THEN _scanDate
                                    ELSE t.last_scan_date
                                  END,
                first_scan_date = CASE
                                    WHEN _scanDate < t.first_scan_date THEN _scanDate
                                    ELSE t.first_scan_date
                                  END
        WHEN NOT MATCHED THEN
            INSERT (batch_id, location_id, first_scan_date)
            VALUES (s.batch_id, s.location_id, _scanDate);

        DROP TABLE Tmp_BatchIDs;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_BatchIDs;
    END;

END
$$;


ALTER PROCEDURE public.add_requested_run_batch_location_scan(IN _locationid integer, IN _scandate timestamp without time zone, IN _batchidlist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

