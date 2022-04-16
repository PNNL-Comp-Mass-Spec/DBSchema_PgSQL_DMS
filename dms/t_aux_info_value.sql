--
-- Name: t_aux_info_value; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_value (
    aux_info_id integer NOT NULL,
    value public.citext,
    target_id integer NOT NULL
);


ALTER TABLE public.t_aux_info_value OWNER TO d3l243;

--
-- Name: TABLE t_aux_info_value; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_value TO readaccess;

