--
CREATE OR REPLACE PROCEDURE public.update_notification_user_registration
(
    _username text,
    _name text,
    _requestedRunBatch text,
    _analysisJobRequest text,
    _samplePrepRequest text,
    _datasetNotReleased text,
    _datasetReleased text,
    _mode text = 'update',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Sets user registration for notification entities
**
**      Used by web page https://dms2.pnl.gov/notification/edit/D3L243
**      See also https://prismwiki.pnl.gov/wiki/DMS_Event_Notification#Notification_Page_Family
**
**  Arguments:
**    _username             DMS user username
**    _name                 Person's name (unused)
**    _requestedRunBatch    'Yes' or 'No', indicating whether the user should be notified of requested runs in a batch starting or finishing (for batches owned by the user)
**    _analysisJobRequest   'Yes' or 'No', indicating whether the user should be notified of jobs in a job request starting or finishing (for job requests owned by the user)
**    _samplePrepRequest    'Yes' or 'No', indicating whether the user should be notified of any state changes to sample prep requests owned by the user
**    _datasetNotReleased   'Yes' or 'No', indicating whether the user should be notified of any datasets (owned by the user) that have their rating set to 'Not released'
**    _datasetReleased      'Yes' or 'No', indicating whether the user should be notified of any datasets (owned by the user) that have their rating set to 'Released'
**    _mode                 Unused, but typically 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Calling user username
**
**  Auth:   grk
**  Date:   04/03/2010
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          06/11/2012 mem - Renamed _dataset to _datasetNotReleased
**                         - Added _datasetReleased
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _userID int;
    _entityTypeID int;
    _notifyUser text;
    _usageMessage text;
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

    ---------------------------------------------------
    -- Lookup user
    ---------------------------------------------------

    SELECT user_id
    INTO _userID
    FROM t_users
    WHERE username = _username::citext;

    If Not FOUND Then
        _message := format('Username "%s" is not valid', _username);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate a temporary table with Entity Type IDs and Entity Type Params
    ---------------------------------------------------
    CREATE TEMP TABLE Tmp_NotificationOptions
        EntityTypeID int,
        NotifyUser text
    );

    INSERT INTO Tmp_NotificationOptions
    VALUES (1, _requestedRunBatch),
           (2, _analysisJobRequest),
           (3, _samplePrepRequest),
           (4, _datasetNotReleased),
           (5, _datasetReleased);

    ---------------------------------------------------
    -- Process each entry in _tblNotificationOptions
    ---------------------------------------------------

    FOR _entityTypeID, _notifyUser IN
        SELECT EntityTypeID, NotifyUser
        FROM Tmp_NotificationOptions
        ORDER BY EntityTypeID
    LOOP

        If _notifyUser::citext = 'Yes' Then
            If Not Exists ( SELECT *
                            FROM t_notification_entity_user
                            WHERE user_id = _userID AND entity_type_id = _entityTypeID ) Then

                INSERT INTO t_notification_entity_user( user_id, entity_type_id )
                VALUES(_userID, _entityTypeID);
            End If;

            CONTINUE;
        End If;

        If _notifyUser::citext = 'No' Then
            DELETE FROM t_notification_entity_user
            WHERE user_id = _userID AND entity_type_id = _entityTypeID;

            CONTINUE;
        End If;

        RAISE WARNING 'Unrecognized value for _notifyUser for Type ID %: %', _entityTypeID, _notifyUser;
    END LOOP;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('User %s', Coalesce(_username, 'NULL'));
    CALL post_usage_log_entry ('update_notification_user_registration', _usageMessage);

    DROP TABLE Tmp_NotificationOptions;
END
$$;

COMMENT ON PROCEDURE public.update_notification_user_registration IS 'UpdateNotificationUserRegistration';
