--
CREATE OR REPLACE PROCEDURE public.add_bom_tracking_dataset
(
    _month text = '',
    _year text = '',
    _instrumentName text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text  = 'D3E154',
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new tracking dataset for the beginning of the month (BOM)
**      for the given year, month, and instrument
**
**      If _month is 'next', adds a tracking dataset for the beginning of the next month
**
**  Arguments:
**    _month            Month (use the current month if blank)
**    _year             Year  (use the current year if blank)
**    _instrumentName   Instrument
**    _mode             Mode: 'add' or 'debug'
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
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
    _mn text;
    _yr text;
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
    -- Validate input arguments
    ---------------------------------------------------

    If Coalesce(_instrumentName, '') = '' Then
        RAISE EXCEPTION 'Instrument name cannot be empty';
    End If;

    _mode := Lower(_mode);

    ---------------------------------------------------
    -- Declare parameters for making BOM tracking dataset
    ---------------------------------------------------

    BEGIN
        _operatorUsername := _callingUser;

        _month := Trim(Coalesce(_month, ''));
        _year  := Trim(Coalesce(_year, ''));

        ---------------------------------------------------
        -- Determine the beginning of month (BOM) date to use
        ---------------------------------------------------

        _now := CURRENT_TIMESTAMP;
        _mn := _month;
        _yr := _year;

        If _month = '' OR _month = 'next' Then
            _mn := Extract(month from _now)::text;
        End If;

        If _year = '' OR _month = 'next' Then
            _yr := Extract(year from _now)::text;
        End If;

        -- make_date() accepts numbers stored as text, but will report an error if _yr or _mn are not integers
        --
        _bom := make_date(_yr, _mn, 1)::timestamp;

        If _month = 'next' Then
            _bom := _bom + Interval '1 month';  -- Beginning of the next month after _bom
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
            RAISE EXCEPTION 'Instrument "%" cannot be found', _instrumentName;
        End If;

        If Exists (SELECT * FROM t_dataset WHERE dataset = _datasetName) Then
            If _mode = 'debug' Then
                _message := format('Dataset already exists: %s', _datasetName);
                RAISE INFO '%', _message;
                RETURN;
            Else
                RAISE EXCEPTION 'Dataset "%" already exists', _datasetName;
            End If;
        End If;

        SELECT dataset, dataset_id
        INTO _conflictingDataset, _datasetID
        FROM t_dataset
        WHERE acq_time_start = _bom AND instrument_id = _instID;

        If (_conflictingDataset <> '') Then
            _message := format('Dataset "%s" has same start time, Dataset ID %s', _conflictingDataset, _datasetID);
            RAISE EXCEPTION '%', _message;
        End If;

        _conflictingDataset := '';

        SELECT dataset, dataset_id
        INTO _conflictingDataset, _datasetID
        FROM t_dataset
        WHERE (Not (acq_time_start IS NULL)) AND
              (Not (acq_time_end IS NULL)) AND
              _bom BETWEEN acq_time_start AND acq_time_end AND
              instrument_id = _instID;

        If (_conflictingDataset <> '') Then
             _message := format('Tracking dataset would overlap existing dataset "%s", Dataset ID %s', _conflictingDataset, _datasetID;);
            RAISE EXCEPTION '%', _message;
        End If;

        If _mode = 'debug' Then
            ---------------------------------------------------
            -- Show debug info
            ---------------------------------------------------

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

            CALL add_update_tracking_dataset (
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
                                _message,           -- Output
                                _callingUser);
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
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;
END
$$;

COMMENT ON PROCEDURE public.add_bom_tracking_dataset IS 'AddBOMTrackingDataset';
