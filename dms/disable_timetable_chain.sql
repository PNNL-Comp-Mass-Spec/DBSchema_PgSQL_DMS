--
-- Name: disable_timetable_chain(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.disable_timetable_chain(IN _chainid integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Disable the given timetable chain in table timetable.chain
**
**  Arguments:
**    _chainID          Timetable chain ID
**    _infoOnly         When true, show the chain that would be disabled (or a warning message if it's already disabled)
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   05/10/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _chainInfo record;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _infoOnly := Coalesce(_infoOnly, false);

        If _chainID Is Null Then
            _message := 'Chain ID cannot be null';
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        SELECT C.chain_id, C.chain_name, C.run_at, C.live, I.interval_description
        INTO _chainInfo
        FROM timetable.chain C
             LEFT OUTER JOIN timetable.t_cron_interval I ON
               C.run_at = I.cron_interval
        WHERE C.chain_id = _chainID;

        If Not FOUND Then
            _message := format('Invalid Chain ID: %s', _chainID);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If Not _chainInfo.live Then
            _message := format('Chain ID %s is already disabled in timetable.chain (live = false for chain "%s")', _chainID, _chainInfo.chain_name);
            RAISE INFO '%', _message;
            RETURN;
        End If;

        If _infoOnly Then
            ----------------------------------------------------
            -- Display the chain id, name, and schedule
            ----------------------------------------------------

            _message := format('Would disable chain ID %s: %s', _chainInfo.chain_id, _chainInfo.chain_name);

            RAISE INFO '';
            RAISE INFO '%', _message;
            RAISE INFO 'Cron time: %', _chainInfo.run_at;
            RAISE INFO 'Cron desc: %', _chainInfo.interval_description;

            RETURN;
        End If;

        UPDATE timetable.chain
        SET live = false
        WHERE chain_id = _chainID;

        _message := Format('Set live to false for timetable chain %s ("%s")', _chainID, _chainInfo.chain_name);

        RAISE INFO '%', _message;

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


ALTER PROCEDURE public.disable_timetable_chain(IN _chainid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

