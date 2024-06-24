--
-- Name: add_update_separation_group(text, text, integer, integer, integer, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_separation_group(IN _separationgroup text, IN _comment text, IN _active integer, IN _sampleprepvisible integer, IN _fractioncount integer, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing separation group
**
**  Arguments:
**    _separationGroup      Separation group name
**    _comment              Group comment
**    _active               Active: 1 means active, 0 means inactive
**    _samplePrepVisible    When 1, include in the DMS website chooser used when editing a sample prep request
**    _fractionCount        For separation groups used when fractionating samples, the number of fractions to be generated, e.g. 'LC-MicroHpH-12' has a fraction count of 12
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user (unused by this procedure)
**
**  Auth:   mem
**  Date:   06/12/2017 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/15/2021 mem - Add _fractionCount
**          01/17/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
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

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _separationGroup   := Trim(Coalesce(_separationGroup, ''));
        _comment           := Trim(Coalesce(_comment, ''));
        _active            := Coalesce(_active, 0);
        _samplePrepVisible := Coalesce(_samplePrepVisible, 0);
        _fractionCount     := Coalesce(_fractionCount, 0);
        _mode              := Trim(Lower(Coalesce(_mode, '')));

        If _separationGroup = '' Then
            RAISE EXCEPTION 'Separation group name must be defined';
        End If;

        If _active Not In (0, 1) Then
            _active := 1;
        End If;

        If _samplePrepVisible Not In (0, 1) Then
            _samplePrepVisible := 1;
        End If;

        If _mode = 'add' And Exists (SELECT separation_group FROM t_separation_group WHERE separation_group = _separationGroup::citext) Then
            RAISE EXCEPTION 'Cannot add: separation group "%" already exists', _separationGroup;
        End If;

        If _mode = 'update' Then
            If Not Exists (SELECT separation_group FROM t_separation_group WHERE separation_group = _separationGroup::citext) Then
                RAISE EXCEPTION 'Cannot update: separation group "%" does not exist', _separationGroup;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_separation_group (
                separation_group,
                comment,
                active,
                sample_prep_visible,
                fraction_count
            ) VALUES (
                _separationGroup,
                _comment,
                _active,
                _samplePrepVisible,
                _fractionCount
            );

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_separation_group
            SET comment             = _comment,
                active              = _active,
                sample_prep_visible = _samplePrepVisible,
                fraction_count      = _fractionCount
            WHERE separation_group = _separationGroup::citext;

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
                        _callingProcLocation => '', _logError => _logErrors);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_separation_group(IN _separationgroup text, IN _comment text, IN _active integer, IN _sampleprepvisible integer, IN _fractioncount integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_separation_group(IN _separationgroup text, IN _comment text, IN _active integer, IN _sampleprepvisible integer, IN _fractioncount integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_separation_group(IN _separationgroup text, IN _comment text, IN _active integer, IN _sampleprepvisible integer, IN _fractioncount integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateSeparationGroup';

