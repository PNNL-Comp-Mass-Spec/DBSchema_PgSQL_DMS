--
CREATE OR REPLACE PROCEDURE sw.update_cached_manager_work_dirs
(
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
    _myRowCount int := 0;
    _message text;
    _callingProcName text;
    _currentLocation text;
BEGIN

    _infoOnly := Coalesce(_infoOnly, false);

    _currentLocation := 'Start';

    ---------------------------------------------------
    -- Create a temporary table to cache the data
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_MgrWorkDirs (
        ID             int NOT NULL,
        Processor_Name text NOT NULL,
        MgrWorkDir     text NULL
    )

    CREATE INDEX IX_Tmp_MgrWorkDirs ON Tmp_MgrWorkDirs (ID);

    Begin Try

        ---------------------------------------------------
        -- Populate a temporary table with the new information
        -- Dates in mc.V_Mgr_Work_Dir will be of the form
        -- \\ServerName\C$\DMS_WorkDir1
        ---------------------------------------------------
        --
        INSERT INTO Tmp_MgrWorkDirs (processor_id, processor_name, MgrWorkDir)
        SELECT processor_id,
               processor_name,
               Replace(MgrWorkDirs.work_dir_admin_share, '\\ServerName\', '\\' || machine || '\') AS MgrWorkDir
        FROM mc.V_Mgr_Work_Dir MgrWorkDirs
             INNER JOIN sw.t_local_processors LP
               ON MgrWorkDirs.Mgr_Name = LP.processor_name
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _infoOnly Then
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
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount > 0 Then
                _message := format('Updated work_dir_admin_share for %s %s in sw.t_local_processors',
                                    _myRowCount, public.check_plural(_myRowCount, ' manager', ' managers'));

                Call public.post_log_entry ('Normal', _message, 'UpdateCachedManagerWorkDirs');
            End If;

        End If;

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        _callingProcName := Coalesce(ERROR_PROCEDURE(), 'UpdateCachedManagerWorkDirs');
        Call local_error_handler  _callingProcName, _currentLocation, _logError => 1,
                                _errorNum = _myError output, _message = _message => _message

    End Catch

    DROP TABLE Tmp_MgrWorkDirs;
END
$$;

COMMENT ON PROCEDURE sw.update_cached_manager_work_dirs IS 'UpdateCachedManagerWorkDirs';
