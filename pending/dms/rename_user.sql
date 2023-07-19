--
CREATE OR REPLACE PROCEDURE public.rename_user
(
    _oldUserName text = '',
    _newUserName text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Renames a user in T_Users and other tracking tables
**
**  Auth:   10/31/2014 mem - Initial version
**  Date:   06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          12/15/2023 mem - Ported to PostgreSQL
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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------

    _oldUserName := Coalesce(_oldUserName, '');
    _newUserName := Coalesce(_newUserName, '');

    If _oldUserName = '' Then
        _message := '_oldUserName is empty; unable to continue';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _newUserName = '' Then
        _message := '_newUserName is empty; unable to continue';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _oldUserName = _newUserName Then
        _message := 'Usernames are identical; nothing to do';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    --------------------------------------------
    -- Examine t_users
    --------------------------------------------

    If Not Exists (Select * From t_users Where username = _oldUserName) Then
        _message := format('User %s does not exist in t_users; nothing to do', _oldUserName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Exists (Select * From t_users Where username = _newUserName) Then
        _message := format('Cannot rename %s to %s because the new username already exists in t_users', _oldUserName, _newUserName);

        If Substring(_oldUserName, 1, char_length(_newUserName)) = _newUserName Then
            _message := format('%s. Will check for required renames in other tables', _message);
            RAISE INFO '%', _message;
        Else
            _message := format('%s. The new username is too different than the old username; aborting', _message);

            RAISE WARNING '%', _message;
            RETURN;
        End If;
    Else

        If _infoOnly Then

            -- ToDo: Update this to use RAISEINFO

            RAISE INFO '';
            RAISE INFO 'Preview user rename from % to %', _oldUserName, _newUserName;

            _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

            _infoHead := format(_formatSpecifier,
                                'abcdefg',
                                'abcdefg',
                                'abcdefg',
                                'abcdefg',
                                'abcdefg'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---',
                                         '---',
                                         '---',
                                         '---',
                                         '---'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT user_id,
                       username,
                       name,
                       hid,
                       status,
                       email,
                       public.timestamp_text(created) As created
                FROM t_users
                WHERE username IN (_oldUserName, _newUserName)
                ORDER BY username
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.user_id,
                                    _previewData.username,
                                    _previewData.name,
                                    _previewData.hid,
                                    _previewData.status,
                                    _previewData.email,
                                    _previewData.created
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        Else
            RAISE INFO 'Renaming % to %', _oldUserName, _newUserName;

            UPDATE t_users
            SET username = _newUserName
            WHERE username = _oldUserName;
        End If;

    End If;

    If _infoOnly Then

        --------------------------------------------
        -- Show the items owned by _oldUserName or _newUserName
        --------------------------------------------

        -- ToDo: Update these SELECT queries to use RAISE INFO


        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---',
                                     '---',
                                     '---',
                                     '---',
                                     '---'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            WITH owned_entities (Entity, Entity_ID, Entity_Name, Role, Username, Sort, ItemRank) AS
            (   SELECT 'Dataset' As Entity,
                       Dataset_ID As Entity_ID,
                       Dataset As Entity_Name,
                       'Operator' As Role,
                       operator_username As Username,
                       1 As Sort,
                       Row_Number() Over (Order By Dataset_ID Desc)
                FROM t_dataset
                WHERE operator_username IN (_oldUserName, _newUserName);
                UNION
                SELECT 'Experiment' As Entity,
                       Exp_ID As Entity_ID,
                       Experiment As Entity_Name,
                       'Researcher' As Role,
                       researcher_username As Username,
                       2 As Sort,
                       Row_Number() Over (Order By Exp_ID Desc)
                FROM t_experiments
                WHERE researcher_username IN (_oldUserName, _newUserName);
                UNION
                SELECT 'Requested Run' As Entity,
                       Request_ID As Entity_ID,
                       Request_Name As Entity_Name,
                       'Requester' As Role,
                       requester_username As Username,
                       3 As Sort,
                       Row_Number() Over (Order By Request_ID Desc)
                FROM t_requested_run
                WHERE requester_username IN (_oldUserName, _newUserName);
                UNION
                SELECT 'Data Package Owner' As Entity,
                       data_pkg_id As Entity_ID,
                       package_name As Entity_Name,
                       'Owner' As Role,
                       owner_username As Username,
                       4 As Sort,
                       Row_Number() Over (Order By data_pkg_id Desc)
                FROM dpkg.t_data_package
                WHERE owner_username IN (_oldUserName, _newUserName);
                UNION
                SELECT 'Data Package Requester' As Entity,
                       data_pkg_id As Entity_ID,
                       package_name As Entity_Name,
                       'Requester' As Role,
                       Requester As Username,
                       5 As Sort,
                       Row_Number() Over (Order By data_pkg_id Desc)
                FROM dpkg.t_data_package
                WHERE requester IN (_oldUserName, _newUserName);
            )
            SELECT Src.Entity,
                   Src.Entity_ID,
                   Src.Entity_Name,
                   Src.Username,
                   StatsQ.Total_Items
            FROM owned_entities Src
                 INNER JOIN ( SELECT Src.Entity,
                                     Max(Src.ItemRank) AS TotalItems
                              FROM owned_entities Src
                              GROUP BY Src.Entity, Src.Username ) StatsQ
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
        WHERE operator_username = _oldUserName;

        UPDATE t_experiments
        SET researcher_username = _newUserName
        WHERE researcher_username = _oldUserName;

        UPDATE t_requested_run
        SET requester_username = _newUserName
        WHERE requester_username = _oldUserName;

        UPDATE dpkg.t_data_package
        SET Owner = _newUserName
        WHERE Owner = _oldUserName;

        UPDATE dpkg.t_data_package
        SET Requester = _newUserName
        WHERE Requester = _oldUserName;

    End If;

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.rename_user IS 'RenameUser';
