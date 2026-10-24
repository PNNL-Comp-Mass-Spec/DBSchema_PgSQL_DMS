--
-- Name: update_dataset_acq_log_messages(integer, xml, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_acq_log_messages(IN _datasetid integer DEFAULT 0, IN _logmessagesxml xml DEFAULT NULL::xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Store the acquisition log messages for the dataset specified by _datasetID
**
**      Data is stored in T_Dataset_Acq_Messages
**
**      If _datasetID is 0, will use the dataset name defined in _logMessagesXML
**      If _datasetID is non-zero, will validate that the Dataset Name in the XML corresponds to the dataset ID specified by _datasetID
**
**      Typical XML file contents:
**
**      <AcquisitionLogMessages>
**        <Dataset>20260210_NatFA_new_WK_60min_Pos_000002</Dataset>
**        <LogMessages>
**          <Message MessageType="Warning" ObservationCount="222" ElutionTimeMin="0.85" ElutionTimeMax="45.32">Status log message</Message>
**          <Message MessageType="Error" ObservationCount="1" ElutionTimeMin="0.01" ElutionTimeMax="0.01">Error log message</Message>
**        </LogMessages>
**      </AcquisitionLogMessages>
**
**  Arguments:
**    _datasetID            If this value is 0, determines the dataset name using the contents of _logMessagesXML
**    _logMessagesXML       XML describing the properties of a single dataset
**    _message              Status message
**    _returnCode           Return code
**    _infoOnly             When true, preview updates
**
**  Auth:   mem
**  Date:   10/20/2026 mem - Initial version
**          10/21/2026 mem - Remove messages that we do not want to store in the database
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetName text;
    _comparisonDate date;
    _usageMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _currentLocation text := 'Start';
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

        _datasetID := Coalesce(_datasetID, 0);
        _infoOnly  := Coalesce(_infoOnly, false);

        ---------------------------------------------------
        -- Examine the XML to determine the dataset name and update or validate _datasetID
        ---------------------------------------------------

        _currentLocation := 'Call get_dataset_details_from_dataset_info_xml';

        CALL public.get_dataset_details_from_dataset_info_xml (
                        _logMessagesXML,
                        _rootElement => 'AcqLogMessages',
                        _sourceTable => '',
                        _datasetID   => _datasetID,     -- Input/Output
                        _datasetName => _datasetName,   -- Output
                        _message     => _message,       -- Output
                        _returnCode  => _returnCode);   -- Output

        If _returnCode <> '' Then
            RETURN;
        End If;

        If Coalesce(_datasetID, 0) = 0 Then
            If Coalesce(_message, '') = '' Then
                _message := 'Procedure get_dataset_details_from_dataset_info_xml returned 0 for dataset ID; unable to continue';
            End If;

            _returnCode := '5201';
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Create a temporary table to hold the data
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Acq_Log_Messages (
            Dataset_ID int null,
            Dataset_Name text not null,
            Msg_Type text not null,
            Message text not null,
            Obs_Count int null,
            Elution_Time_Min numeric null,
            Elution_Time_Max numeric null
        );

        ---------------------------------------------------
        -- Parse the contents of _logMessagesXML to populate Tmp_Acq_Log_Messages
        --
        -- Use XMLTABLE since there can be multiple messages
        ---------------------------------------------------

        _currentLocation := 'Parse _logMessagesXML and populate Tmp_Acq_Log_Messages';

        INSERT INTO Tmp_Acq_Log_Messages (
            Dataset_ID,
            Dataset_Name,
            Msg_Type,
            Message,
            Obs_Count,
            Elution_Time_Min,
            Elution_Time_Max
        )
        SELECT _datasetID                                       AS Dataset_ID,
               _datasetName                                     AS Dataset,
               Trim(XmlQ.MessageType)                           AS Msg_Type,
               Trim(XmlQ.Message)                               AS Message,
               public.try_cast(XmlQ.ObservationCount, 0)        AS Obs_Count,
               public.try_cast(XmlQ.ElutionTimeMin, 0::numeric) AS Elution_Time_Min,
               public.try_cast(XmlQ.ElutionTimeMax, 0::numeric) AS Elution_Time_Max
        FROM (
            SELECT xmltable.*
            FROM (SELECT _logMessagesXML AS rooted_xml
                 ) Src,
                 XMLTABLE('//AcqLogMessages/Messages/Message'
                          PASSING Src.rooted_xml
                          COLUMNS Message   text PATH '.',
                                  MessageType  text PATH '@MessageType',
                                  ObservationCount text PATH '@ObservationCount',
                                  ElutionTimeMin text PATH '@ElutionTimeMin',
                                  ElutionTimeMax text PATH '@ElutionTimeMax')
             ) XmlQ
        WHERE NOT XmlQ.Message IS NULL;

        ---------------------------------------------------
        -- Make sure Dataset_ID is up-to-date in Tmp_Acq_Log_Messages
        ---------------------------------------------------

        UPDATE Tmp_Acq_Log_Messages
        SET Dataset_ID = _datasetID;

        If _infoOnly Then
            -----------------------------------------------
            -- Preview the data, then exit
            -----------------------------------------------

            _currentLocation := 'Preview data';

            RAISE INFO '';
            RAISE INFO 'Acquisition Log Messages for Dataset ID %: %', _datasetID, _datasetName;
            RAISE INFO '';

            _formatSpecifier := '%-12s %-17s %-16s %-16s %-30s ';

            _infoHead := format(_formatSpecifier,
                                'Message_Type',
                                'Observation_Count',
                                'Elution_Time_Min',
                                'Elution_Time_Max',
                                'Message'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '------------',
                                         '-----------------',
                                         '----------------',
                                         '----------------',
                                         '------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT LogMsgs.Msg_Type           AS MsgType,
                       LogMsgs.Obs_Count          AS ObsCount,
                       LogMsgs.Elution_Time_Min   AS ElutionTimeMin,
                       LogMsgs.Elution_Time_Max   AS ElutionTimeMax,
                       LogMsgs.Message            AS Message
                FROM Tmp_Acq_Log_Messages LogMsgs
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.MsgType,
                                    _previewData.ObsCount,
                                    _previewData.ElutionTimeMin,
                                    _previewData.ElutionTimeMax,
                                    _previewData.Message
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_Acq_Log_Messages;
            RETURN;
        End If;

        -----------------------------------------------
        -- Remove messages that we do not want to store in the database
        -----------------------------------------------

        _currentLocation := 'Remove messages to ignore';

        DELETE FROM Tmp_Acq_Log_Messages
        WHERE message LIKE 'Warning%Ambient temperature change%' OR
              message IN (
                  'Info : Info: Performance - Affected: Mass Calibration (negative) - Default Values',
                  'Info : Info: Performance - Affected: System Calibration (negative) - Default Values',
                  'Info : In-Source Trapping is now Off',
                  'Info : In-Source Trapping is now On',
                  'Info : Instrument status Ok',
                  'Info : Lens Mode Enabled',
                  'Info : Manual Control of Inject Flatapole and Bent Flatapole RF Vp-p',
                  'Info : The RF Vp-p of the transfer optics is set for high m/z',
                  'Info : The RF Vp-p of the transfer optics is set for low m/z'
                  ) OR
              message LIKE 'Info : MS acquisition end. Accumulated MS size%' OR
              message LIKE 'Warning%Sequence counter matches again%';

        -----------------------------------------------
        -- Add/update t_dataset_acq_messages using a merge statement
        -----------------------------------------------

        _currentLocation := 'Update t_dataset_acq_messages using a merge';

        MERGE INTO t_dataset_acq_messages AS target
        USING (SELECT dataset_id,
                      message,
                      msg_type,
                      obs_count,
                      elution_time_min,
                      elution_time_max
               FROM Tmp_Acq_Log_Messages
              ) AS Source
        ON (target.dataset_id = Source.dataset_id and
            target.msg_type   = Source.msg_type and
            target.message    = Source.message)
        WHEN MATCHED THEN
            UPDATE SET
                obs_count         = Source.obs_count,
                elution_time_min  = Source.elution_time_min,
                elution_time_max  = Source.elution_time_max,
                last_affected     = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (dataset_id,
                    message,
                    msg_type,
                    obs_count,
                    elution_time_min,
                    elution_time_max,
                    last_affected)
            VALUES (Source.dataset_id,
                    Source.message,
                    Source.msg_type,
                    Source.obs_count,
                    Source.elution_time_min,
                    Source.elution_time_max,
                    CURRENT_TIMESTAMP
                   );

        _currentLocation := 'Delete extra rows from t_dataset_acq_messages';

        DELETE FROM t_dataset_acq_messages target
        WHERE target.dataset_id = _datasetID AND
              NOT EXISTS (SELECT 1
                          FROM Tmp_Acq_Log_Messages Source
                          WHERE target.msg_type = Source.msg_type and
                                target.message  = Source.message);

        ---------------------------------------------------
        -- Log SP usage
        ---------------------------------------------------

        _currentLocation := 'Call post_usage_log_entry';

        If Coalesce(_datasetName, '') = '' Then
            _usageMessage := format('Dataset ID: %s', _datasetId);
        Else
            _usageMessage := format('Dataset: %s', _datasetName);
        End If;

        CALL post_usage_log_entry ('update_dataset_acq_log_messages', _usageMessage);

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


ALTER PROCEDURE public.update_dataset_acq_log_messages(IN _datasetid integer, IN _logmessagesxml xml, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

