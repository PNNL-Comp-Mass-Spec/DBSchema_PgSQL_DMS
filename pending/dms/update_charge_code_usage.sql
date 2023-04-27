--
CREATE OR REPLACE PROCEDURE public.update_charge_code_usage
(
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the Usage columns in T_Charge_Code
**
**  Auth:   mem
**  Date:   06/04/2013 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    -----------------------------------------------------------
    -- Create the table to hold the data
    -----------------------------------------------------------

    If Not _infoOnly Then

        UPDATE t_charge_code
        SET usage_sample_prep = SPR_Usage
        FROM t_charge_code Target

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE t_charge_code
        **   SET ...
        **   FROM source
        **   WHERE source.id = t_charge_code.id;
        ********************************************************************************/

                               ToDo: Fix this query

                INNER JOIN ( SELECT CC.charge_code,
                                    COUNT(*) AS SPR_Usage
                            FROM t_sample_prep_request SPR
                                INNER JOIN t_charge_code CC
                                    ON SPR.work_package = CC.charge_code
                            GROUP BY CC.charge_code
                           ) StatsQ
                ON Target.charge_code = StatsQ.charge_code
        WHERE Coalesce(Target.usage_sample_prep, 0) <> SPR_Usage
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        UPDATE t_charge_code
        SET usage_requested_run = RR_Usage
        FROM t_charge_code Target

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE t_charge_code
        **   SET ...
        **   FROM source
        **   WHERE source.id = t_charge_code.id;
        ********************************************************************************/

                               ToDo: Fix this query

                INNER JOIN ( SELECT CC.charge_code,
                                    COUNT(*) AS RR_Usage
                            FROM t_charge_code CC

                            /********************************************************************************
                            ** This UPDATE query includes the target table name in the FROM clause
                            ** The WHERE clause needs to have a self join to the target table, for example:
                            **   UPDATE t_charge_code
                            **   SET ...
                            **   FROM source
                            **   WHERE source.id = t_charge_code.id;
                            ********************************************************************************/

                                                   ToDo: Fix this query

                                INNER JOIN t_requested_run RR
                                    ON CC.Charge_Code = RR.work_package
                            GROUP BY CC.Charge_Code
                           ) StatsQ
                ON Target.Charge_Code = StatsQ.Charge_Code
        WHERE Coalesce(Target.Usage_RequestedRun, 0) <> RR_Usage
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    Else

        SELECT Coalesce(A.charge_code, B.charge_code) AS Charge_Code,
               A.SPR_Usage,
               B.RR_Usage
        FROM ( SELECT CC.charge_code,
                      COUNT(*) AS SPR_Usage
               FROM t_sample_prep_request SPR
                    INNER JOIN t_charge_code CC
                      ON SPR.work_package = CC.charge_code
               GROUP BY CC.charge_code
             ) A
             FULL OUTER JOIN ( SELECT CC.charge_code,
                                      COUNT(*) AS RR_Usage
                               FROM t_charge_code CC
                                    INNER JOIN t_requested_run RR
                                      ON CC.charge_code = RR.work_package
                               GROUP BY CC.charge_code
             ) B
               ON A.charge_code = B.charge_code
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    End If;

    Return _myError
END
$$;

COMMENT ON PROCEDURE public.update_charge_code_usage IS 'UpdateChargeCodeUsage';
