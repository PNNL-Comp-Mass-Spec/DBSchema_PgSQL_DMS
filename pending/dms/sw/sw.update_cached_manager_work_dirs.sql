--
CREATE OR REPLACE PROCEDURE sw.update_cached_manager_work_dirs
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update the cached working directory for each manager
**
**  Auth:   mem
**  Date:   10/05/2016 mem - Initial release
**          02/17/2020 mem - Update the Mgr_Name column in mc.V_Mgr_Work_Dir
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create a temporary table to cache the data
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_MgrWorkDirs (
        ID             int NOT NULL,
        Processor_Name text NOT NULL,
        MgrWorkDir     text NULL
    );

    CREATE INDEX IX_Tmp_MgrWorkDirs ON Tmp_MgrWorkDirs (ID);

    BEGIN

        ---------------------------------------------------
        -- Populate a temporary table with the new information
        -- Dates in mc.V_Mgr_Work_Dir will be of the form
        -- \\ServerName\C$\DMS_WorkDir1
        ---------------------------------------------------
        --
        INSERT INTO Tmp_MgrWorkDirs (processor_id, processor_name, MgrWorkDir)
        SELECT processor_id,
               processor_name,
               Replace(MgrWorkDirs.work_dir_admin_share, '\\ServerName\', format('\\%s\', machine)) AS MgrWorkDir
        FROM mc.V_Mgr_Work_Dir MgrWorkDirs
             INNER JOIN sw.t_local_processors LP
               ON MgrWorkDirs.Mgr_Name = LP.processor_name;

        If _infoOnly Then

            -- ToDo: Update this to use RAISE INFO

            SELECT Target.*, Src.MgrWorkDir AS MgrWorkDir_New
            FROM Tmp_MgrWorkDirs Src
                 INNER JOIN sw.t_local_processors Target
                   ON Src.processor_name = Target.processor_name
            WHERE Target.work_dir_admin_share <> Src.MgrWorkDir OR
                  Target.work_dir_admin_share IS NULL AND NOT Src.MgrWorkDir IS NULL

        Else
            UPDATE sw.t_local_processors
            SET work_dir_admin_share = Src.MgrWorkDir
            FROM Tmp_MgrWorkDirs Src
                 INNER JOIN sw.t_local_processors Target
                   ON Src.processor_name = Target.processor_name
            WHERE Target.work_dir_admin_share <> Src.MgrWorkDir OR
                  Target.work_dir_admin_share IS NULL AND NOT Src.MgrWorkDir IS NULL
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _updateCount > 0 Then
                _message := format('Updated work_dir_admin_share for %s %s in sw.t_local_processors',
                                    _updateCount, public.check_plural(_updateCount, 'manager', 'managers'));

                CALL public.post_log_entry ('Normal', _message, 'Update_Cached_Manager_Work_Dirs', 'sw');
            End If;

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
$$;

COMMENT ON PROCEDURE sw.update_cached_manager_work_dirs IS 'UpdateCachedManagerWorkDirs';
