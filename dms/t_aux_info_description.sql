--
-- Name: t_aux_info_description; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_description (
    aux_description_id integer NOT NULL,
    aux_description public.citext NOT NULL,
    parent_id integer,
    sequence smallint NOT NULL,
    data_size integer NOT NULL,
    helper_append character(1) NOT NULL,
    active character(1) NOT NULL
);


ALTER TABLE public.t_aux_info_description OWNER TO d3l243;

--
-- Name: TABLE t_aux_info_description; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_description TO readaccess;

