--
-- Name: add_update_prep_lc_run(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_prep_lc_run(INOUT _id integer, IN _preprunname text, IN _instrument text, IN _type text, IN _lccolumn text, IN _lccolumn2 text, IN _comment text, IN _guardcolumn text, IN _operatorusername text, IN _digestionmethod text, IN _sampletype text, IN _samplepreprequests text, IN _numberofruns text, IN _instrumentpressure text, IN _qualitycontrol text, IN _datasets text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing prep LC run
**
**  Arguments:
**    _id                   Input/output: prep LC run ID in t_prep_lc_run
**    _prepRunName          Prep LC run name
**    _instrument           Instrument
**    _type                 Type
**    _lcColumn             Primary LC column
**    _lcColumn2            Secondary LC column; empty string if not applicable
**    _comment              Comment
**    _guardColumn          Guard column: 'Yes', 'No', or 'n/a'
**    _operatorUsername     Username of the DMS user to associate with the prep LC run
**    _digestionMethod      Digestion method
**    _sampleType           Sample type
**    _samplePrepRequests   Typically a single sample prep request ID, but can also be a comma-separated list (or blank)
**    _numberOfRuns         Number of runs (datasets) to be created
**    _instrumentPressure   Instrument pressure
**    _qualityControl       Quality control reagent description
**    _datasets             Comma-separated list of dataset names to associate with this prep LC run
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user (unused by this procedure)
**
**  Auth:   grk
**  Date:   08/04/2009
**          04/24/2010 grk - Replace _project with _samplePrepRequest
**          04/26/2010 grk - Allow _samplePrepRequest to be a list of IDs
**          05/06/2010 grk - Add storage path
**          08/25/2011 grk - Add QC field
**          09/30/2011 grk - Add datasets field
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/27/2022 mem - Update _samplePrepRequest to replace semicolons with commas, then assure that the list only contains integers
**          06/06/2022 mem - Only validate _id if updating an existing item
**          11/18/2022 mem - Rename parameter to _prepRunName
**          03/08/2023 mem - Rename parameter to _samplePrepRequests
**                         - Use new column name Sample_Prep_Requests in T_Prep_LC_Run
**                         - Update work package(s) in column Sample_Prep_Work_Packages
**          01/16/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          07/19/2025 mem - Raise an exception if _mode is undefined or unsupported
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _validatedName text;
    _itemCount int;
    _integerCount int;
    _invalidIDs text;
    _numberOfRunsValue int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _prepRunName        := Trim(Coalesce(_prepRunName, ''));
        _instrument         := Trim(Coalesce(_instrument, ''));
        _type               := Trim(Coalesce(_type, ''));
        _lcColumn           := Trim(Coalesce(_lcColumn, ''));
        _lcColumn2          := Trim(Coalesce(_lcColumn2, ''));
        _comment            := Trim(Coalesce(_comment, ''));
        _guardColumn        := Trim(Coalesce(_guardColumn, ''));
        _operatorUsername   := Trim(Coalesce(_operatorUsername, ''));
        _digestionMethod    := Trim(Coalesce(_digestionMethod, ''));
        _sampleType         := Trim(Coalesce(_sampleType, ''));
        _samplePrepRequests := Trim(Coalesce(_samplePrepRequests, ''));
        _numberOfRuns       := Trim(Coalesce(_numberOfRuns, ''));
        _instrumentPressure := Trim(Coalesce(_instrumentPressure, ''));
        _qualityControl     := Trim(Coalesce(_qualityControl, ''));
        _datasets           := Trim(Coalesce(_datasets, ''));
        _mode               := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            RAISE EXCEPTION 'Empty string specified for parameter _mode';
        ElsIf Not _mode IN ('add', 'update', 'check_add', 'check_update') Then
            RAISE EXCEPTION 'Unsupported value for parameter _mode: %', _mode;
        End If;

        If _mode = 'update' And Coalesce(_id, 0) <= 0 Then
            RAISE EXCEPTION 'Cannot update: prep LC run ID must be a positive integer';
        End If;

        If _prepRunName = '' Then
            RAISE EXCEPTION 'Prep LC run name must be specified';
        End If;

        If _instrument = '' Then
            RAISE EXCEPTION 'Instrument name must be specified';
        End If;

        SELECT instrument
        INTO _validatedName
        FROM t_instrument_name
        WHERE instrument = _instrument::citext;

        If Not Found Then
            RAISE EXCEPTION 'Unrecognized instrument name: %', _instrument;
        Else
            _instrument := _validatedName;
        End If;

        If _type = '' Then
            RAISE EXCEPTION 'Run type must be specified';
        End If;

        If _lcColumn = '' Then
            RAISE EXCEPTION 'LC column must be specified';
        End If;

        If _guardColumn::citext In ('Y', 'Yes', '1') Then
            _guardColumn := 'Yes';
        ElsIf _guardColumn::citext In ('N', 'No', '0') Then
            _guardColumn := 'No';
        ElsIf _guardColumn::citext In ('n/a', 'na') Then
            _guardColumn := 'n/a';
        End If;

        If Not _guardColumn::citext In ('Yes', 'No', 'n/a') Then
            RAISE EXCEPTION 'Guard column must be "Yes", "No", or "n/a"';
        End If;

        If _operatorUsername = '' Then
            RAISE EXCEPTION 'Operator username must be specified';
        End If;

        If _numberOfRuns = '' Then
            RAISE EXCEPTION 'Number of runs must be specified';
        End If;

        _numberOfRunsValue := public.try_cast(_numberOfRuns, null::int);

        If _numberOfRunsValue Is Null Then
            RAISE EXCEPTION 'Number of runs must be an integer';
        End If;

        -- Assure that _samplePrepRequests is a comma-separated list of integers (or an empty string)
        If _samplePrepRequests Like '%;%' Then
            _samplePrepRequests := Replace(_samplePrepRequests, ';', ',');
        End If;

        CREATE TEMP TABLE Tmp_SamplePrepRequests (
            Prep_Request_ID int NOT NULL
        );

        If _samplePrepRequests <> '' Then
            SELECT COUNT(*)
            INTO _itemCount
            FROM public.parse_delimited_list(_samplePrepRequests);

            INSERT INTO Tmp_SamplePrepRequests (Prep_Request_ID)
            SELECT DISTINCT Value
            FROM public.parse_delimited_integer_list(_samplePrepRequests);

            GET DIAGNOSTICS _integerCount = ROW_COUNT;

            If _itemCount = 0 Or _itemCount <> _integerCount Then
                _message := 'The sample prep request list should be one or more sample prep request IDs (integers), separated by commas';
                RAISE EXCEPTION '%', _message;
            End If;

            SELECT string_agg(NewIDs.Prep_Request_ID::text, ', ' ORDER BY NewIDs.Prep_Request_ID)
            INTO _invalidIDs
            FROM Tmp_SamplePrepRequests NewIDs
                 LEFT OUTER JOIN t_sample_prep_request SPR
                   ON NewIDs.Prep_Request_ID = SPR.prep_request_id
            WHERE SPR.prep_request_id IS NULL;

            If Coalesce(_invalidIDs, '') <> '' Then
                _message := format('Invalid sample prep request ID(s): %s', _invalidIDs);
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' And Not Exists (SELECT prep_run_id FROM t_prep_lc_run WHERE prep_run_id = _id) Then
            RAISE EXCEPTION 'Cannot update: prep LC run % does not exist', _id;
        End If;

        ---------------------------------------------------
        -- Resolve dataset list
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Datasets (
          Dataset text,
          Dataset_ID int NULL
        );

        INSERT INTO Tmp_Datasets (Dataset)
        SELECT Value
        FROM public.parse_delimited_list(_datasets);

        UPDATE Tmp_Datasets
        SET dataset_id = DS.dataset_id
        FROM t_dataset DS
        WHERE Tmp_Datasets.dataset = DS.dataset;

        SELECT string_agg(Dataset, ', ' ORDER BY Dataset)
        INTO _invalidIDs
        FROM Tmp_Datasets NewIDs
        WHERE Dataset_ID IS NULL;

        If Coalesce(_invalidIDs, '') <> '' Then
            _message := format('Invalid dataset name(s): %s', _invalidIDs);
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            INSERT INTO t_prep_lc_run (
                prep_run_name,
                instrument,
                type,
                lc_column,
                lc_column_2,
                comment,
                guard_column,
                operator_username,
                digestion_method,
                sample_type,
                sample_prep_requests,
                number_of_runs,
                instrument_pressure,
                quality_control
            ) VALUES (
                _prepRunName,
                _instrument,
                _type,
                _lcColumn,
                _lcColumn2,
                _comment,
                _guardColumn,
                _operatorUsername,
                _digestionMethod,
                _sampleType,
                _samplePrepRequests,
                _numberOfRunsValue,
                _instrumentPressure,
                _qualityControl
            )
            RETURNING prep_run_id
            INTO _id;

            INSERT INTO t_prep_lc_run_dataset (
                prep_lc_run_id,
                dataset_id
            )
            SELECT _id AS Prep_LC_Run_ID, Dataset_ID
            FROM Tmp_Datasets;
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            UPDATE t_prep_lc_run
            SET prep_run_name        = _prepRunName,
                instrument           = _instrument,
                type                 = _type,
                lc_column            = _lcColumn,
                lc_column_2          = _lcColumn2,
                comment              = _comment,
                guard_column         = _guardColumn,
                operator_username    = _operatorUsername,
                digestion_method     = _digestionMethod,
                sample_type          = _sampleType,
                sample_prep_requests = _samplePrepRequests,
                number_of_runs       = _numberOfRunsValue,
                instrument_pressure  = _instrumentPressure,
                quality_control      = _qualityControl
            WHERE prep_run_id = _id;

            -- Add new datasets
            INSERT INTO t_prep_lc_run_dataset (prep_lc_run_id, dataset_id)
            SELECT _id AS Prep_LC_Run_ID, Dataset_ID
            FROM Tmp_Datasets
            WHERE NOT Tmp_Datasets.dataset_id IN (SELECT dataset_id FROM t_prep_lc_run_dataset WHERE prep_lc_run_id = _id);

            -- Delete removed datasets
            DELETE FROM t_prep_lc_run_dataset
            WHERE prep_lc_run_id = _id AND
                  NOT t_prep_lc_run_dataset.dataset_id IN (SELECT dataset_id FROM Tmp_Datasets);
        End If;

        -- Update the work package list using the sample prep request ID(s)

        CALL public.update_prep_lc_run_work_package_list (
                        _prepLCRunID => _id,
                        _message     => _message,       -- Output
                        _returnCode  => _returnCode);   -- Output

        DROP TABLE Tmp_SamplePrepRequests;
        DROP TABLE Tmp_Datasets;

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _id Is Null Then
            _logMessage := format('%s; Prep LC run %s', _exceptionMessage, _prepRunName);
        Else
            _logMessage := format('%s; Prep LC run %s, ID %s', _exceptionMessage, _prepRunName, _id);
        End If;

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_SamplePrepRequests;
    DROP TABLE IF EXISTS Tmp_Datasets;
END
$$;


ALTER PROCEDURE public.add_update_prep_lc_run(INOUT _id integer, IN _preprunname text, IN _instrument text, IN _type text, IN _lccolumn text, IN _lccolumn2 text, IN _comment text, IN _guardcolumn text, IN _operatorusername text, IN _digestionmethod text, IN _sampletype text, IN _samplepreprequests text, IN _numberofruns text, IN _instrumentpressure text, IN _qualitycontrol text, IN _datasets text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_prep_lc_run(INOUT _id integer, IN _preprunname text, IN _instrument text, IN _type text, IN _lccolumn text, IN _lccolumn2 text, IN _comment text, IN _guardcolumn text, IN _operatorusername text, IN _digestionmethod text, IN _sampletype text, IN _samplepreprequests text, IN _numberofruns text, IN _instrumentpressure text, IN _qualitycontrol text, IN _datasets text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_prep_lc_run(INOUT _id integer, IN _preprunname text, IN _instrument text, IN _type text, IN _lccolumn text, IN _lccolumn2 text, IN _comment text, IN _guardcolumn text, IN _operatorusername text, IN _digestionmethod text, IN _sampletype text, IN _samplepreprequests text, IN _numberofruns text, IN _instrumentpressure text, IN _qualitycontrol text, IN _datasets text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdatePrepLCRun';

