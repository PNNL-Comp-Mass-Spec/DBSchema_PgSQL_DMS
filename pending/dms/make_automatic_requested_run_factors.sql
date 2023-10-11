--
CREATE OR REPLACE PROCEDURE public.make_automatic_requested_run_factors
(
    _batchID int,
    _mode text = 'all',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
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
**    _mode     Unused parameter (proposed to be 'all' or 'actual_run_order', but in reality this procedure always calls update_requested_run_factors with f="Actual_Run_Order" defined by dataset acquisition times)
**
**  Auth:   grk
**  Date:   03/23/2010 grk - Initial release
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          06/10/2022 mem - Exit the procedure if _batchID is 0 or null
**          03/10/2023 mem - Call update_cached_requested_run_batch_stats to update T_Cached_Requested_Run_Batch_Stats
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _factorList text := '';
BEGIN
    _message := '';
    _returnCode := '';

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

    INSERT INTO Tmp_Requests ( Request )
    SELECT t_requested_run.request_id
    FROM t_requested_run
         INNER JOIN t_dataset
           ON t_requested_run.dataset_id = t_dataset.dataset_id
    WHERE t_requested_run.batch_id = _batchID AND
          NOT t_dataset.acq_time_start IS NULL
    ORDER BY t_dataset.acq_time_start;

    SELECT string_agg(format('<r i="%s" f="Actual_Run_Order" v="%s" />', Request, Actual_Run_Order), '' ORDER BY Request)
    INTO _factorList
    FROM Tmp_Requests;

    -----------------------------------------------------------
    -- Update factors
    -----------------------------------------------------------

    If Coalesce(_factorList, '') = '' Then
        RETURN;
    End If;

    If _callingUser = '' Then
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

COMMENT ON PROCEDURE public.make_automatic_requested_run_factors IS 'MakeAutomaticRequestedRunFactors';
