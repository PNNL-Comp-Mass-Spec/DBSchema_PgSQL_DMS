--
-- Name: update_charge_code_usage(boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.update_charge_code_usage(_infoonly boolean DEFAULT false) RETURNS TABLE(charge_code public.citext, usage_comment public.citext, sample_prep_usage_old integer, sample_prep_usage_new integer, requested_run_usage_old integer, requested_run_usage_new integer, wbs_title public.citext, charge_code_title public.citext, sub_account_title public.citext, setup_date timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the usage columns in T_Charge_Code
**
**  Arguments:
**    _infoOnly     When true, preview the old and new values; otherwise, update the stats
**
**  Example usage:
**
**      -- Preview changes:
**      SELECT * FROM update_charge_code_usage(true);
**
**      -- Apply changes:
**      SELECT * FROM update_charge_code_usage(false);
**
**  Auth:   mem
**  Date:   06/04/2013 mem - Initial version
**          05/24/2023 mem - Look for work packages that have non-zero usage values but are not actually in use
**                         - Ported to PostgreSQL
**          07/10/2023 mem - Use COUNT(SPR.prep_request_id) and COUNT(RR.request_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _updateCount int;
BEGIN

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview Updates
        ---------------------------------------------------

        -- Look for Charge Codes with a non-zero sample prep usage value, but are no longer associated with a sample prep request
        --
        RETURN QUERY
        SELECT CC.Charge_Code,
               'Has non-zero sample prep usage, but not actually used'::citext AS Usage_Comment,
               CC.Usage_Sample_Prep AS Sample_Prep_Usage_Old,
               0 AS Sample_Prep_Usage_New,
               CC.Usage_Requested_Run AS Requested_Run_Usage_Old,
               CC.Usage_Requested_Run AS Requested_Run_Usage_New,
               CC.WBS_Title,
               CC.Charge_Code_Title,
               CC.Sub_Account_Title,
               CC.Setup_Date
        FROM T_Charge_Code CC
        WHERE CC.Usage_Sample_Prep > 0 AND
              NOT EXISTS ( SELECT 1
                           FROM ( SELECT CC.Charge_Code,
                                         COUNT(SPR.prep_request_id) AS SPR_Usage
                                  FROM T_Sample_Prep_Request SPR
                                       INNER JOIN T_Charge_Code CC
                                         ON SPR.Work_Package = CC.Charge_Code
                                  GROUP BY CC.Charge_Code ) StatsQ
                           WHERE StatsQ.SPR_Usage > 0 AND
                                 StatsQ.Charge_Code = CC.Charge_Code );

        -- Look for Charge Codes with a non-zero requested run usage value, but are no longer associated with a requested run
        --
        RETURN QUERY
        SELECT CC.Charge_Code,
               'Has non-zero requested run usage, but not actually used'::citext AS Usage_Comment,
               CC.Usage_Sample_Prep AS Sample_Prep_Usage_Old,
               CC.Usage_Sample_Prep AS Sample_Prep_Usage_New,
               CC.Usage_Requested_Run AS Requested_Run_Usage_Old,
               0 AS Requested_Run_Usage_New,
               CC.WBS_Title,
               CC.Charge_Code_Title,
               CC.Sub_Account_Title,
               CC.Setup_Date
        FROM T_Charge_Code CC
        WHERE CC.Usage_Requested_Run > 0 AND
              NOT EXISTS ( SELECT 1
                           FROM ( SELECT CC.Charge_Code,
                                         COUNT(request_id) AS RR_Usage
                                  FROM T_Charge_Code CC
                                       INNER JOIN T_Requested_Run RR
                                         ON CC.Charge_Code = RR.Work_Package
                                  GROUP BY CC.Charge_Code ) StatsQ
                           WHERE StatsQ.RR_Usage > 0 AND
                                 StatsQ.Charge_Code = CC.Charge_Code );

        -- Show usage stats for all work packages
        --
        RETURN QUERY
        SELECT Coalesce(A.charge_code, B.charge_code) AS Charge_Code,
               ''::citext AS Usage_Comment,
               A.Sample_Prep_Usage_Old,
               A.Sample_Prep_Usage_New,
               B.Requested_Run_Usage_Old,
               B.Requested_Run_Usage_New,
               Coalesce(A.WBS_Title,         B.WBS_Title)         AS WBS_Title,
               Coalesce(A.Charge_Code_Title, B.Charge_Code_Title) AS Charge_Code_Title,
               Coalesce(A.Sub_Account_Title, B.Sub_Account_Title) AS Sub_Account_Title,
               Coalesce(A.Setup_Date,        B.Setup_Date)        AS Setup_Date
        FROM ( SELECT  CC.charge_code,
                       CC.Usage_Sample_Prep AS Sample_Prep_Usage_Old,
                       COUNT(SPR.prep_request_id)::int4 AS Sample_Prep_Usage_New,
                       CC.WBS_Title,
                       CC.Charge_Code_Title,
                       CC.Sub_Account_Title,
                       CC.Setup_Date
               FROM t_sample_prep_request SPR
                    INNER JOIN t_charge_code CC
                      ON SPR.work_package = CC.charge_code
               GROUP BY CC.charge_code
             ) A
             FULL OUTER JOIN ( SELECT  CC.charge_code,
                                       CC.Usage_Requested_Run AS Requested_Run_Usage_Old,
                                       COUNT(RR.request_id)::int4 AS Requested_Run_Usage_New,
                                       CC.WBS_Title,
                                       CC.Charge_Code_Title,
                                       CC.Sub_Account_Title,
                                       CC.Setup_Date
                               FROM t_charge_code CC
                                    INNER JOIN t_requested_run RR
                                      ON CC.charge_code = RR.work_package
                               GROUP BY CC.charge_code
             ) B
               ON A.charge_code = B.charge_code;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update usage stats
    ---------------------------------------------------

    -- Look for Charge Codes with a non-zero sample prep usage value, but are no longer associated with a sample prep request
    --
    UPDATE T_Charge_Code Target
    SET usage_sample_prep = 0
    WHERE Target.usage_sample_prep > 0 AND
          Target.Charge_Code IN ( SELECT CC.Charge_Code
                                  FROM T_Charge_Code CC
                                  WHERE usage_sample_prep > 0 AND
                                        NOT EXISTS ( SELECT 1
                                                     FROM ( SELECT CC.Charge_Code,
                                                                   COUNT(SPR.prep_request_id) AS SPR_Usage
                                                            FROM T_Sample_Prep_Request SPR
                                                                 INNER JOIN T_Charge_Code CC
                                                                   ON SPR.Work_Package = CC.Charge_Code
                                                            GROUP BY CC.Charge_Code ) StatsQ
                                                     WHERE StatsQ.SPR_Usage > 0 AND
                                                           StatsQ.Charge_Code = CC.Charge_Code ) );
   --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        RETURN QUERY
        SELECT 'DB Updated'::citext AS Charge_Code,
               format('Set Sample Prep Request usage to 0 for %s charge %s',
                      _updateCount, public.check_plural(_updateCount, 'code', 'codes'))::citext AS Usage_Comment,
               0 AS Sample_Prep_Usage_Old,
               0 AS Sample_Prep_Usage_New,
               0 AS Requested_Run_Usage_Old,
               0 AS Requested_Run_Usage_New,
               ''::citext AS WBS_Title,
               ''::citext AS Charge_Code_Title,
               ''::citext AS Sub_Account_Title,
               null::timestamp AS Setup_Date;
    End If;

    -- Look for Charge Codes with a non-zero requested run usage value, but are no longer associated with a requested run
    --
    UPDATE T_Charge_Code Target
    SET Usage_Requested_Run = 0
    WHERE Target.Usage_Requested_Run > 0 AND
          Target.Charge_Code IN ( SELECT CC.Charge_Code
                                  FROM T_Charge_Code CC
                                  WHERE Usage_Requested_Run > 0 AND
                                        NOT EXISTS ( SELECT 1
                                                     FROM ( SELECT CC.Charge_Code,
                                                                   COUNT(RR.request_id) AS RR_Usage
                                                            FROM T_Charge_Code CC
                                                                 INNER JOIN T_Requested_Run RR
                                                                   ON CC.Charge_Code = RR.Work_Package
                                                            GROUP BY CC.Charge_Code ) StatsQ
                                                     WHERE StatsQ.RR_Usage > 0 AND
                                                           StatsQ.Charge_Code = CC.Charge_Code ) );
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        RETURN QUERY
        SELECT 'DB Updated'::citext AS Charge_Code,
               format('Set Requested Run usage to 0 for %s charge %s',
                      _updateCount, public.check_plural(_updateCount, 'code', 'codes'))::citext AS Usage_Comment,
               0 AS Sample_Prep_Usage_Old,
               0 AS Sample_Prep_Usage_New,
               0 AS Requested_Run_Usage_Old,
               0 AS Requested_Run_Usage_New,
               ''::citext AS WBS_Title,
               ''::citext AS Charge_Code_Title,
               ''::citext AS Sub_Account_Title,
               null::timestamp AS Setup_Date;
    End If;

    -- Update sample prep request usage stats
    --
    UPDATE t_charge_code Target
    SET usage_sample_prep = SPR_Usage
    FROM ( SELECT CC.charge_code,
                  COUNT(SPR.prep_request_id) AS SPR_Usage
           FROM t_sample_prep_request SPR
               INNER JOIN t_charge_code CC
                   ON SPR.work_package = CC.charge_code
           GROUP BY CC.charge_code
          ) StatsQ
    WHERE Target.charge_code = StatsQ.charge_code AND
          Coalesce(Target.usage_sample_prep, 0) <> StatsQ.SPR_Usage;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        RETURN QUERY
        SELECT 'DB Updated'::citext AS Charge_Code,
               format('Updated Sample Prep Usage stats for %s charge %s',
                      _updateCount, public.check_plural(_updateCount, 'code', 'codes'))::citext AS Usage_Comment,
               0 AS Sample_Prep_Usage_Old,
               0 AS Sample_Prep_Usage_New,
               0 AS Requested_Run_Usage_Old,
               0 AS Requested_Run_Usage_New,
               ''::citext AS WBS_Title,
               ''::citext AS Charge_Code_Title,
               ''::citext AS Sub_Account_Title,
               null::timestamp AS Setup_Date;
    Else
        RETURN QUERY
        SELECT 'Stats already up-to-date'::citext AS Charge_Code,
               'Sample Prep Usage stats are already up-to-date'::citext AS Usage_Comment,
               0 AS Sample_Prep_Usage_Old,
               0 AS Sample_Prep_Usage_New,
               0 AS Requested_Run_Usage_Old,
               0 AS Requested_Run_Usage_New,
               ''::citext AS WBS_Title,
               ''::citext AS Charge_Code_Title,
               ''::citext AS Sub_Account_Title,
               null::timestamp AS Setup_Date;
    End If;

    -- Update requested run usage stats
    --
    UPDATE t_charge_code Target
    SET usage_requested_run = RR_Usage
    FROM ( SELECT CC.charge_code,
                   COUNT(RR.request_id) AS RR_Usage
           FROM t_charge_code CC
               INNER JOIN t_requested_run RR
                   ON CC.Charge_Code = RR.work_package
           GROUP BY CC.Charge_Code
          ) StatsQ
    WHERE Target.Charge_Code = StatsQ.Charge_Code AND
          Coalesce(Target.Usage_Requested_Run, 0) <> StatsQ.RR_Usage;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        RETURN QUERY
        SELECT 'DB Updated'::citext AS Charge_Code,
               format('Updated Requested Run Usage stats for %s charge %s',
                      _updateCount, public.check_plural(_updateCount, 'code', 'codes'))::citext AS Usage_Comment,
               0 AS Sample_Prep_Usage_Old,
               0 AS Sample_Prep_Usage_New,
               0 AS Requested_Run_Usage_Old,
               0 AS Requested_Run_Usage_New,
               ''::citext AS WBS_Title,
               ''::citext AS Charge_Code_Title,
               ''::citext AS Sub_Account_Title,
               null::timestamp AS Setup_Date;
    Else
        RETURN QUERY
        SELECT 'Stats already up-to-date'::citext AS Charge_Code,
               'Requested Run Usage stats are already up-to-date'::citext AS Usage_Comment,
               0 AS Sample_Prep_Usage_Old,
               0 AS Sample_Prep_Usage_New,
               0 AS Requested_Run_Usage_Old,
               0 AS Requested_Run_Usage_New,
               ''::citext AS WBS_Title,
               ''::citext AS Charge_Code_Title,
               ''::citext AS Sub_Account_Title,
               null::timestamp AS Setup_Date;
    End If;

END
$$;


ALTER FUNCTION public.update_charge_code_usage(_infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION update_charge_code_usage(_infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.update_charge_code_usage(_infoonly boolean) IS 'UpdateChargeCodeUsage';

