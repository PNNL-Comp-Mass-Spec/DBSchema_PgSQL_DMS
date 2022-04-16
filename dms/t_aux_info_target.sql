--
-- Name: t_aux_info_target; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_target (
    aux_target_id integer NOT NULL,
    aux_target public.citext,
    target_table public.citext,
    target_id_col public.citext,
    target_name_col public.citext
);


ALTER TABLE public.t_aux_info_target OWNER TO d3l243;

--
-- Name: TABLE t_aux_info_target; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_target TO readaccess;

