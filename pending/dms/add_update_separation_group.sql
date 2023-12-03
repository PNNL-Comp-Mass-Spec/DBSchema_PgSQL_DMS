--
CREATE OR REPLACE PROCEDURE public.add_update_separation_group
(
    _separationGroup text,
    _comment text,
    _active int,
    _samplePrepVisible int,
    _fractionCount int,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits an existing separation group
**
**  Arguments:
**    _separationGroup      Separation group name
**    _comment              Group comment
**    _active               Active: 1 means active, 0 means inactive
**    _samplePrepVisible    When 1, include in the DMS website chooser used when editing a sample prep request
**    _fractionCount        For separation groups used when fractionating samples, the number of fractions to be generated, e.g. 'LC-MicroHpH-12' has a fraction count of 12
**    _mode                 Mode: 'add' or 'update'
**    _message              Output message
**    _returnCode           Return code
**    _callingUser          Calling user username
**
**  Auth:   mem
**  Date:   06/12/2017 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/15/2021 mem - Add _fractionCount
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetTypeID int;

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

        _comment           := Trim(Coalesce(_comment, ''));
        _active            := Coalesce(_active, 0);
        _samplePrepVisible := Coalesce(_samplePrepVisible, 0);
        _fractionCount     := Coalesce(_fractionCount, 0);
        _mode              := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            If Not Exists (SELECT separation_group FROM t_separation_group WHERE separation_group = _separationGroup) Then
                RAISE EXCEPTION 'No entry could be found in database for update';
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_separation_group( separation_group,
                                            comment,
                                            active,
                                            sample_prep_visible,
                                            fraction_count)
            VALUES (_separationGroup, _comment, _active, _samplePrepVisible, _fractionCount)

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_separation_group
            SET comment = _comment,
                active = _active,
                sample_prep_visible = _samplePrepVisible,
                fraction_count = _fractionCount
            WHERE separation_group = _separationGroup

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

COMMENT ON PROCEDURE public.add_update_separation_group IS 'AddUpdateSeparationGroup';
