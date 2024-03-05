--
-- Name: reset_failed_dataset_purge_tasks(integer, integer, boolean, text, text, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.reset_failed_dataset_purge_tasks(IN _resetholdoffhours integer DEFAULT 2, IN _maxtaskstoreset integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, INOUT _resetcount integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for dataset archive entries with state 8=Purge Failed
**
**      Examine the archive_state_last_affected column and reset any entries that entered the Purge Failed state
**      at least _resetHoldoffHours hours before the present
**
**  Arguments:
**    _resetHoldoffHours    Holdoff time to apply to column AS_state_Last_Affected
**    _maxTasksToReset      If greater than 0, will limit the number of tasks to reset
**    _infoOnly             When true, preview the tasks that would be reset
**    _message              Status message
**    _returnCode           Return code
**    _resetCount           Output: Number of tasks reset
**
**  Auth:   mem
**  Date:   07/12/2010 mem - Initial version
**          12/13/2010 mem - Changed _resetHoldoffHours from tinyint to real
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/21/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _resetHoldoffHours := Coalesce(_resetHoldoffHours, 2);
    _maxTasksToReset   := Coalesce(_maxTasksToReset, 0);
    _infoOnly          := Coalesce(_infoOnly, false);

    _resetCount := 0;

    If _maxTasksToReset <= 0 Then
        _maxTasksToReset := 1000000;
    End If;

    BEGIN

        If _infoOnly Then
            ------------------------------------------------
            -- Preview all datasets with an archive state of 8=Purge Failed
            ------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-20s %-25s %-80s %-10s %-5s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Server',
                                'Instrument',
                                'Dataset',
                                'Dataset_ID',
                                'State',
                                'Last_Affected'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------',
                                         '-------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '----------',
                                         '-----',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT SPath.vol_name_client AS Server,
                       SPath.Instrument,
                       DS.Dataset,
                       DA.Dataset_ID,
                       DA.archive_state_id AS State,
                       public.timestamp_text(DA.archive_state_last_affected) AS Last_Affected
                FROM t_dataset_archive DA
                     INNER JOIN t_dataset DS
                       ON DA.dataset_id = DS.dataset_id
                     INNER JOIN t_storage_path SPath
                       ON DS.storage_path_id = SPath.storage_path_id
                WHERE DA.archive_state_id = 8 AND
                      DA.archive_state_last_affected < CURRENT_TIMESTAMP - make_interval(hours => _resetHoldoffHours)
                ORDER BY SPath.vol_name_client, SPath.instrument, DS.dataset
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Server,
                                    _previewData.Instrument,
                                    _previewData.Dataset,
                                    _previewData.Dataset_ID,
                                    _previewData.State,
                                    _previewData.Last_Affected
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            RETURN;
        End If;

        ------------------------------------------------
        -- Reset up to _maxTasksToReset archive tasks
        -- that currently have an archive state of 8
        ------------------------------------------------

        UPDATE t_dataset_archive target
        SET archive_state_id = 3
        WHERE dataset_id IN ( SELECT DA.dataset_id
                              FROM t_dataset_archive DA
                              WHERE DA.archive_state_id = 8 AND
                                    Extract(epoch from CURRENT_TIMESTAMP - DA.archive_state_Last_Affected) / 60 >= _resetHoldoffHours * 60
                              LIMIT _maxTasksToReset
                            );
        --
        GET DIAGNOSTICS _resetCount = ROW_COUNT;

        If _resetCount > 0 Then
            _message := format('Reset dataset archive state from "Purge Failed" to "Complete" for %s %s', _resetCount, public.check_plural(_resetCount, 'dataset', 'datasets'));
        Else
            _message := 'No candidate tasks were found to reset';
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


ALTER PROCEDURE public.reset_failed_dataset_purge_tasks(IN _resetholdoffhours integer, IN _maxtaskstoreset integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, INOUT _resetcount integer) OWNER TO d3l243;

--
-- Name: PROCEDURE reset_failed_dataset_purge_tasks(IN _resetholdoffhours integer, IN _maxtaskstoreset integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, INOUT _resetcount integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.reset_failed_dataset_purge_tasks(IN _resetholdoffhours integer, IN _maxtaskstoreset integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, INOUT _resetcount integer) IS 'ResetFailedDatasetPurgeTasks';

