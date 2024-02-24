--
-- Name: add_bom_tracking_dataset(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_bom_tracking_dataset(IN _month text DEFAULT ''::text, IN _year text DEFAULT ''::text, IN _instrumentname text DEFAULT ''::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT 'D3E154'::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new tracking dataset for the beginning of the month (BOM) for the given month, year, and instrument
**
**      If _month is 'next', adds a tracking dataset for the beginning of the next month
**
**  Arguments:
**    _month            Month (use the current month if blank)
**    _year             Year  (use the current year if blank)
**    _instrumentName   Instrument
**    _mode             Mode: 'add' or 'debug'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user
**
**  Auth:   grk
**  Date:   12/14/2012
**          12/14/2012 grk - Initial release
**          12/16/2012 grk - Added concept of 'next' month
**          02/01/2013 grk - Fixed broken logic for specifying year/month
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/14/2022 mem - Update error messages to show the correct dataset name
**                         - When _mode is 'debug', update _message to include the run start date and dataset name
**          02/15/2022 mem - Mention Update_Dataset_Interval and T_Run_Interval in the debug message
**          02/22/2022 mem - When _mode is 'debug', do not log an error if the dataset already exists
**          08/25/2023 mem - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/12/2023 mem - Update call to add_update_tracking_dataset
**          01/20/2024 mem - Ignore case when looking for an existing dataset by name
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _datasetName text;
    _runStart text;
    _experimentName text := 'Tracking';
    _operatorUsername text;
    _runDuration text := '10';
    _comment text := '';
    _eusProposalID text := '';
    _eusUsageType text := 'MAINTENANCE';
    _eusUsersList text := '';
    _now timestamp;
    _mn int;
    _yr int;
    _bom timestamp;
    _dateLabel text;
    _instID int := 0;
    _conflictingDataset text := '';
    _datasetID int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If Trim(Coalesce(_instrumentName, '')) = '' Then
        _message := 'Instrument name cannot be empty';

        If _mode = 'debug' Then
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    If _mode = 'add' Then
        _logErrors := true;
    End If;

    BEGIN
        _operatorUsername := _callingUser;

        _month := Trim(Lower(Coalesce(_month, '')));
        _year  := Trim(Lower(Coalesce(_year, '')));

        ---------------------------------------------------
        -- Determine the beginning of month (BOM) date to use
        ---------------------------------------------------

        _now := CURRENT_TIMESTAMP;

        If _month = '' Or _month = 'next' Then
            _mn := Extract(month from _now)::text;
        Else
            _mn := public.try_cast(_month, null::int);

            If _mn Is Null Then
                _message := format('_month must be an integer, an empty string, or "next", not "%s"', _month);

                If _mode = 'debug' Then
                    RAISE WARNING '%', _message;
                    RETURN;
                End If;

                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        If _year = '' Or _month = 'next' Then
            _yr := Extract(year FROM _now)::text;
        Else
            _yr := public.try_cast(_year, null::int);

            If _yr Is Null Then
                _message := format('_year must be an integer or an empty string, not "%s"', _year);

                If _mode = 'debug' Then
                    RAISE WARNING '%', _message;
                    RETURN;
                End If;

                RAISE EXCEPTION '%', _message;
            End If;

        End If;

        _bom := make_date(_yr, _mn, 1)::timestamp;

        If _month = 'next' Then
            _bom := _bom + INTERVAL '1 month';  -- Beginning of the next month after _bom
        End If;

        _runStart := _bom;

        -- Format the date as day, month abbreviation, year, e.g. 01Jun22

        _dateLabel := to_char(_bom, 'ddMonyy');

        _datasetName := format('%s_%s', _instrumentName, _dateLabel);

        ---------------------------------------------------
        -- Is it OK to make the dataset?
        ---------------------------------------------------

        SELECT instrument_id
        INTO _instID
        FROM t_instrument_name
        WHERE instrument = _instrumentName;

        If Not FOUND Then
            _message := format('Instrument "%s" does not exist', _instrumentName);

            If _mode = 'debug' Then
                RAISE WARNING '%', _message;
                RETURN;
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        If Exists (SELECT dataset_id FROM t_dataset WHERE dataset = _datasetName::citext) Then
            _message := format('Dataset already exists: %s', _datasetName);

            If _mode = 'debug' Then
                RAISE WARNING '%', _message;
                RETURN;
            Else
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        SELECT dataset, dataset_id
        INTO _conflictingDataset, _datasetID
        FROM t_dataset
        WHERE acq_time_start = _bom AND instrument_id = _instID;

        If FOUND Then
            _message := format('Dataset "%s" has same start time as the new tracking dataset (see Dataset ID %s)', _conflictingDataset, _datasetID);

            If _mode = 'debug' Then
                RAISE WARNING '%', _message;
                RETURN;
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        _conflictingDataset := '';

        SELECT dataset, dataset_id
        INTO _conflictingDataset, _datasetID
        FROM t_dataset
        WHERE NOT acq_time_start IS NULL AND
              NOT acq_time_end IS NULL AND
              _bom BETWEEN acq_time_start AND acq_time_end AND
              instrument_id = _instID;

        If FOUND Then
            _message := format('Tracking dataset would overlap with existing dataset "%s" (Dataset ID %s)', _conflictingDataset, _datasetID);

            If _mode = 'debug' Then
                RAISE WARNING '%', _message;
                RETURN;
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        If _mode = 'debug' Then
            ---------------------------------------------------
            -- Show debug info
            ---------------------------------------------------

            RAISE INFO '';
            RAISE INFO 'Dataset:             %', _datasetName;
            RAISE INFO 'Run Start:           %', _runStart;
            RAISE INFO 'Experiment:          %', _experimentName;
            RAISE INFO 'Operator Username:   %', _operatorUsername;
            RAISE INFO 'Run Duration:        %', _runDuration;
            RAISE INFO 'Comment:             %', _comment;
            RAISE INFO 'EUS Proposal:        %', _eusProposalID;
            RAISE INFO 'EUS Usage Type:      %', _eusUsageType;
            RAISE INFO 'EUS Users:           %', _eusUsersList;
            RAISE INFO 'mode:                %', _mode;

            -- Note that Add_Update_Tracking_Dataset calls Update_Dataset_Interval after creating the dataset
            _message := format('Would create dataset with run start %s and name ''%s'', then call Update_Dataset_Interval to update t_run_interval',
                                _runStart, _datasetName);
        End If;

        If _mode = 'add' Then
            ---------------------------------------------------
            -- Add the tracking dataset
            ---------------------------------------------------

            CALL public.add_update_tracking_dataset (
                                _datasetName,
                                _experimentName,
                                _operatorUsername,
                                _instrumentName,
                                _runStart,
                                _runDuration,
                                _comment,
                                _eusProposalID,
                                _eusUsageType,
                                _eusUsersList,
                                _mode,
                                _message    => _message,        -- Output
                                _returnCode => _returnCode,     -- Output
                                _callingUser => _callingUser);
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => _logErrors);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;
END
$$;


ALTER PROCEDURE public.add_bom_tracking_dataset(IN _month text, IN _year text, IN _instrumentname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_bom_tracking_dataset(IN _month text, IN _year text, IN _instrumentname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_bom_tracking_dataset(IN _month text, IN _year text, IN _instrumentname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddBOMTrackingDataset';

