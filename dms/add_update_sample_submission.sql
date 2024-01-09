--
-- Name: add_update_sample_submission(integer, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_sample_submission(INOUT _id integer, IN _campaign text, IN _receivedby text, INOUT _containerlist text, IN _newcontainercomment text, IN _description text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit existing item in T_Sample_Submission
**
**  Arguments:
**    _id                   Input/output: sample submission ID
**    _campaign             Campaign name
**    _receivedBy           Person who received the sample; supports 'Zink, Erika M', 'Zink, Erika M (D3P704)', or 'D3P704'
**    _containerList        Comma-separated list of material container names; use 'na' if no container
**    _newContainerComment  Comment for new containers created when adding a sample submission item
**    _description          Sample submission description
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Auth:   grk
**  Date:   04/23/2010
**          04/30/2010 grk - Added call to CallSendMessage
**          09/23/2011 grk - Accomodate researcher field in AssureMaterialContainersExist
**          02/06/2013 mem - Added logic to prevent duplicate entries
**          12/08/2014 mem - Now using Name_with_PRN to obtain the user's name and username
**          03/26/2015 mem - Update duplicate sample submission message
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/18/2017 mem - Disable logging certain messages to T_Log_Entries
**          11/19/2023 mem - Send campaign name to assure_material_containers_exist
**          11/21/2023 mem - Ported to PostgreSQL
**                         - If _containerList is 'na', assure that it is lowercase
**          11/22/2023 mem - Allow _receivedBy to be of the form 'Zink, Erika M', 'Zink, Erika M (D3P704)', or 'D3P704'
**          01/03/2024 mem - Update warning messages
**          01/08/2024 mem - Remove procedure name from error message
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text := '';
    _logErrors boolean := false;
    _campaignID int;

    _matchCount int;
    _receivedByUserName text;
    _receivedByUserID int;

    _containerListCopy text;
    _comment text;

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

        _campaign := Trim(Coalesce(_campaign, ''));

        If _campaign = '' Then
            RAISE EXCEPTION 'Campaign name must be specified';
        End If;

        _containerList := Trim(Coalesce(_containerList, ''));

        If _containerList = '' Then
            RAISE EXCEPTION 'Container list must be specified';
        End If;

        If _containerList::citext = 'na' Then
            _containerList := 'na';
        End If;

        _receivedBy := Trim(Coalesce(_receivedBy, ''));

        If _receivedBy = '' Then
            RAISE EXCEPTION 'Received by name must be specified';
        End If;

        _newContainerComment := Trim(Coalesce(_newContainerComment, ''));

        _description := Trim(Coalesce(_description, ''));

        If _description = '' Then
            RAISE EXCEPTION 'Description must be specified';
        End If;

        ---------------------------------------------------
        -- Resolve Campaign ID
        ---------------------------------------------------

        SELECT campaign_id
        INTO _campaignID
        FROM t_campaign
        WHERE campaign = _campaign;

        If Not FOUND Then
            RAISE EXCEPTION 'Campaign "%" could not be found', _campaign;
        End If;

        ---------------------------------------------------
        -- Validate the received by person
        ---------------------------------------------------

        If _receivedBy::citext In ('', 'na', 'none') Then
            _message := 'Received by person must be a valid DMS user';
            _returnCode := 'U5201';
            RETURN;
        End If;

        CALL public.auto_resolve_name_to_username (
                        _receivedBy,
                        _matchCount       => _matchCount,           -- Output
                        _matchingUsername => _receivedByUserName,   -- Output
                        _matchingUserID   => _receivedByUserID);    -- Output

        If _matchCount = 1 Then
            -- Single match found; update _receivedBy to be only the username, e.g. 'D3P704'
            _receivedBy := _receivedByUserName;

        Else
            -- Single match not found

            _message := 'Received by person must be a valid DMS user';

            If _matchCount = 0 Then
                _message := format('%s; "%s" does not exist', _message, _receivedBy);
            Else
                _message := format('%s; "%s" matches more than one user', _message, _receivedBy);
            End If;

            _returnCode := 'U5202';
            RETURN;
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry

            If Not Exists (SELECT submission_id FROM t_sample_submission WHERE submission_id = _id) Then
                RAISE EXCEPTION 'Cannot update: sample submission ID % does not exist', _id;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            ---------------------------------------------------
            -- Verify container list
            ---------------------------------------------------

            _containerListCopy := _containerList;

            CALL public.assure_material_containers_exist (
                            _containerList => _containerListCopy,   -- Input/Output
                            _comment       => _comment,
                            _type          => 'Box',
                            _campaignName  => _campaign,
                            _researcher    => _receivedByUserName,
                            _mode          => 'verify_only',
                            _message       => _msg,                 -- Output
                            _returnCode    => _returnCode,          -- Output
                            _callingUser   => '');

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;

            ---------------------------------------------------
            -- Verify that this doesn't duplicate an existing sample submission request
            ---------------------------------------------------

            SELECT submission_id
            INTO _id
            FROM t_sample_submission
            WHERE campaign_id = _campaignID AND
                  received_by_user_id = _receivedByUserID AND
                  description = _description;

            If FOUND Then
                RAISE EXCEPTION 'New sample submission is duplicate of existing sample submission, ID %; both have identical Campaign, Received By User, and Description', _id;
            End If;

            _logErrors := true;

            BEGIN
                ---------------------------------------------------
                -- Add the new data
                ---------------------------------------------------

                INSERT INTO t_sample_submission (
                    campaign_id,
                    received_by_user_id,
                    container_list,
                    description,
                    storage_id
                ) VALUES (
                    _campaignID,
                    _receivedByUserID,
                    _containerList,
                    _description,
                    NULL
                )
                RETURNING submission_id
                INTO _id;

                ---------------------------------------------------
                -- Add containers (as needed)
                ---------------------------------------------------

                If _newContainerComment = '' Then
                    _comment := format('(created via sample submission %s)', _id);
                Else
                    _comment := format('%s (sample submission %s)', _newContainerComment, _id);
                End If;

                CALL public.assure_material_containers_exist (
                                _containerList => _containerList,   -- Input/Output
                                _comment       => _comment,
                                _type          => 'Box',
                                _campaignName  => _campaign,
                                _researcher    => _receivedByUserName,
                                _mode          => 'create',
                                _message       => _msg,             -- Output
                                _returnCode    => _returnCode,      -- Output
                                _callingUser   => _callingUser);

                If _returnCode <> '' Then
                    RAISE EXCEPTION '%', _message;
                End If;

                ---------------------------------------------------
                -- Update container list for sample submission
                ---------------------------------------------------

                UPDATE t_sample_submission
                SET container_list = _containerList
                WHERE submission_id = _id;

            END;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            _logErrors := true;

            UPDATE t_sample_submission
            SET campaign_id         = _campaignID,
                received_by_user_id = _receivedByUserID,
                container_list      = _containerList,
                description         = _description
            WHERE submission_id = _id;

        End If;

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

END
$$;


ALTER PROCEDURE public.add_update_sample_submission(INOUT _id integer, IN _campaign text, IN _receivedby text, INOUT _containerlist text, IN _newcontainercomment text, IN _description text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_sample_submission(INOUT _id integer, IN _campaign text, IN _receivedby text, INOUT _containerlist text, IN _newcontainercomment text, IN _description text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_sample_submission(INOUT _id integer, IN _campaign text, IN _receivedby text, INOUT _containerlist text, IN _newcontainercomment text, IN _description text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateSampleSubmission';

