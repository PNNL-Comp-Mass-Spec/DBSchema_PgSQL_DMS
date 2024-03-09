--
-- Name: update_dataset_dispositions_by_name(text, text, text, text, text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_dispositions_by_name(IN _datasetlist text, IN _rating text DEFAULT ''::text, IN _comment text DEFAULT ''::text, IN _recyclerequest text DEFAULT ''::text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update datasets in list according to disposition parameters
**
**  Arguments:
**    _datasetList      Comma-separated list of dataset names
**    _rating           New dataset rating, e.g. 'Released' or 'No Interest'
**    _comment          Text to append to the dataset comment
**    _recycleRequest   If 'yes', update_dataset_dispositions() will call unconsume_scheduled_run() to recycle the request; otherwise, must be 'No'
**    _mode             Mode: if 'update', update_dataset_dispositions() will update t_dataset and possibly call unconsume_scheduled_run() and schedule_predefined_analysis_jobs()
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**    _showDebug        When true, show debug messages
**
**  Auth:   grk
**  Date:   10/15/2008 grk - Initial version (Ticket #582)
**          08/19/2010 grk - Use try-catch for error handling
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          02/20/2013 mem - Expanded _message to varchar(1024)
**          02/21/2013 mem - Now requiring _recycleRequest to be yes or no
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/03/2018 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          02/29/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetCount int := 0;
    _logErrors boolean := false;
    _invalidDatasets text;
    _datasetIDList text;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _datasetList    := Trim(Coalesce(_datasetList, ''));
        _rating         := Trim(Coalesce(_rating, ''));
        _comment        := Trim(Coalesce(_comment, ''));
        _recycleRequest := Trim(Lower(Coalesce(_recycleRequest, '')));
        _mode           := Trim(Lower(Coalesce(_mode, '')));
        _showDebug      := Coalesce(_showDebug, false);

        If Not _recycleRequest::citext In ('yes', 'no') Then
            _message := format('RecycleRequest must be Yes or No (currently "%s")', _recycleRequest);
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Temp table for holding dataset names and IDs
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetsToUpdate (
            DatasetID int,
            DatasetName citext
        );

        --------------------------------------------------
        -- Add datasets from input list to table
        ---------------------------------------------------

        INSERT INTO Tmp_DatasetsToUpdate (DatasetName)
        SELECT Value
        FROM public.parse_delimited_list(_datasetList);

        ---------------------------------------------------
        -- Resolve dataset name to ID
        ---------------------------------------------------

        UPDATE Tmp_DatasetsToUpdate
        SET DatasetID = DS.Dataset_ID
        FROM t_dataset DS
        WHERE DS.dataset = DatasetName;

        ---------------------------------------------------
        -- Any datasets not found?
        ---------------------------------------------------

        SELECT string_agg(DatasetName, ', ' ORDER BY DatasetName)
        INTO _invalidDatasets
        FROM Tmp_DatasetsToUpdate
        WHERE DatasetID IS NULL;

        If Coalesce(_invalidDatasets, '') <> '' Then
            If Position(',' In _invalidDatasets) > 0 Then
                _message := format('Unrecognized datasets: %s', _invalidDatasets);
            Else
                _message := format('Unrecognized dataset: %s', _invalidDatasets);
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Make list of dataset IDs
        ---------------------------------------------------

        SELECT string_agg(DatasetID::text, ', ' ORDER BY DatasetID)
        INTO _datasetIDList
        FROM Tmp_DatasetsToUpdate;

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DatasetsToUpdate;

        _logErrors := true;

        ---------------------------------------------------
        -- Call sproc to update dataset disposition
        ---------------------------------------------------

        CALL public.update_dataset_dispositions (
                        _datasetIDList  => _datasetIDList,
                        _rating         => _rating,
                        _comment        => _comment,
                        _recycleRequest => _recycleRequest,
                        _mode           => _mode,
                        _message        => _message,            -- Output
                        _returnCode     => _returnCode,         -- Output
                        _callingUser    => _callingUser,
                        _showDebug      => _showDebug);

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets'));
    CALL post_usage_log_entry ('update_dataset_dispositions_by_name', _usageMessage);

    DROP TABLE IF EXISTS Tmp_DatasetsToUpdate;
END
$$;


ALTER PROCEDURE public.update_dataset_dispositions_by_name(IN _datasetlist text, IN _rating text, IN _comment text, IN _recyclerequest text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_dataset_dispositions_by_name(IN _datasetlist text, IN _rating text, IN _comment text, IN _recyclerequest text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_dataset_dispositions_by_name(IN _datasetlist text, IN _rating text, IN _comment text, IN _recyclerequest text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean) IS 'UpdateDatasetDispositionsByName';

