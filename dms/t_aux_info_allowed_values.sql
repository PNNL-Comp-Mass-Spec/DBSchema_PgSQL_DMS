--
-- Name: t_aux_info_allowed_values; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_allowed_values (
    aux_info_id integer NOT NULL,
    value public.citext NOT NULL
);


ALTER TABLE public.t_aux_info_allowed_values OWNER TO d3l243;

--
-- Name: TABLE t_aux_info_allowed_values; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_allowed_values TO readaccess;

