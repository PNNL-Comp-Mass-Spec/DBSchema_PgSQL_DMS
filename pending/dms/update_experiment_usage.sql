--
CREATE OR REPLACE PROCEDURE public.update_experiment_usage
(
    _infoOnly boolean = false,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates column Last_Used in T_Experiments
**
**      Last_Used is used by LcmsNetDMSTools when retrieving recent experiments
**
**  Auth:   mem
**  Date:   07/31/2015 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);
    _message := '';

    If _infoOnly Then
        ---------------------------------------------------
        -- Preview the updates
        ---------------------------------------------------
        --
        SELECT E.exp_id,
               E.last_used,
               LookupRR.MostRecentUse AS Last_Used_ReqRun,
               LookupDS.MostRecentUse AS Last_Used_Dataset
        FROM t_experiments E
             LEFT OUTER JOIN ( SELECT E.exp_id,
                                      MAX(CAST(RR.created AS date)) AS MostRecentUse
                               FROM t_experiments E
                                    INNER JOIN t_requested_run RR
                                      ON E.exp_id = RR.exp_id
                               GROUP BY E.exp_id
                             ) LookupRR
               ON E.exp_id = LookupRR.exp_id
             LEFT OUTER JOIN ( SELECT E.exp_id,
                                      MAX(CAST(DS.created AS date)) AS MostRecentUse
                               FROM t_experiments E
                                    INNER JOIN t_dataset DS
                                      ON E.exp_id = DS.exp_id
                               GROUP BY E.exp_id
                             ) LookupDS
               ON E.exp_id = LookupDS.exp_id
        WHERE LookupRR.MostRecentUse > E.last_used OR
              LookupDS.MostRecentUse > E.last_used

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update based on the most recent Requested Run
    ---------------------------------------------------
    --
    UPDATE t_experiments
    SET last_used = MostRecentUse
    FROM t_experiments E

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE t_experiments
    **   SET ...
    **   FROM source
    **   WHERE source.id = t_experiments.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT E.exp_id,
                             MAX(CAST(RR.Created AS date)) AS MostRecentUse
                      FROM t_experiments E

                      /********************************************************************************
                      ** This UPDATE query includes the target table name in the FROM clause
                      ** The WHERE clause needs to have a self join to the target table, for example:
                      **   UPDATE t_experiments
                      **   SET ...
                      **   FROM source
                      **   WHERE source.id = t_experiments.id;
                      ********************************************************************************/

                                             ToDo: Fix this query

                           INNER JOIN t_requested_run RR
                             ON E.exp_id = RR.exp_id
                      GROUP BY E.exp_id
                    ) LookupQ
           ON E.exp_id = LookupQ.exp_id
    WHERE LookupQ.MostRecentUse > E.Last_Used;

    ---------------------------------------------------
    -- Update based on the most recent Dataset
    ---------------------------------------------------
    --
    UPDATE t_experiments
    SET last_used = MostRecentUse
    FROM t_experiments E

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE t_experiments
    **   SET ...
    **   FROM source
    **   WHERE source.id = t_experiments.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT E.exp_id,
                             MAX(CAST(DS.Created AS date)) AS MostRecentUse
                      FROM t_experiments E

                      /********************************************************************************
                      ** This UPDATE query includes the target table name in the FROM clause
                      ** The WHERE clause needs to have a self join to the target table, for example:
                      **   UPDATE t_experiments
                      **   SET ...
                      **   FROM source
                      **   WHERE source.id = t_experiments.id;
                      ********************************************************************************/

                                             ToDo: Fix this query

                           INNER JOIN t_dataset DS
                             ON E.exp_id = DS.exp_id
                      GROUP BY E.exp_id

                      ) LookupQ
           ON E.Exp_ID = LookupQ.Exp_ID
    WHERE LookupQ.MostRecentUse > E.Last_Used
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    RAISE INFO 'Updated Last_Used date for % %', _myRowCount, public.check_plural(_myRowcount, 'experiment',  'experiments');

END
$$;

COMMENT ON PROCEDURE public.update_experiment_usage IS 'UpdateExperimentUsage';
