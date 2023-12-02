--
-- Name: v_analysis_job_backlog_crosstab; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_backlog_crosstab AS
 SELECT pivotq.posting_time,
    sum(pivotq."MSGFPlus") AS "MSGFPlus",
    sum(pivotq."MSGFPlus_SplitFASTA") AS "MSGFPlus_SplitFASTA",
    sum(pivotq."Decon2LS_V2") AS "Decon2LS_V2",
    sum(pivotq."MASIC_Finnigan") AS "MASIC_Finnigan",
    sum(pivotq."MaxQuant") AS "MaxQuant",
    sum(pivotq."MSFragger") AS "MSFragger",
    sum(pivotq."MSAlign") AS "MSAlign",
    sum(pivotq."MSPathFinder") AS "MSPathFinder",
    sum(pivotq."TopPIC") AS "TopPIC",
    sum(pivotq."MAC_iTRAQ") AS "MAC_iTRAQ",
    sum(pivotq."MSXML_Gen") AS "MSXML_Gen"
   FROM ( SELECT date_trunc('minute'::text, v_analysis_job_backlog_history.posting_time) AS posting_time,
                CASE
                    WHEN ((v_analysis_job_backlog_history.analysis_tool OPERATOR(public.~~) 'MSGFPlus%'::public.citext) AND (NOT (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.~~) '%SplitFasta%'::public.citext))) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MSGFPlus",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.~~) 'MSGFPlus%SplitFasta%'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MSGFPlus_SplitFASTA",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'Decon2LS_V2'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "Decon2LS_V2",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MASIC_Finnigan'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MASIC_Finnigan",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MaxQuant'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MaxQuant",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MSFragger'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MSFragger",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MSAlign'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MSAlign",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MSPathFinder'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MSPathFinder",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'TopPIC'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "TopPIC",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MAC_iTRAQ'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MAC_iTRAQ",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MSXML_Gen'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MSXML_Gen"
           FROM public.v_analysis_job_backlog_history) pivotq
  GROUP BY pivotq.posting_time;


ALTER VIEW public.v_analysis_job_backlog_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_backlog_crosstab; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_backlog_crosstab TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_backlog_crosstab TO writeaccess;

