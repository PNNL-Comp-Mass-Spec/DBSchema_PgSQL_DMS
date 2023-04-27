--
CREATE OR REPLACE PROCEDURE public.post_email_alert
(
    _type text,
    _message text,
    _postedBy text = 'na',
    _recipients text = 'admins',
    _postMessageToLogEntries int = 1,
    _duplicateEntryHoldoffHours int = 0
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add a new elert to T_Email_Alerts
**
**  Arguments:
**    _type                         Typically Normal, Warning, or Error, but can be any text value
**    _recipients                   Either a semicolon separated list of e-mail addresses, or a keyword to use to query T_MiscPaths using 'Email_alert_' + _recipients
**    _postMessageToLogEntries      When 1, also post this message to T_Log_Entries
**    _duplicateEntryHoldoffHours   Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
**
**  Auth:   mem
**  Date:   06/14/2018 mem - Initial version
**          08/26/2022 mem - Fix bug subtracting _duplicateEntryHoldoffHours from the current date/time
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _duplicateRowCount int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _type := Rtrim(Ltrim(Coalesce(_type, 'Error')));
    _message := Rtrim(Ltrim(Coalesce(_message, '')));
    _postedBy := Rtrim(Ltrim(Coalesce(_postedBy, 'Unknown')));
    _recipients := Rtrim(Ltrim(Coalesce(_recipients, '')));
    _postMessageToLogEntries := Coalesce(_postMessageToLogEntries, 1);
    _duplicateEntryHoldoffHours := Coalesce(_duplicateEntryHoldoffHours, 0);

    If Coalesce(_duplicateEntryHoldoffHours, 0) > 0 Then
        SELECT COUNT(*)
        INTO _duplicateRowCount
        FROM t_email_alerts
        WHERE message = _message AND
              alert_type = _type AND
              posting_time >= CURRENT_TIMESTAMP - make_interval(hours => _duplicateEntryHoldoffHours);
    End If;

    If _duplicateRowCount > 0 Then
        RETURN;
    End If;

    If _recipients <> '' And Not _recipients Like '%@%' Then
        SELECT server
        INTO _recipients
        FROM   t_misc_paths
        WHERE (path_function = 'Email_alert_' || _recipients)
    End If;

    If _recipients = '' Then
        -- Use the default recipients
        SELECT server
        INTO _recipients
        FROM t_misc_paths
        WHERE path_function = 'Email_alert_admins';

        If _recipients = '' Then
            _recipients := 'proteomics_pnnl.gov';
        End If;
    End If;

    INSERT INTO t_email_alerts ( posted_by,
                                 posting_time,
                                 alert_type,
                                 message,
                                 recipients )
    VALUES (_postedBy, CURRENT_TIMESTAMP, _type, _message, _recipients);
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _postMessageToLogEntries > 0 Then
        Call post_log_entry _type, _message, _postedBy, _duplicateEntryHoldoffHours
    End If;

END
$$;

COMMENT ON PROCEDURE public.post_email_alert IS 'PostEmailAlert';
