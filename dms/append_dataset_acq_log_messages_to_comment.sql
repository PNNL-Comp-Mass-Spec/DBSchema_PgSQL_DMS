--
-- Name: append_dataset_acq_log_messages_to_comment(integer, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.append_dataset_acq_log_messages_to_comment(IN _datasetid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Append the dataset's acquisition log messages to the dataset's comment
**
**  Arguments:
**    _datasetID            Dataset ID
**    _message              Status message
**    _returnCode           Return code
**    _infoOnly             When true, preview updates
**
**  Auth:   mem
**  Date:   10/23/2026 mem - Initial version
**
*****************************************************/
DECLARE
    _datasetName text;
    _datasetComment text;

    _messageCount int;
    _messages text := '';
    _messageInfo record;

    _currentLocation text := 'Start';
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

        _datasetID := Coalesce(_datasetID, 0);
        _infoOnly  := Coalesce(_infoOnly, false);

        ---------------------------------------------------
        -- Validate the Dataset ID
        ---------------------------------------------------

        _currentLocation := 'Validate _datasetID';

        If _datasetID = 0 Then
            _message := 'Dataset ID is 0; unable to continue';
            RAISE WARNING '%', _message;

            _returnCode := '5201';
            RETURN;
        End If;

        SELECT dataset, Coalesce(comment, '') AS Dataset_Comment
        INTO _datasetName, _datasetComment
        FROM t_dataset
        WHERE dataset_id = _datasetID;

        If Not FOUND Then
            _message := 'Dataset ID % not found in t_dataset; unable to continue';
            RAISE WARNING '%', _message;

            _returnCode := '5202';
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Create a temporary table to hold the data
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Acq_Log_Messages (
            Msg_Type text not null,
            Message text not null
        );

        -----------------------------------------------------------
        -- Obtain the first five acquisition log messages for each category, then concatenate
        -----------------------------------------------------------

        _currentLocation := 'Look for acquisition log messages';

        INSERT INTO Tmp_Acq_Log_Messages (msg_type, message)
        SELECT msg_type, message
        FROM (SELECT msg_type, message
              FROM t_dataset_acq_messages
              WHERE dataset_id = _datasetID AND msg_type = 'Error'
              ORDER BY entry_id LIMIT 5
             ) ErrorQ
        UNION
        SELECT msg_type, message
        FROM (SELECT msg_type, message
              FROM t_dataset_acq_messages
              WHERE dataset_id = _datasetID AND msg_type = 'Warning'
              ORDER BY entry_id LIMIT 5
             ) WarningQ
        UNION
        SELECT msg_type, message
        FROM (SELECT msg_type, message
              FROM t_dataset_acq_messages
              WHERE dataset_id = _datasetID AND msg_type = 'Failure'
              ORDER BY entry_id LIMIT 5
             ) FailureQ
        UNION
        SELECT msg_type, message
        FROM (SELECT msg_type, message
              FROM t_dataset_acq_messages
              WHERE dataset_id = _datasetID AND NOT msg_type IN ('Error', 'Warning', 'Failure')
              ORDER BY entry_id LIMIT 5
             ) ExtrasQ;

        If Not FOUND Then
            RAISE INFO 'Dataset ID % does not have any acquisition log messages in t_dataset_acq_messages; nothing to do for %', _datasetID, _datasetName;

            DROP TABLE Tmp_Acq_Log_Messages;
            RETURN;
        End If;

        SELECT COUNT(DISTINCT message)
        INTO _messageCount
        FROM Tmp_Acq_Log_Messages;

        FOR _messageInfo IN
            SELECT LogMsgs.Msg_Type AS MsgType,
                   LogMsgs.Message  AS Message
            FROM Tmp_Acq_Log_Messages LogMsgs
        LOOP
            _messages := append_to_text(_messages,
                                        format('%s, %s', _messageInfo.MsgType, Trim(regexp_replace(_messageInfo.Message, '\n', ''))),
                                        _addDuplicateText => false);
        END LOOP;

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'Acquisition log messages for Dataset ID % (%)', _datasetID, _datasetName;
            RAISE INFO '%', _messages;

            DROP TABLE Tmp_Acq_Log_Messages;
            RETURN;
        End If;

        If _messageCount > 1 Then
            _messages := format('%s: %s', 'Acquisition log messages', _messages);
        Else
            _messages := format('%s: %s', 'Acquisition log message', _messages);
        End If;

        -----------------------------------------------
        -- Append the messages to the dataset's comment, then update the database
        -----------------------------------------------

        _datasetComment := append_to_text(_datasetComment, _messages, _addDuplicateText => false);

        UPDATE t_dataset
        SET comment = _datasetComment
        WHERE dataset_id = _datasetID;

        DROP TABLE Tmp_Acq_Log_Messages;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_Acq_Log_Messages;
    END;
END
$$;


ALTER PROCEDURE public.append_dataset_acq_log_messages_to_comment(IN _datasetid integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

