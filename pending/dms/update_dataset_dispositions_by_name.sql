--
CREATE OR REPLACE PROCEDURE public.update_dataset_dispositions_by_name
(
    _datasetList text,
    _rating text = '',
    _comment text = '',
    _recycleRequest text = '',
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
**      Updates datasets in list according to disposition parameters
**      Accepts list of dataset names
**
**  Arguments:
**    _recycleRequest   yes/no
**
**  Auth:   grk
**  Date:   10/15/2008 grk - Initial release (Ticket #582)
**          08/19/2010 grk - Use try-catch for error handling
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          02/20/2013 mem - Expanded _message to varchar(1024)
**          02/21/2013 mem - Now requiring _recycleRequest to be yes or no
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/03/2018 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetCount int := 0;
    _logErrors boolean := false;
    _datasetIDList text := '';
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
        -- Validate input parameters
        ---------------------------------------------------

        _rating := Coalesce(_rating, '');
        _recycleRequest := Trim(Lower(Coalesce(_recycleRequest, '')));
        _comment := Coalesce(_comment, '');

        If Not _recycleRequest::citext IN ('yes', 'no') Then
            _message := format('RecycleRequest must be Yes or No (currently "%s")', _recycleRequest);
            RAISE EXCEPTION '%', _message;
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Temp table  for holding dataset names and IDs
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetsToUpdate
            DatasetID text,
            DatasetName text
        )

        --------------------------------------------------
        -- Add datasets from input list to table
        ---------------------------------------------------

        INSERT INTO Tmp_DatasetsToUpdate( DatasetName )
        SELECT Item
        FROM public.parse_delimited_list ( _datasetList )

        ---------------------------------------------------
        -- Look up dataset IDs for datasets
        ---------------------------------------------------

        UPDATE Tmp_DatasetsToUpdate
        SET DatasetID = D.Dataset_ID::text
        FROM t_dataset D
        WHERE D.dataset = DatasetName;

        ---------------------------------------------------
        -- Any datasets not found?
        ---------------------------------------------------

        SELECT string_agg(DatasetName, ', ' ORDER BY DatasetName)
        INTO _datasetIDList
        FROM Tmp_DatasetsToUpdate
        WHERE DatasetID IS NULL;

        If Coalesce(_datasetIDList, '') <> '' Then
            _message := format('Datasets not found: %s', _datasetIDList);
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Make list of dataset IDs
        ---------------------------------------------------

        SELECT string_agg(DatasetID::text, ', ' ORDER BY DatasetID);
        INTO _datasetIDList
        FROM Tmp_DatasetsToUpdate;

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DatasetsToUpdate;

        _logErrors := true;

        ---------------------------------------------------
        -- Call sproc to update dataset disposition
        ---------------------------------------------------

        CALL update_dataset_dispositions (
                            _datasetIDList,
                            _rating,
                            _comment,
                            _recycleRequest,
                            _mode,
                            _message => _message,           -- Output
                            _returnCode => _returnCode,     -- Output
                            _callingUser);

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

    _usageMessage := format('%s %s updated', _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets');
    CALL post_usage_log_entry ('update_dataset_dispositions_by_name', _usageMessage);

    DROP TABLE IF EXISTS Tmp_DatasetsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.update_dataset_dispositions_by_name IS 'UpdateDatasetDispositionsByName';
