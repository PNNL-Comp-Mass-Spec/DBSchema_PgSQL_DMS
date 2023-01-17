--
-- Name: validate_instrument_group_for_requested_runs(text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_instrument_group_for_requested_runs(IN _reqrunidlist text, IN _instrumentgroup text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validates that the specified instrument group is valid for the dataset types defined for the requested runs in _reqRunIDList
**
**  Arguments:
**    _reqRunIDList         Comma separated list of requested run IDs
**    _instrumentGroup      Instrument group name
**    _message              Output: Status message if the group is valid; warning message if the instrument group is not valid
**    _returnCode           Output: Empty string if the instrument group is valid, 'U5205' if the instrument group is not valid for the dataset types
**
**  Auth:   mem
**  Date:   01/15/2023 mem - Initial version (code refactored code from UpdateRequestedRunAssignments)
**
*****************************************************/
DECLARE
    _requestInfo record;
    _allowedDatasetTypes text;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _message := '';
    _returnCode := '';

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _reqRunIDList := Trim(Coalesce(_reqRunIDList, ''));
        _instrumentGroup := Trim(Coalesce(_instrumentGroup, ''));

        If _reqRunIDList = '' Then
            _message := 'Argument _reqRunIDList is an empty string';
            _returnCode := 'U5201';

            RETURN;
        End If;

        If Not Exists (Select * From T_Instrument_Group Where instrument_group = _instrumentGroup::citext) Then
            _message := 'Invalid instrument group name: ' || _instrumentGroup;
            _returnCode := 'U5202'

            RETURN;
        End If;

        ---------------------------------------------------
        -- Populate a temporary table with the dataset type associated with the requested run IDs in _reqRunIDList
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetTypeList (
            DatasetTypeName text,
            DatasetTypeID int,
            RequestIDCount int,
            RequestIDFirst int,
            RequestIDLast int
        );

        INSERT INTO Tmp_DatasetTypeList (
            DatasetTypeName,
            DatasetTypeID,
            RequestIDCount,
            RequestIDFirst,
            RequestIDLast
        )
        SELECT DST.Dataset_Type AS DatasetTypeName,
               DST.dataset_type_id AS DatasetTypeID,
               COUNT(RR.request_id) AS RequestIDCount,
               MIN(RR.request_id) AS RequestIDFirst,
               MAX(RR.request_id) AS RequestIDFirst
        FROM ( SELECT Distinct value AS request_id
               FROM public.parse_delimited_integer_list ( _reqRunIDList )
             ) AS RequestQ
             INNER JOIN T_Requested_Run RR
               ON RequestQ.request_id = RR.request_id
             INNER JOIN T_Dataset_Type_Name DST
               ON RR.request_type_id = DST.dataset_type_id
        GROUP BY DST.Dataset_Type, DST.dataset_type_id;

        If Not FOUND Then
            _message := 'Requested run IDs not found in T_Requested_Run: ' || _reqRunIDList;
            _returnCode := 'U5203';

            DROP TABLE Tmp_DatasetTypeList;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the dataset type defined for each of the requested runs
        -- is appropriate for instrument group _instrumentGroup
        ---------------------------------------------------

        FOR _requestInfo IN
            SELECT DatasetTypeID,
                   DatasetTypeName,
                   RequestIDCount,
                   RequestIDFirst,
                   RequestIDLast
            FROM Tmp_DatasetTypeList
            ORDER BY DatasetTypeID
        LOOP
            ---------------------------------------------------
            -- Verify that dataset type is valid for given instrument group
            ---------------------------------------------------

            If Not Exists (SELECT *
                           FROM t_instrument_group_allowed_ds_type
                           WHERE instrument_group = _instrumentGroup::citext AND dataset_type = _requestInfo.DatasetTypeName) Then

                _allowedDatasetTypes := get_instrument_group_dataset_type_list(_instrumentGroup::citext, ', ');

                _message := format('Dataset type "%s" is invalid for instrument group "%s"; valid types are "%s"',
                                _requestInfo.DatasetTypeName, _instrumentGroup, _allowedDatasetTypes);

                If _requestInfo.RequestIDCount > 1 Then
                    _message := format('%s; %s conflicting Request IDs, ranging from ID %s to %s', _message, _requestInfo.RequestIDCount, _requestInfo.RequestIDFirst, _requestInfo.RequestIDLast);
                Else
                    _message := format('%s; conflicting Request ID is %s', _message, _requestInfo.equestIDFirst);
                End If;

                _returnCode := 'U5205'

                -- Break out of the while loop
                EXIT;

            End If;

        END LOOP;

        If _returnCode = '' Then
            SELECT Sum(RequestIDCount) AS RequestIDCount,
                   Min(RequestIDFirst) AS RequestIDFirst,
                   Min(RequestIDLast) AS RequestIDLast
            INTO _requestInfo
            FROM Tmp_DatasetTypeList;

            If _requestInfo.RequestIDCount = 1 Then
                _message := format('Instrument group %s is valid for requested run ID %s', _instrumentGroup, _requestInfo.RequestIDFirst);
            Else
                _message := format('Instrument group %s is valid for all %s requested runs (%s - %s)',
                                    _instrumentGroup, _requestInfo.RequestIDCount, _requestInfo.RequestIDFirst, _requestInfo.RequestIDLast);
            End If;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage = _exceptionMessage || '; Requests ';

        If char_length(_reqRunIDList) < 128 Then
            _logMessage := _logMessage || _reqRunIDList;
        Else
            _logMessage := _logMessage || Substring(_reqRunIDList, 1, 128) || ' ...';
        End If;

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    DROP TABLE IF EXISTS Tmp_DatasetTypeList;
END
$$;


ALTER PROCEDURE public.validate_instrument_group_for_requested_runs(IN _reqrunidlist text, IN _instrumentgroup text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;
