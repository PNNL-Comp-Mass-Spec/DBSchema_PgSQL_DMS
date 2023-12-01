--
-- Name: update_cached_manager_work_dirs(boolean, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_cached_manager_work_dirs(IN _infoonly boolean DEFAULT false, IN _showall boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Updates the cached working directory for each manager
**
**  Arguments:
**    _infoOnly     When true, show the managers that would be updated
**    _showAll      When true, show the working directory for all managers
**
**  Auth:   mem
**  Date:   10/05/2016 mem - Initial release
**          02/17/2020 mem - Update the Mgr_Name column in mc.V_Mgr_Work_Dir
**          08/13/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _callingProcName text;
    _currentLocation text := 'Start';

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _showAll  := Coalesce(_showAll, false);

    ---------------------------------------------------
    -- Create a temporary table to cache the data
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_MgrWorkDirs (
        processor_id         int NOT NULL,
        processor_name       text NOT NULL,
        work_dir_admin_share text NULL
    );

    CREATE INDEX IX_Tmp_MgrWorkDirs ON Tmp_MgrWorkDirs (processor_id);

    BEGIN

        ---------------------------------------------------
        -- Populate a temporary table with the new information
        -- Paths in mc.V_Mgr_Work_Dir will be of the form
        -- \\ServerName\C$\DMS_WorkDir1
        ---------------------------------------------------

        INSERT INTO Tmp_MgrWorkDirs (processor_id, processor_name, work_dir_admin_share)
        SELECT processor_id,
               processor_name,
               Replace(MgrWorkDirs.work_dir_admin_share, '\\\\ServerName\\', format('\\\\%s\\', machine)) AS work_dir_admin_share
        FROM mc.V_Mgr_Work_Dir MgrWorkDirs
             INNER JOIN sw.t_local_processors LP
               ON MgrWorkDirs.Mgr_Name = LP.processor_name;

        If _infoOnly Then

            RAISE INFO '';

            _formatSpecifier := '%-12s %-20s %-30s %-30s %-15s';

            _infoHead := format(_formatSpecifier,
                                'Processor_ID',
                                'Processor_Name',
                                'Work_Dir_Admin_Share',
                                'Work_Dir_Admin_Share_New',
                                'Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '------------',
                                         '--------------------',
                                         '------------------------------',
                                         '------------------------------',
                                         '---------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Target.Processor_ID,
                       Target.Processor_Name,
                       Target.Work_Dir_Admin_Share,
                       Src.Work_Dir_Admin_Share AS Work_Dir_Admin_Share_New,
                       CASE WHEN Target.work_dir_admin_share IS DISTINCT FROM Src.work_dir_admin_share
                            THEN 'Update required'
                            ELSE ''
                       END AS Comment
                FROM sw.t_local_processors Target
                     INNER JOIN Tmp_MgrWorkDirs Src
                       ON Src.processor_name = Target.processor_name
                WHERE _showAll OR
                       Target.work_dir_admin_share IS DISTINCT FROM Src.work_dir_admin_share
                ORDER BY Processor_Name
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Processor_ID,
                                    _previewData.Processor_Name,
                                    _previewData.Work_Dir_Admin_Share,
                                    _previewData.Work_Dir_Admin_Share_New,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_MgrWorkDirs;
            RETURN;
        End If;

        UPDATE sw.t_local_processors Target
        SET work_dir_admin_share = Src.work_dir_admin_share
        FROM Tmp_MgrWorkDirs Src
        WHERE Src.processor_name = Target.processor_name AND
              Target.work_dir_admin_share IS DISTINCT FROM Src.work_dir_admin_share;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Updated work_dir_admin_share for %s %s in sw.t_local_processors',
                                _updateCount, public.check_plural(_updateCount, 'manager', 'managers'));

            CALL public.post_log_entry ('Normal', _message, 'Update_Cached_Manager_Work_Dirs', 'sw');
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE Tmp_MgrWorkDirs;
END
$_$;


ALTER PROCEDURE sw.update_cached_manager_work_dirs(IN _infoonly boolean, IN _showall boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_manager_work_dirs(IN _infoonly boolean, IN _showall boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_cached_manager_work_dirs(IN _infoonly boolean, IN _showall boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedManagerWorkDirs';

