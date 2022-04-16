--
-- Name: t_dim_error_solution; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dim_error_solution (
    error_text public.citext NOT NULL,
    solution public.citext NOT NULL
);


ALTER TABLE public.t_dim_error_solution OWNER TO d3l243;

--
-- Name: TABLE t_dim_error_solution; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dim_error_solution TO readaccess;

