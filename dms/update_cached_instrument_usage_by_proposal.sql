--
-- Name: update_cached_instrument_usage_by_proposal(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_instrument_usage_by_proposal(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the data in T_Cached_Instrument_Usage_by_Proposal
**
**  Auth:   mem
**  Date:   12/02/2013 mem - Initial Version
**          02/23/2016 mem - Add set XACT_ABORT on
**          02/10/2022 mem - Add new usage type codes added to T_EUS_UsageType on 2021-05-26
**                         - Use the last 12 months for determining usage (previously used last two fiscal years)
**          01/02/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _message := '';
    _returnCode := '';

    BEGIN

        MERGE INTO t_cached_instrument_usage_by_proposal AS target
        USING (SELECT TIN.instrument_group,
                      RR.eus_proposal_id,
                      (SUM(TD.acq_length_minutes) / 60.0)::real AS Actual_Hours
               FROM t_dataset AS TD
                    INNER JOIN t_requested_run AS RR
                      ON TD.dataset_id = RR.dataset_id
                    INNER JOIN t_instrument_name AS TIN
                      ON TIN.instrument_id = TD.instrument_id
               WHERE TD.dataset_rating_id > 1
                     AND RR.eus_usage_type_id IN (16, 19, 20, 21)                          -- User, User_Unknown, User_Onsite, User_Remote
                     AND TD.dataset_state_id = 3                                           -- Complete
                     AND TD.acq_time_start >= CURRENT_TIMESTAMP - Interval '1 year'        -- The last 12 months (previously used >= get_fiscal_year_start(1))
                     AND NOT RR.eus_proposal_id IS NULL
               GROUP BY TIN.instrument_group, RR.eus_proposal_id
            ) AS Source
        ON (target.instrument_group = source.instrument_group AND target.eus_proposal_id = source.eus_proposal_id)
        WHEN MATCHED AND target.actual_hours IS DISTINCT FROM source.actual_hours THEN
            UPDATE SET
                actual_hours = source.actual_hours
        WHEN NOT MATCHED THEN
            INSERT (instrument_group, eus_proposal_id, actual_hours)
            VALUES (source.instrument_group, source.eus_proposal_id, source.actual_hours);

        -- Delete rows in t_cached_instrument_usage_by_proposal that are not in the Source query shown above

        DELETE FROM t_cached_instrument_usage_by_proposal target
        WHERE NOT EXISTS (SELECT source.instrument_group
                          FROM (SELECT TIN.instrument_group,
                                       RR.eus_proposal_id
                                FROM t_dataset AS TD
                                     INNER JOIN t_requested_run AS RR
                                       ON TD.dataset_id = RR.dataset_id
                                     INNER JOIN t_instrument_name AS TIN
                                       ON TIN.instrument_id = TD.instrument_id
                                WHERE TD.dataset_rating_id > 1
                                      AND RR.eus_usage_type_id IN (16, 19, 20, 21)                          -- User, User_Unknown, User_Onsite, User_Remote
                                      AND TD.dataset_state_id = 3                                           -- Complete
                                      AND TD.acq_time_start >= CURRENT_TIMESTAMP - Interval '1 year'        -- The last 12 months (previously used >= get_fiscal_year_start(1))
                                      AND NOT RR.eus_proposal_id IS NULL
                                GROUP BY TIN.instrument_group, RR.eus_proposal_id
                               ) AS Source
                          WHERE target.instrument_group = source.instrument_group AND
                                target.eus_proposal_id = source.eus_proposal_id);

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


ALTER PROCEDURE public.update_cached_instrument_usage_by_proposal(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_instrument_usage_by_proposal(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_instrument_usage_by_proposal(INOUT _message text, INOUT _returncode text) IS 'UpdateCachedInstrumentUsageByProposal';

