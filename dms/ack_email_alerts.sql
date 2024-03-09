--
-- Name: ack_email_alerts(text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.ack_email_alerts(IN _alertids text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the state of alerts in T_Email_Alerts
**      The DMSEmailManager calls this procedure after e-mailing admins regarding alerts with state 1
**
**  Arguments:
**    _alertIDs     Comma-separated list of alert IDs
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   06/16/2018 mem - Initial Version
**          08/23/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _alertCountToUpdate int := 0;
    _alertCountUpdated int := 0;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _alertIDs := Coalesce(_alertIDs, '');
    _infoOnly := Coalesce(_infoOnly, true);

    ---------------------------------------------------
    -- Create a temporary table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_AlertIDs (
        AlertID int NOT NULL
    );

    INSERT INTO Tmp_AlertIDs (AlertID)
    SELECT Value
    FROM public.parse_delimited_integer_list ( _alertIDs );

    SELECT COUNT(*)
    INTO _alertCountToUpdate
    FROM Tmp_AlertIDs;

    If _alertCountToUpdate = 0 Then
        _message := format('No integers were found in %s',_alertIDs);
        DROP TABLE Tmp_AlertIDs;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update the alerts or preview changes
    ---------------------------------------------------

    If _infoOnly Then
        RAISE INFO '';

        _formatSpecifier := '%-6s %-20s %-20s %-10s %-80s %-50s %-11s %-11s %-20s';

        _infoHead := format(_formatSpecifier,
                            'ID',
                            'Posted_By',
                            'Posting_Time',
                            'Alert_Type',
                            'Message',
                            'Recipients',
                            'Alert_State',
                            'State_Name',
                            'Last_Affected'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------',
                                     '--------------------',
                                     '--------------------',
                                     '----------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------------------------------------',
                                     '-----------',
                                     '-----------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Alerts.id,
                   Alerts.posted_by,
                   public.timestamp_text(Alerts.posting_time) AS posting_time,
                   Alerts.alert_type,
                   Alerts.message,
                   Alerts.recipients,
                   Alerts.alert_state,
                   Alerts.alert_state_name AS State_Name,
                   public.timestamp_text(Alerts.last_affected) AS last_affected
            FROM public.V_Email_Alerts Alerts
                 INNER JOIN Tmp_AlertIDs
                   ON Alerts.ID = Tmp_AlertIDs.AlertID
            ORDER BY Alerts.ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.ID,
                                _previewData.Posted_By,
                                _previewData.Posting_Time,
                                _previewData.Alert_Type,
                                _previewData.Message,
                                _previewData.Recipients,
                                _previewData.Alert_State,
                                _previewData.State_Name,
                                _previewData.Last_Affected
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_AlertIDs;
        RETURN;
    End If;

    UPDATE t_email_alerts Alerts
    SET alert_state = 2
    FROM Tmp_AlertIDs
    WHERE Alerts.Alert_State = 1 AND
          Alerts.ID = Tmp_AlertIDs.AlertID;
    --
    GET DIAGNOSTICS _alertCountUpdated = ROW_COUNT;

    _message := format('Acknowledged %s %s in t_email_alerts',
                       _alertCountUpdated, public.check_plural(_alertCountUpdated, 'alert', 'alerts'));

    If _alertCountUpdated < _alertCountToUpdate Then
        _message := format('%s; one or more alerts were skipped since already acknowledged', _message);
    End If;

    CALL post_log_entry ('Normal', _message, 'Ack_Email_Alerts');

    DROP TABLE Tmp_AlertIDs;
END
$$;


ALTER PROCEDURE public.ack_email_alerts(IN _alertids text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE ack_email_alerts(IN _alertids text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.ack_email_alerts(IN _alertids text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AckEmailAlerts';

