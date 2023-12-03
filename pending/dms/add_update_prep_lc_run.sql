--
CREATE OR REPLACE PROCEDURE public.add_update_prep_lc_run
(
    INOUT _id int,
    _prepRunName text,
    _instrument text,
    _type text,
    _lcColumn text,
    _lcColumn2 text,
    _comment text,
    _guardColumn text,
    _operatorUsername text,
    _digestionMethod text,
    _sampleType text,
    _samplePrepRequests text,
    _numberOfRuns text,
    _instrumentPressure text,
    _qualityControl text,
    _datasets text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits an existing prep LC run
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
**    _message              Output message
**    _returnCode           Return code
**    _callingUser          Calling user username
**
**  Auth:   grk
**  Date:   08/04/2009
**          04/24/2010 grk - Replaced _project with _samplePrepRequest
**          04/26/2010 grk - _samplePrepRequest can be multiple
**          05/06/2010 grk - Added storage path
**          08/25/2011 grk - Added QC field
**          09/30/2011 grk - Added datasets field
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
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _itemCount Int;
    _integerCount Int;
    _invalidIDs text;

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

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

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

        _id := Coalesce(_id, 0);
        _samplePrepRequests := Trim(Coalesce(_samplePrepRequests, ''));

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode = 'update' And _id <= 0 Then
            RAISE EXCEPTION 'Prep LC run ID must be a positive integer';
        End If;

        -- Assure that _samplePrepRequests is a comma-separated list of integers (or an empty string)
        If _samplePrepRequest Like '%;%' Then
            _samplePrepRequest := Replace(_samplePrepRequest, ';', ',');
        End If;

        CREATE TEMP TABLE Tmp_SamplePrepRequests (
            Prep_Request_ID Int Not Null
        );

        If char_length(_samplePrepRequest) > 0 Then
            SELECT COUNT(*)
            INTO _itemCount
            FROM public.parse_delimited_list(_samplePrepRequest)

            INSERT INTO Tmp_SamplePrepRequests (Prep_Request_ID)
            SELECT DISTINCT Value
            FROM public.parse_delimited_integer_list(_samplePrepRequests);

            GET DIAGNOSTICS _integerCount = ROW_COUNT;

            If _itemCount = 0 Or _itemCount <> _integerCount Then
                _message := 'The sample prep request list should be one or more sample prep request IDs (integers), separated by commas';
                RAISE EXCEPTION '%', _message;
            End If;

            SELECT _invalidIDs = string_agg(Prep_Request_ID, ',' ORDER BY Prep_Request_ID)
            FROM Tmp_SamplePrepRequests NewIDs
                 LEFT OUTER JOIN t_sample_prep_request SPR
                   ON NewIDs.Prep_Request_ID = SPR.ID
            WHERE SPR.ID IS NULL;

            If Coalesce(_invalidIDs, '') <> ''
            Begin
                _message := format('Invalid sample prep request ID(s): %s', _invalidIDs);
                RAISE EXCEPTION '%', _message;
            End
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' And Not Exists (SELECT prep_run_id FROM t_prep_lc_run WHERE prep_run_id = _id) Then
            RAISE EXCEPTION 'No entry could be found in database for update';
        End If;

        ---------------------------------------------------
        -- Resolve dataset list
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Datasets (
          Dataset text,
          Dataset_ID int NULL
        )

        INSERT INTO Tmp_Datasets( Dataset )
        SELECT Value
        FROM public.parse_delimited_list(_datasets)

        UPDATE Tmp_Datasets
        SET dataset_id = t_dataset.dataset_id
        FROM t_dataset DS
        WHERE Tmp_Datasets.dataset = DS.dataset;

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
                sample_prep_request,
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
                _samplePrepRequest,
                _numberOfRuns,
                _instrumentPressure,
                _qualityControl
            )
            RETURNING prep_run_id
            INTO _id;

            INSERT INTO t_prep_lc_run_dataset ( prep_lc_run_id, dataset_id )
            SELECT _id AS Prep_LC_Run_ID, Dataset_ID
            FROM Tmp_Datasets;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_prep_lc_run
            SET prep_run_name = _prepRunName,
                instrument = _instrument,
                type = _type,
                lc_column = _lcColumn,
                lc_column_2 = _lcColumn2,
                comment = _comment,
                guard_column = _guardColumn,
                operator_username = _operatorUsername,
                digestion_method = _digestionMethod,
                sample_type = _sampleType,
                sample_prep_request = _samplePrepRequest,
                number_of_runs = _numberOfRuns,
                instrument_pressure = _instrumentPressure,
                quality_control = _qualityControl
            WHERE prep_run_id = _id

            -- Add new datasets
            INSERT INTO t_prep_lc_run_dataset
                    ( prep_lc_run_id, dataset_id )
            SELECT _id AS Prep_LC_Run_ID, Dataset_ID
            FROM Tmp_Datasets
            WHERE NOT Tmp_Datasets.dataset_id IN (SELECT dataset_id FROM t_prep_lc_run_dataset WHERE prep_lc_run_id = _id)

            -- Delete removed datasets
            DELETE FROM t_prep_lc_run_dataset
            WHERE prep_lc_run_id = _id AND
                  NOT t_prep_lc_run_dataset.dataset_id IN (SELECT dataset_id FROM Tmp_Datasets)

        End If;

        -- Update the work package list
        CALL public.update_prep_lc_run_work_package_list (
                        _prepLCRunID => _id,
                        _message     => _message,       -- Output
                        _returnCode  => _returnCode);   -- Output

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('%s; Job %s', _exceptionMessage, _job);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_Datasets;
END
$$;

COMMENT ON PROCEDURE public.add_update_prep_lc_run IS 'AddUpdatePrepLCRun';
