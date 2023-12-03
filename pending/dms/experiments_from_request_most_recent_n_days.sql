--
CREATE OR REPLACE FUNCTION public.experiments_from_request_most_recent_n_days
(
    _requestID int,
    _days int
)
RETURNS int
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns count of number of experiments made from given sample prep request
**
**      Only includes experiments created within the most recent N days, specified by _days
**
**  Arguments:
**    _requestID    Sample prep request ID
**    _days         Number of days before today to include
**
**  Auth:   mem
**  Date:   03/26/2013 mem - Initial version
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          06/17/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**          12/15/2024 mem - Ported to Postgres
**
*****************************************************/
DECLARE
    _count int;
BEGIN
    SELECT COUNT(exp_id)
    INTO _count
    FROM t_experiments
    WHERE sample_prep_request_id = _requestID AND
          created > CURRENT_TIMESTAMP - make_interval (days => Coalesce(_days, 1));

    RETURN Coalesce(_count, 0);
END
$$;

COMMENT ON FUNCTION public.experiments_from_request_most_recent_n_days IS 'ExperimentsFromRequestMostRecentNDays';
