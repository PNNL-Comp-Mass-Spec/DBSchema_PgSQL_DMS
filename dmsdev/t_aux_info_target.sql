--
-- Name: t_aux_info_target; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_target (
    target_type_id integer NOT NULL,
    target_type_name public.citext,
    target_table public.citext,
    target_id_col public.citext,
    target_name_col public.citext
);


ALTER TABLE public.t_aux_info_target OWNER TO d3l243;

--
-- Name: t_aux_info_target_target_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_aux_info_target ALTER COLUMN target_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_aux_info_target_target_type_id_seq
    START WITH 500
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_aux_info_target pk_t_aux_info_target; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_target
    ADD CONSTRAINT pk_t_aux_info_target PRIMARY KEY (target_type_id);

--
-- Name: TABLE t_aux_info_target; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_target TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_aux_info_target TO writeaccess;

