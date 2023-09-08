--
-- Name: post_email_alert(text, text, text, text, boolean, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.post_email_alert(IN _type text, IN _message text, IN _postedby text DEFAULT 'na'::text, IN _recipients text DEFAULT 'admins'::text, IN _postmessagetologentries boolean DEFAULT true, IN _duplicateentryholdoffhours integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a new alert to T_Email_Alerts
**
**  Arguments:
**    _type                         Typically Normal, Warning, or Error, but can be any text value
**    _message                      Message to send
**    _postedBy                     Calling procedure name
**    _recipients                   Either a semicolon separated list of e-mail addresses, or a keyword to use to query T_Misc_Paths using 'Email_alert_' || _recipients
**    _postMessageToLogEntries      When true, also post this message to T_Log_Entries
**    _duplicateEntryHoldoffHours   Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
**
**  Auth:   mem
**  Date:   06/14/2018 mem - Initial version
**          08/26/2022 mem - Fix bug subtracting _duplicateEntryHoldoffHours from the current date/time
**          06/14/2023 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(email_alert_id) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _duplicateRowCount int := 0;
    _groupToFind citext;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _type                       := Trim(Coalesce(_type, 'Error'));
    _message                    := Trim(Coalesce(_message, ''));
    _postedBy                   := Trim(Coalesce(_postedBy, 'Unknown'));
    _recipients                 := Trim(Coalesce(_recipients, ''));
    _postMessageToLogEntries    := Coalesce(_postMessageToLogEntries, true);
    _duplicateEntryHoldoffHours := Coalesce(_duplicateEntryHoldoffHours, 0);

    If Coalesce(_duplicateEntryHoldoffHours, 0) > 0 Then
        SELECT COUNT(email_alert_id)
        INTO _duplicateRowCount
        FROM t_email_alerts
        WHERE message = _message AND
              alert_type = _type AND
              posting_time >= CURRENT_TIMESTAMP - make_interval(hours => _duplicateEntryHoldoffHours);
    End If;

    If _duplicateRowCount > 0 Then
        RAISE INFO 'Table t_email_alerts already has a recent entry matching the given alert type and message; not adding a new row';
        RETURN;
    End If;

    If _recipients <> '' And Not _recipients Like '%@%' Then
        _groupToFind := format('Email_alert_%s', _recipients);

        SELECT server
        INTO _recipients
        FROM t_misc_paths
        WHERE path_function::citext = _groupToFind;

        If Not FOUND Then
            RAISE WARNING 'Path function "%" not found in t_misc_paths; will instead look for "Email_alert_admins"', _groupToFind;
         End if;
    End If;

    If Coalesce(_recipients, '') = '' Then
        -- Use the default recipients (admins)
        _groupToFind := 'Email_alert_admins';

        SELECT server
        INTO _recipients
        FROM t_misc_paths
        WHERE path_function::citext = _groupToFind;

        If Not FOUND Then
            RAISE WARNING 'Path function "%" not found in t_misc_paths; using e-mail address proteomics@pnnl.gov', _groupToFind;
            _recipients := 'proteomics@pnnl.gov';
        ElsIf Coalesce(_recipients, '') = '' Then
            RAISE WARNING 'Path function "%" has an empty value in t_misc_paths; using e-mail address proteomics@pnnl.gov', _groupToFind;
            _recipients := 'proteomics@pnnl.gov';
        End If;
    End If;

    INSERT INTO t_email_alerts ( posted_by,
                                 posting_time,
                                 alert_type,
                                 message,
                                 recipients )
    VALUES (_postedBy, CURRENT_TIMESTAMP, _type, _message, _recipients);

    If _postMessageToLogEntries Then
        CALL post_log_entry (_type, _message, _postedBy, _duplicateentryholdoffhours => _duplicateEntryHoldoffHours);
    End If;

END
$$;


ALTER PROCEDURE public.post_email_alert(IN _type text, IN _message text, IN _postedby text, IN _recipients text, IN _postmessagetologentries boolean, IN _duplicateentryholdoffhours integer) OWNER TO d3l243;

--
-- Name: PROCEDURE post_email_alert(IN _type text, IN _message text, IN _postedby text, IN _recipients text, IN _postmessagetologentries boolean, IN _duplicateentryholdoffhours integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.post_email_alert(IN _type text, IN _message text, IN _postedby text, IN _recipients text, IN _postmessagetologentries boolean, IN _duplicateentryholdoffhours integer) IS 'PostEmailAlert';

