--
-- Name: reset_auto_purged_datasets_with_msxml_results(boolean, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.reset_auto_purged_datasets_with_msxml_results(IN _infoonly boolean DEFAULT false, INOUT _resetcount integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for datasets with archive state 14 that have potentially unpurged MSXML jobs
**      State 14 is 'Purged Instrument Data (plus auto-purge)'
**
**      Change the dataset archive state back to 3=Complete to give the space manager a chance to purge the .mzML or .mzXML file
**
**      This procedure is no longer needed because we use _CacheInfo.txt placeholder files
**
**  Arguments:
**    _infoOnly     When true, preview the datasets that would be reset
**    _resetCount   Number of datasets that were reset
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   01/13/2014 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/20/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetIDs text;
    _datasetNames text;
    _datasetCount int;

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

    _infoOnly := Coalesce(_infoOnly, false);

    _resetCount := 0;

    CREATE TEMP TABLE Tmp_Datasets (
        Dataset_ID int NOT NULL
    );

    BEGIN
        ------------------------------------------------
        -- Find datasets to update
        ------------------------------------------------

        INSERT INTO Tmp_Datasets (dataset_id)
        SELECT DISTINCT DS.dataset_id
        FROM t_dataset DS
             INNER JOIN t_dataset_archive DA
               ON DS.dataset_id = DA.dataset_id
             INNER JOIN t_analysis_job J
               ON DS.dataset_id = J.dataset_id
             INNER JOIN t_analysis_tool AnTool
               ON J.analysis_tool_id = AnTool.analysis_tool_id
        WHERE DA.archive_state_id = 14 AND
              AnTool.analysis_tool LIKE 'MSXML%' AND
              DA.archive_state_last_affected < CURRENT_TIMESTAMP - INTERVAL '180 days' AND
              J.purged = 0;

        If Not FOUND Then
            _message := 'No candidate datasets were found to reset';

            If _infoOnly Then
                RAISE INFO '%', _message;
            End If;

            DROP TABLE Tmp_Datasets;
            RETURN;
        End If;

        If _infoOnly Then
            ------------------------------------------------
            -- Show the dataset IDs and dataset names that would be reset
            ------------------------------------------------

            SELECT string_agg(DS.dataset_id::text, ', ' ORDER BY DS.dataset_id),
                   string_agg(DS.dataset,          ', ' ORDER BY DS.dataset_id)
            INTO _datasetIDs, _datasetNames
            FROM t_dataset DS
                 INNER JOIN Tmp_Datasets U
                   ON DS.dataset_id = U.dataset_id
                 INNER JOIN t_dataset_archive DA
                   ON DS.dataset_id = DA.dataset_id
                 INNER JOIN t_dataset_archive_state_name DASN
                   ON DA.archive_state_id = DASN.archive_state_id;

            _datasetCount := array_length(string_to_array(_datasetIDs, ','), 1);

            _message := format('Would reset %s %s', _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets'));

            RAISE INFO '';
            RAISE INFO '%', _message;

            RAISE INFO '';
            CALL public.show_delimited_text_wrapped (
                            _delimitedList => format('ID(s):    %s', _datasetIDs),
                            _delimiter     => ',',
                            _maxLineLength => 128,
                            _indentSize    => 10
            );

            RAISE INFO '';
            CALL public.show_delimited_text_wrapped (
                            _delimitedList => format('Names(s): %s', _datasetNames),
                            _delimiter     => ',',
                            _maxLineLength => 512,
                            _indentSize    => 10
            );

            DROP TABLE Tmp_Datasets;
            RETURN;
        End If;

        ------------------------------------------------
        -- Change the dataset archive state back to 3
        ------------------------------------------------

        UPDATE t_dataset_archive DA
        SET archive_state_id = 3
        FROM Tmp_Datasets U
        WHERE DA.dataset_id = U.Dataset_ID;
        --
        GET DIAGNOSTICS _resetCount = ROW_COUNT;

        If _resetCount > 0 Then
            _message := format('Reset dataset archive state from "Purged Instrument Data (plus auto-purge)" to "Complete" for %s dataset(s)', _resetCount);
        Else
            _message := 'No candidate datasets were found to reset';
        End If;

        If _resetCount > 0 Then
            CALL post_log_entry ('Normal', _message, 'Reset_Auto_Purged_Datasets_With_MSXML_Results');
        End If;

        DROP TABLE Tmp_Datasets;
        RETURN;

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

    DROP TABLE IF EXISTS Tmp_Datasets;
END
$$;


ALTER PROCEDURE public.reset_auto_purged_datasets_with_msxml_results(IN _infoonly boolean, INOUT _resetcount integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE reset_auto_purged_datasets_with_msxml_results(IN _infoonly boolean, INOUT _resetcount integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.reset_auto_purged_datasets_with_msxml_results(IN _infoonly boolean, INOUT _resetcount integer, INOUT _message text, INOUT _returncode text) IS 'ResetAutoPurgedDatasetsWithMSXmlResults';

