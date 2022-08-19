--
-- Name: v_run_assignment_wellplate_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_assignment_wellplate_list_report AS
 SELECT countq.wellplate,
    w.description,
    countq.scheduled,
    countq.requested
   FROM (( SELECT t_requested_run.wellplate,
            sum(
                CASE
                    WHEN (t_requested_run.priority > 0) THEN 1
                    ELSE 0
                END) AS scheduled,
            sum(
                CASE
                    WHEN (t_requested_run.priority = 0) THEN 1
                    ELSE 0
                END) AS requested
           FROM public.t_requested_run
          GROUP BY t_requested_run.wellplate) countq
     LEFT JOIN public.t_wellplates w ON ((countq.wellplate OPERATOR(public.=) w.wellplate)));


ALTER TABLE public.v_run_assignment_wellplate_list_report OWNER TO d3l243;

--
-- Name: TABLE v_run_assignment_wellplate_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_assignment_wellplate_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_run_assignment_wellplate_list_report TO writeaccess;

