--
-- Name: test_chain_procedures(boolean, boolean, boolean, boolean, text, text); Type: PROCEDURE; Schema: test; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE test.test_chain_procedures(IN _commitafterlog boolean DEFAULT true, IN _rollbackafterlog boolean DEFAULT false, IN _rethrowexception boolean DEFAULT false, IN _logerrors boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;

    _entryID int;
Begin
    RAISE INFO 'Start';

    If 1 = 1 Then
        ------------------------------------------------------------
        -- This Begin/End block logs a message to t_log_entries
        -- A transaction is auto-created when the row is inserted into t_log_entries
        ------------------------------------------------------------

        Begin
            RAISE INFO 'Insert new log entry';

            INSERT INTO t_log_entries (posted_by, type, message)
            VALUES ('Monroe', 'Test', 'Test log message')
            RETURNING entry_id
            INTO _entryID;

            RAISE INFO 'Call alter_entered_by_user';
            CALL alter_entered_by_user('public', 't_log_entries', 'entry_id', _entryID, 'bob',
                                    _entrydatecolumnname := 'entered',
                                    _message := _message);
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

            RAISE NOTICE 'Error in block 1; sqlstate: %, message: %, context: [%]',
                 _sqlstate, _message, replace(_exceptionContext, E'\n', ' <- ');
        END;

        ------------------------------------------------------------
        -- Note that Commit and Rollback commands cannot be included
        -- within a Begin/End block that has an Exception handler
        ------------------------------------------------------------

        If _commitAfterLog Then
            -- This commit is not needed, since the divide by zero error in the next Begin/End block will be handled via the exception handler
            -- However, if the exception is re-thrown, and this commit has not been made, the new row added to t_log_entries will be removed
            COMMIT;
        End If;

        If _rollbackAfterLog Then
            ROLLBACK;
        End If;

        ------------------------------------------------------------
        -- This Begin/End block triggers an exception
        ------------------------------------------------------------

        Begin
            PERFORM 15 / 0;
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

            RAISE NOTICE 'Error in block 2; sqlstate: %, message: %, context: [%]',
                 _sqlstate, _message, replace(_exceptionContext, E'\n', ' <- ');

             If _rethrowException Then
                RAISE EXCEPTION '%', _message;
             End If;
        END;

        RAISE INFO 'Inside End If';
    End If;

    RAISE INFO 'End';

End
$$;


ALTER PROCEDURE test.test_chain_procedures(IN _commitafterlog boolean, IN _rollbackafterlog boolean, IN _rethrowexception boolean, IN _logerrors boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

