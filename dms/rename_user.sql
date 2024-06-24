--
-- Name: rename_user(text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.rename_user(IN _oldusername text DEFAULT ''::text, IN _newusername text DEFAULT ''::text, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Rename a user in t_users and other tracking tables
**
**  Arguments:
**    _oldUserName      Username to change, e.g. 'D3L243'
**    _newUserName      New username
*     _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   10/31/2014 mem - Initial version
**  Date:   06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          02/19/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
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

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------

    _oldUserName := Trim(Coalesce(_oldUserName, ''));
    _newUserName := Trim(Coalesce(_newUserName, ''));
    _infoOnly    := Coalesce(_infoOnly, true);

    RAISE INFO '';

    If _oldUserName = '' Then
        _message := 'Old username must be specified; unable to continue';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _newUserName = '' Then
        _message := 'New username must be specified; unable to continue';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _oldUserName::citext = _newUserName::citext Then
        _message := 'Usernames are identical; nothing to do';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    --------------------------------------------
    -- Examine t_users
    --------------------------------------------

    If Not Exists (SELECT user_id FROM t_users WHERE username = _oldUserName::citext) Then
        _message := format('User %s does not exist in t_users; nothing to do', _oldUserName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Exists (SELECT user_id FROM t_users WHERE username = _newUserName::citext) Then
        _message := format('Cannot rename %s to %s because the new username already exists in t_users', _oldUserName, _newUserName);

        If Substring(_oldUserName::citext, 1, char_length(_newUserName)) = _newUserName::citext Then
            _message := format('%s. Will check for required renames in other tables', _message);
            RAISE INFO '%', _message;
        Else
            _message := format('%s. The new username is too different than the old username; aborting', _message);

            RAISE WARNING '%', _message;
            RETURN;
        End If;

    ElsIf _infoOnly Then

        RAISE INFO 'Preview user rename from % to %', _oldUserName, _newUserName;
        RAISE INFO '';

        _formatSpecifier := '%-8s %-10s %-35s %-11s %-10s %-40s %-20s';

        _infoHead := format(_formatSpecifier,
                            'User_ID',
                            'Username',
                            'Name',
                            'HID',
                            'Status',
                            'Email',
                            'Created'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------',
                                     '----------',
                                     '-----------------------------------',
                                     '-----------',
                                     '----------',
                                     '----------------------------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT User_ID,
                   Username,
                   Name,
                   HID,
                   Status,
                   Email,
                   public.timestamp_text(created) AS created
            FROM t_users
            WHERE username IN (_oldUserName::citext, _newUserName::citext)
            ORDER BY username
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.User_ID,
                                _previewData.Username,
                                _previewData.Name,
                                _previewData.HID,
                                _previewData.Status,
                                _previewData.Email,
                                _previewData.Created
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        RAISE INFO 'Renaming user % to %', _oldUserName, _newUserName;

        UPDATE t_users
        SET username = _newUserName
        WHERE username = _oldUserName::citext;
    End If;

    If _infoOnly Then

        --------------------------------------------
        -- Show the items owned by _oldUserName or _newUserName
        -- Only shows the newest 25 items of each entity type
        --------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-25s %-10s %-80s %-10s %-11s';

        _infoHead := format(_formatSpecifier,
                            'Entity',
                            'Entity_ID',
                            'Entity_Name',
                            'Username',
                            'Total_Items'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-------------------------',
                                     '----------',
                                     '--------------------------------------------------------------------------------',
                                     '----------',
                                     '-----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            WITH owned_entities (Entity, Entity_ID, Entity_Name, Role, Username, Sort, ItemRank) AS
            (SELECT 'Dataset' AS Entity,
                    Dataset_ID AS Entity_ID,
                    Dataset AS Entity_Name,
                    'Operator' AS Role,
                    operator_username AS Username,
                    1 AS Sort,
                    Row_Number() OVER (ORDER BY Dataset_ID DESC) AS ItemRank
             FROM t_dataset
             WHERE operator_username IN (_oldUserName::citext, _newUserName::citext)
             UNION
             SELECT 'Experiment' AS Entity,
                    Exp_ID AS Entity_ID,
                    Experiment AS Entity_Name,
                    'Researcher' AS Role,
                    researcher_username AS Username,
                    2 AS Sort,
                    Row_Number() OVER (ORDER BY Exp_ID DESC) AS ItemRank
             FROM t_experiments
             WHERE researcher_username IN (_oldUserName::citext, _newUserName::citext)
             UNION
             SELECT 'Requested Run' AS Entity,
                    Request_ID AS Entity_ID,
                    Request_Name AS Entity_Name,
                    'Requester' AS Role,
                    requester_username AS Username,
                    3 AS Sort,
                    Row_Number() OVER (ORDER BY Request_ID DESC) AS ItemRank
             FROM t_requested_run
             WHERE requester_username IN (_oldUserName::citext, _newUserName::citext)
             UNION
             SELECT 'Data Package Owner' AS Entity,
                    data_pkg_id AS Entity_ID,
                    package_name AS Entity_Name,
                    'Owner' AS Role,
                    owner_username AS Username,
                    4 AS Sort,
                    Row_Number() OVER (ORDER BY data_pkg_id DESC) AS ItemRank
             FROM dpkg.t_data_package
             WHERE owner_username IN (_oldUserName::citext, _newUserName::citext)
             UNION
             SELECT 'Data Package Requester' AS Entity,
                    data_pkg_id AS Entity_ID,
                    package_name AS Entity_Name,
                    'Requester' AS Role,
                    Requester AS Username,
                    5 AS Sort,
                    Row_Number() OVER (ORDER BY data_pkg_id DESC) AS ItemRank
             FROM dpkg.t_data_package
             WHERE requester IN (_oldUserName::citext, _newUserName::citext)
            )
            SELECT Src.Entity,
                   Src.Entity_ID,
                   Src.Entity_Name,
                   Src.Username,
                   StatsQ.Total_Items
            FROM owned_entities Src
                 INNER JOIN (SELECT Src.Entity,
                                    MAX(Src.ItemRank) AS Total_Items
                             FROM owned_entities Src
                             GROUP BY Src.Entity, Src.Username) StatsQ
                   ON Src.Entity = StatsQ.Entity
            WHERE Src.ItemRank <= 25
            ORDER BY Src.Sort, Src.Entity_Name
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Entity,
                                _previewData.Entity_ID,
                                _previewData.Entity_Name,
                                _previewData.Username,
                                _previewData.Total_Items
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        UPDATE t_dataset
        SET operator_username = _newUserName
        WHERE operator_username = _oldUserName::citext;

        UPDATE t_experiments
        SET researcher_username = _newUserName
        WHERE researcher_username = _oldUserName::citext;

        UPDATE t_requested_run
        SET requester_username = _newUserName
        WHERE requester_username = _oldUserName::citext;

        UPDATE dpkg.t_data_package
        SET owner_username = _newUserName
        WHERE owner_username = _oldUserName::citext;

        UPDATE dpkg.t_data_package
        SET Requester = _newUserName
        WHERE Requester = _oldUserName::citext;

        RAISE INFO 'User % has been renamed to %', _oldUserName, _newUserName;
    End If;

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;
END
$$;


ALTER PROCEDURE public.rename_user(IN _oldusername text, IN _newusername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE rename_user(IN _oldusername text, IN _newusername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.rename_user(IN _oldusername text, IN _newusername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'RenameUser';

