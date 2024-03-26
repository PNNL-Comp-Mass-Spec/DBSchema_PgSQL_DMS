--
-- Name: update_charge_code_usage_proc(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_charge_code_usage_proc(IN _infoonly boolean, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls function update_charge_code_usage() to update the usage columns in t_charge_code
**
**      Used by timetable task "Update charge code usage"
**
**  Arguments:
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   03/25/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _chargeCodeInfo record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, true);

    CREATE TEMP TABLE Tmp_UpdateResults (
        Charge_Code citext,         -- Holds charge code if _infoOnly is true; will be 'DB Updated' or 'Stats already up-to-date' if _infoOnly is false
        Usage_Comment citext,
        Sample_Prep_Usage int,
        Requested_Run_Usage int
    );

    INSERT INTO Tmp_UpdateResults (
        Charge_Code,
        Usage_Comment,
        Sample_Prep_Usage,
        Requested_Run_Usage
    )
    SELECT charge_code,
           usage_comment,
           sample_prep_usage_new,
           requested_run_usage_new
    FROM public.update_charge_code_usage (_infoOnly => _infoOnly);

    If Not FOUND Then
        _message := 'Function public.update_charge_code_usage() did not return any results';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        DROP TABLE Tmp_UpdateResults;
        RETURN;
    End If;

    RAISE INFO '';

    If _infoOnly Then
        _formatSpecifier := '%-11s %-17s %-19s';

        _infoHead := format(_formatSpecifier,
                            'Charge_Code',
                            'Sample_Prep_Usage',
                            'Requested_Run_Usage'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-----------',
                                     '-----------------',
                                     '-------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;
    End If;

    FOR _chargeCodeInfo IN
        SELECT Charge_Code AS ChargeCode,
               Usage_Comment AS UsageComment,
               Sample_Prep_Usage AS SamplePrepUsage,
               Requested_Run_Usage AS RequestedRunUsage
        FROM Tmp_UpdateResults
        WHERE NOT _infoOnly OR Sample_Prep_Usage > 0 OR Requested_Run_Usage > 0
        ORDER BY Charge_Code
    LOOP
        If _infoOnly Then
            _infoData := format(_formatSpecifier,
                                _chargeCodeInfo.ChargeCode,
                                _chargeCodeInfo.SamplePrepUsage,
                                _chargeCodeInfo.RequestedRunUsage
                               );

            RAISE INFO '%', _infoData;
        Else
            RAISE INFO '%', _chargeCodeInfo.UsageComment;
            _message := public.append_to_text(_message, _chargeCodeInfo.UsageComment);
        End If;
    END LOOP;

    If _infoOnly Then
        _message := 'See the output pane for a preview of the updates';
    End If;

    DROP TABLE Tmp_UpdateResults;
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

    DROP TABLE IF EXISTS Tmp_UpdateResults;
END;
$$;


ALTER PROCEDURE public.update_charge_code_usage_proc(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

