--
CREATE OR REPLACE PROCEDURE public.ack_email_alerts
(
    _alertIDs text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the state of alerts in T_Email_Alerts
**      The DMSEmailManager calls this procedure after e-mailing admins regarding alerts with state 1
**
**  Auth:   mem
**  Date:   06/16/2018 mem - Initial Version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _alertCountToUpdate int := 0;
    _alertCountUpdated int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _alertIDs := Coalesce(_alertIDs, '');
    _infoOnly := Coalesce(_infoOnly, true);

    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Create a temporary table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_AlertIDs (
        AlertID int NOT NULL
    );

    INSERT INTO Tmp_AlertIDs( AlertID )
    SELECT Value
    FROM public.parse_delimited_integer_list ( _alertIDs, ',' );

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

    If Not _infoOnly Then
        UPDATE t_email_alerts
        SET alert_state = 2
        FROM t_email_alerts Alerts

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE t_email_alerts
        **   SET ...
        **   FROM source
        **   WHERE source.email_alert_id = t_email_alerts.email_alert_id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN Tmp_AlertIDs
               ON Alerts.ID = Tmp_AlertIDs.AlertID
        WHERE Alerts.Alert_State = 1
        --
        GET DIAGNOSTICS _alertCountUpdated = ROW_COUNT;

        _message := format('Acknowledged %s %s in t_email_alerts',
                            _alertCountUpdated, public.check_plural(_alertCountUpdated, 'alert', 'alerts'));

        If _alertCountUpdated < _alertCountToUpdate Then
            _message := _message || '; one or more alerts were skipped since already acknowledged';
        End If;

        CALL post_log_entry ('Normal', _message, 'Ack_Email_Alerts');

    Else
        SELECT Alerts.*
        FROM V_Email_Alerts Alerts
             INNER JOIN Tmp_AlertIDs
               ON Alerts.ID = Tmp_AlertIDs.AlertID
        ORDER BY Alerts.ID
    End If;

    DROP TABLE Tmp_AlertIDs;
END
$$;

COMMENT ON PROCEDURE public.ack_email_alerts IS 'AckEmailAlerts';
