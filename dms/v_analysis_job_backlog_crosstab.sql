--
-- Name: v_analysis_job_backlog_crosstab; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_backlog_crosstab AS
 SELECT posting_time,
    sum("MSGFPlus") AS "MSGFPlus",
    sum("MSGFPlus_SplitFASTA") AS "MSGFPlus_SplitFASTA",
    sum("Decon2LS_V2") AS "Decon2LS_V2",
    sum("DiaNN") AS "DiaNN",
    sum("MASIC_Finnigan") AS "MASIC_Finnigan",
    sum("MaxQuant") AS "MaxQuant",
    sum("FragPipe") AS "FragPipe",
    sum("MSFragger") AS "MSFragger",
    sum("MSAlign") AS "MSAlign",
    sum("MSPathFinder") AS "MSPathFinder",
    sum("TopPIC") AS "TopPIC",
    sum("MAC_iTRAQ") AS "MAC_iTRAQ",
    sum("MSXML_Gen") AS "MSXML_Gen"
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
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'DiaNN'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "DiaNN",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MASIC_Finnigan'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MASIC_Finnigan",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'MaxQuant'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "MaxQuant",
                CASE
                    WHEN (v_analysis_job_backlog_history.analysis_tool OPERATOR(public.=) 'FragPipe'::public.citext) THEN v_analysis_job_backlog_history.backlog_count
                    ELSE (0)::bigint
                END AS "FragPipe",
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
  GROUP BY posting_time;


ALTER VIEW public.v_analysis_job_backlog_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_backlog_crosstab; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_backlog_crosstab TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_backlog_crosstab TO writeaccess;

