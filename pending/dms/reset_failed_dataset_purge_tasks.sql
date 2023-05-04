--
CREATE OR REPLACE PROCEDURE public.reset_failed_dataset_purge_tasks
(
    _resetHoldoffHours real = 2,
    _maxTasksToReset int = 0,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _resetCount int = 0 output
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for dataset archive entries with state 8=Purge Failed
**      Examines the archive_state_last_affected column and
**        resets any entries that entered the Purge Failed state
**        at least _resetHoldoffHours hours before the present
**
**  Arguments:
**    _resetHoldoffHours   Holdoff time to apply to column AS_state_Last_Affected
**    _maxTasksToReset     If greater than 0, will limit the number of tasks to reset
**    _infoOnly            True to preview the tasks that would be reset
**    _message             Status message
**    _resetCount          Number of tasks reset
**
**  Auth:   mem
**  Date:   07/12/2010 mem - Initial version
**          12/13/2010 mem - Changed _resetHoldoffHours from tinyint to real
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _resetHoldoffHours := Coalesce(_resetHoldoffHours, 2);
    _maxTasksToReset := Coalesce(_maxTasksToReset, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    _resetCount := 0;

    If _maxTasksToReset <= 0 Then
        _maxTasksToReset := 1000000;
    End If;

    BEGIN

        If _infoOnly Then
            ------------------------------------------------
            -- Preview all datasets with an Archive State of 8=Purge Failed
            ------------------------------------------------

            -- ToDo: Show the results using RAISE INFO

            SELECT SPath.vol_name_client AS Server,
                   SPath.instrument AS Instrument,
                   DS.dataset AS Dataset,
                   DA.dataset_id AS Dataset_ID,
                   DA.archive_state_id AS State,
                   DA.archive_state_last_affected AS Last_Affected
            FROM t_dataset_archive DA
                 INNER JOIN t_dataset DS
                   ON DA.dataset_id = DS.dataset_id
                 INNER JOIN t_storage_path SPath
                   ON DS.storage_path_id = SPath.storage_path_id
            WHERE DA.archive_state_id = 8 AND
                  DA.archive_state_last_affected < CURRENT_TIMESTAMP - make_interval(hours => _resetHoldoffHours)
            ORDER BY SPath.vol_name_client, SPath.instrument, DS.dataset

        Else
            ------------------------------------------------
            -- Reset up to _maxTasksToReset archive tasks
            -- that currently have an archive state of 8
            ------------------------------------------------

            UPDATE t_dataset_archive
            SET archive_state_id = 3
            FROM ( SELECT DA.dataset_id
                   FROM t_dataset_archive DA
                   WHERE DA.archive_state_id = 8 AND
                         extract(epoch FROM CURRENT_TIMESTAMP - DA.archive_state_Last_Affected) / 60.0 >= _resetHoldoffHours * 60
                   LIMIT _maxTasksToReset
                 ) LookupQ
            WHERE t_dataset_archive.dataset_id = LookupQ.dataset_id;
            --
            GET DIAGNOSTICS _resetCount = ROW_COUNT;

            If _resetCount > 0 Then
                _message := format('Reset dataset archive state from "Purge Failed" to "Complete" for %s datasets', _myRowCount);
            Else
                _message := 'No candidate tasks were found to reset';
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

END
$$;

COMMENT ON PROCEDURE public.reset_failed_dataset_purge_tasks IS 'ResetFailedDatasetPurgeTasks';
