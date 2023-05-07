--
CREATE OR REPLACE PROCEDURE public.do_sample_submission_operation
(
    _id int,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Performs operation given by _mode on entity given by _id
**
**      Note: this procedure has not been used since 2012
**
**  Arguments:
**    _mode   'make_folder'
**
**  Auth:   grk
**  Date:   05/07/2010 grk - initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**                         - Add call to PostUsageLogEntry
**          08/01/2017 mem - Use THROW if not authorized
**          01/12/2023 mem - Remove call to CallSendMessage since it was deprecated in 2016
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _storagePath int := 0;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Make the folder for the sample submission
        ---------------------------------------------------
        --
        If _mode = 'make_folder' Then

            ---------------------------------------------------
            -- Get storage path from sample submission
            --
            SELECT Coalesce(storage_id, 0)
            INTO _storagePath
            FROM t_sample_submission
            WHERE submission_id = _id;

            ---------------------------------------------------
            -- If storage path not defined, get valid path ID and update sample submission
            --
            If _storagePath = 0 Then
                --
                SELECT storage_id
                INTO _storagePath
                FROM t_prep_file_storage
                WHERE state = 'Active' AND
                      purpose = 'Sample_Prep';

                If Not FOUND Then
                    RAISE EXCEPTION 'Storage path for files could not be found in t_prep_file_storage';
                End If;

                UPDATE t_sample_submission
                SET storage_id = _storagePath
                WHERE submission_id = _id;
            End If;

            -- CallSendMessage was deprecated in 2016
            --
            -- Call call_send_message _id,'sample_submission', _message => _message
            -- If _returnCode <> '' Then
            --     RAISE EXCEPTION 'CallSendMessage:%', _message;
            -- End If;
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

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_id, 0) > 0 Then
        _usageMessage := 'Performed submission operation for submission ID ' || Cast(_id as text) || '; mode ' || _mode;

        _usageMessage := _usageMessage || '; user ' || Coalesce(_callingUser, '??');

        Call post_usage_log_entry ('do_sample_submission_operation', _usageMessage, _minimumUpdateInterval => 2);
    End If;

END
$$;

COMMENT ON PROCEDURE public.do_sample_submission_operation IS 'DoSampleSubmissionOperation';
