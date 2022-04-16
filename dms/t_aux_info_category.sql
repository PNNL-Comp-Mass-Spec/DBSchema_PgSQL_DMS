--
-- Name: t_aux_info_category; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_category (
    aux_category_id integer NOT NULL,
    aux_category public.citext,
    target_type_id integer,
    sequence smallint NOT NULL
);


ALTER TABLE public.t_aux_info_category OWNER TO d3l243;

--
-- Name: TABLE t_aux_info_category; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_category TO readaccess;

