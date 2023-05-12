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
**      Updates the usage columns in T_Charge_Code
**
**  Auth:   mem
**  Date:   06/04/2013 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN

    If _infoOnly Then

        -- ToDo: Show this using RAISE INFO
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

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update usage stats
    ---------------------------------------------------
    --
    UPDATE t_charge_code Target
    SET usage_sample_prep = SPR_Usage
    FROM ( SELECT CC.charge_code,
                  COUNT(*) AS SPR_Usage
           FROM t_sample_prep_request SPR
               INNER JOIN t_charge_code CC
                   ON SPR.work_package = CC.charge_code
           GROUP BY CC.charge_code
          ) StatsQ
    WHERE Target.charge_code = StatsQ.charge_code AND
          Coalesce(Target.usage_sample_prep, 0) <> StatsQ.SPR_Usage

    UPDATE t_charge_code Target
    SET usage_requested_run = RR_Usage
    FROM ( SELECT CC.charge_code,
                   COUNT(*) AS RR_Usage
           FROM t_charge_code CC
               INNER JOIN t_requested_run RR
                   ON CC.Charge_Code = RR.work_package
           GROUP BY CC.Charge_Code
          ) StatsQ
    WHERE Target.Charge_Code = StatsQ.Charge_Code AND
          Coalesce(Target.Usage_RequestedRun, 0) <> StatsQ.RR_Usage;

END
$$;

COMMENT ON PROCEDURE public.update_charge_code_usage IS 'UpdateChargeCodeUsage';
