--
-- Name: v_experiment_date; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_date AS
 SELECT experiment,
    EXTRACT(year FROM created) AS year,
    EXTRACT(month FROM created) AS month,
    EXTRACT(day FROM created) AS day
   FROM public.t_experiments;


ALTER VIEW public.v_experiment_date OWNER TO d3l243;

--
-- Name: TABLE v_experiment_date; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_date TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_date TO writeaccess;

