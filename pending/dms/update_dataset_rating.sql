--
CREATE OR REPLACE PROCEDURE public.update_dataset_rating
(
    _datasets text,
    _rating text = 'Unknown',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the rating for the given datasets by calling SP UpdateDatasets
**
**  Arguments:
**    _datasets   Comma-separated list of datasets
**    _rating     Typically 'Released' or 'Not Released'
**
**  Auth:   mem
**  Date:   10/07/2015 mem - Initial release
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _ratingID int;
    _datasetCount int := 0;
    _mode text := 'update';
BEGIN
    _message := '';
    _returnCode := '';

    _rating := Coalesce(_rating, '');
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Resolve id for rating
    ---------------------------------------------------

    _ratingID := get_dataset_rating_id (_rating);

    If _ratingID = 0 Then
        _message := format('Could not find entry in database for rating "%s"', _rating);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    SELECT COUNT (DISTINCT Value)
    INTO _datasetCount
    FROM public.parse_delimited_list(_datasets, ',')

    If _datasetCount = 0 Then
        _message := '_datasets cannot be empty';
        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Determine the mode based on _infoOnly
    ---------------------------------------------------

    If _infoOnly Then
        _mode := 'preview';
    End If;

    ---------------------------------------------------
    -- Call procedure UpdateDatasets
    ---------------------------------------------------

    CALL update_datasets (
        _datasets,
        _rating => _rating,
        _mode => _mode,
        _message => _message,
        _returnCode => _returnCode,
        _callingUser => _callingUser);

    If _returnCode = '' And Not _infoOnly Then
        If _datasetCount = 1 Then
            _message := format('Changed the rating to "%s" for dataset %s', _rating _datasets);
            RAISE INFO '%', _message;
        Else
            _message := format('Changed the rating to "%s" for %s datasets', _rating, _datasetCount);
            RAISE INFO '%: %', _message, _datasets;
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_dataset_rating IS 'UpdateDatasetRating';
