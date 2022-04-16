--
-- Name: t_aux_info_subcategory; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_subcategory (
    aux_subcategory_id integer NOT NULL,
    aux_subcategory public.citext,
    parent_id integer,
    sequence smallint NOT NULL
);


ALTER TABLE public.t_aux_info_subcategory OWNER TO d3l243;

--
-- Name: TABLE t_aux_info_subcategory; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_subcategory TO readaccess;

