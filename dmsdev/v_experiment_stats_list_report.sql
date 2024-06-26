--
-- Name: v_experiment_stats_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_stats_list_report AS
 SELECT year,
    month,
    experiments,
    researcher
   FROM ( SELECT EXTRACT(month FROM e.created) AS month,
            EXTRACT(year FROM e.created) AS year,
            count(e.exp_id) AS experiments,
            'Total'::public.citext AS researcher
           FROM public.t_experiments e
          GROUP BY (EXTRACT(month FROM e.created)), (EXTRACT(year FROM e.created))
        UNION
         SELECT EXTRACT(month FROM e.created) AS month,
            EXTRACT(year FROM e.created) AS year,
            count(e.exp_id) AS experiments,
            u.name AS researcher
           FROM (public.t_experiments e
             JOIN public.t_users u ON ((e.researcher_username OPERATOR(public.=) u.username)))
          GROUP BY (EXTRACT(month FROM e.created)), (EXTRACT(year FROM e.created)), u.name) countq
  ORDER BY year DESC, month DESC, experiments DESC;


ALTER VIEW public.v_experiment_stats_list_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_stats_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_stats_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_stats_list_report TO writeaccess;

