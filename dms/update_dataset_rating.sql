--
-- Name: update_dataset_rating(text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_rating(IN _datasets text, IN _rating text DEFAULT 'Unknown'::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the rating for the given datasets by calling procedure update_datasets()
**
**  Arguments:
**    _datasets     Comma-separated list of dataset names
**    _rating       Typically 'Released' or 'Not Released'
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   mem
**  Date:   10/07/2015 mem - Initial version
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/01/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _ratingID int;
    _datasetCount int := 0;
    _mode text;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasets := Trim(Coalesce(_datasets, ''));
    _rating   := Trim(Coalesce(_rating, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Resolve id for rating
    ---------------------------------------------------

    _ratingID := public.get_dataset_rating_id(_rating);

    If _ratingID = 0 Then
        _message := format('Invalid dataset rating: %s', _rating);
        RAISE INFO '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    SELECT COUNT (DISTINCT Value)
    INTO _datasetCount
    FROM public.parse_delimited_list(_datasets);

    If _datasetCount = 0 Then
        _message := 'Dataset list cannot be empty';
        RAISE INFO '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Determine the mode based on _infoOnly
    ---------------------------------------------------

    If _infoOnly Then
        _mode := 'preview';
    Else
        _mode := 'update';
    End If;

    ---------------------------------------------------
    -- Call procedure update_datasets
    ---------------------------------------------------

    CALL public.update_datasets (
        _datasetList => _datasets,
        _state       => '',
        _rating      => _rating,
        _comment     => '',
        _findText    => '',
        _replaceText => '',
        _mode        => _mode,
        _message     => _message,       -- Output
        _returnCode  => _returnCode,    -- Output
        _callingUser => _callingUser);

    If _returnCode = '' And Not _infoOnly Then
        If _datasetCount = 1 Then
            _message := format('Changed the rating to "%s" for dataset %s', _rating, _datasets);
            RAISE INFO '%', _message;
        Else
            _message := format('Changed the rating to "%s" for %s datasets', _rating, _datasetCount);
            RAISE INFO '%: %', _message, _datasets;
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.update_dataset_rating(IN _datasets text, IN _rating text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_dataset_rating(IN _datasets text, IN _rating text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_dataset_rating(IN _datasets text, IN _rating text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateDatasetRating';

