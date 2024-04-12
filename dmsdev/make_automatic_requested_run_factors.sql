--
-- Name: make_automatic_requested_run_factors(integer, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.make_automatic_requested_run_factors(IN _batchid integer, IN _mode text DEFAULT 'all'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds/updates factors named Actual_Run_Order for the requested runs in the given batch
**      The values for the factors are 1, 2, 3, etc., ordered by the acquisition time values for the datasets associated with the requested runs
**      Requested runs without a dataset will not have an Actual_Run_Order factor added
**
**  Arguments:
**    _batchID      Requested run batch ID
**    _mode         Unused parameter (proposed to be 'all' or 'actual_run_order', but in reality this procedure always calls update_requested_run_factors with f="Actual_Run_Order" defined by dataset acquisition times)
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   grk
**  Date:   03/23/2010 grk - Initial version
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          06/10/2022 mem - Exit the procedure if _batchID is 0 or null
**          03/10/2023 mem - Call update_cached_requested_run_batch_stats to update T_Cached_Requested_Run_Batch_Stats
**          02/14/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _factorList text := '';
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    If Coalesce(_batchID, 0) = 0 Then
        _message := 'Batch ID is zero; cannot create automatic factors';
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Make factor list for actual run order
    -- FUTURE: support 'actual_run_order' or 'all' for _mode
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_Requests (
        Request int,
        Actual_Run_Order int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    INSERT INTO Tmp_Requests (Request)
    SELECT RR.request_id
    FROM t_requested_run RR
         INNER JOIN t_dataset DS
           ON RR.dataset_id = DS.dataset_id
    WHERE RR.batch_id = _batchID AND
          NOT DS.acq_time_start IS NULL
    ORDER BY DS.acq_time_start;

    SELECT string_agg(format('<r i="%s" f="Actual_Run_Order" v="%s" />', Request, Actual_Run_Order), '' ORDER BY Request)
    INTO _factorList
    FROM Tmp_Requests;

    -----------------------------------------------------------
    -- Update factors
    -----------------------------------------------------------

    If Coalesce(_factorList, '') = '' Then
        If Exists ( SELECT RR.request_id
                    FROM t_requested_run RR
                         INNER JOIN t_dataset DS
                           ON RR.dataset_id = DS.dataset_id
                    WHERE RR.batch_id = _batchID)
        Then
            RAISE INFO 'The datasets for requested runs associated with batch ID % all have null Acq_Time_Start values', _batchID;
        Else
            RAISE INFO 'None of the requested runs for batch ID % has an associated dataset', _batchID;
        End If;
        RETURN;
    End If;

    If Trim(Coalesce(_callingUser, '')) = '' Then
        _callingUser := public.get_user_login_without_domain('');
    End If;

    CALL public.update_requested_run_factors (
                    _factorList,
                    _message     => _message,       -- Output
                    _returnCode  => _returnCode,    -- Output
                    _callingUser => _callingUser,
                    _infoOnly    => false);

    DROP TABLE Tmp_Requests;
END
$$;


ALTER PROCEDURE public.make_automatic_requested_run_factors(IN _batchid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE make_automatic_requested_run_factors(IN _batchid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.make_automatic_requested_run_factors(IN _batchid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'MakeAutomaticRequestedRunFactors';

