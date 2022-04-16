--
-- Name: t_lc_column_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_column_state_name (
    column_state_id integer NOT NULL,
    column_state public.citext NOT NULL
);


ALTER TABLE public.t_lc_column_state_name OWNER TO d3l243;

--
-- Name: TABLE t_lc_column_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_column_state_name TO readaccess;

