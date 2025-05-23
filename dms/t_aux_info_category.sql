--
-- Name: t_aux_info_category; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_category (
    aux_category_id integer NOT NULL,
    aux_category public.citext,
    target_type_id integer,
    sequence smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.t_aux_info_category OWNER TO d3l243;

--
-- Name: t_aux_info_category_aux_category_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_aux_info_category ALTER COLUMN aux_category_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_aux_info_category_aux_category_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_aux_info_category pk_t_aux_info_category; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_category
    ADD CONSTRAINT pk_t_aux_info_category PRIMARY KEY (aux_category_id);

ALTER TABLE public.t_aux_info_category CLUSTER ON pk_t_aux_info_category;

--
-- Name: t_aux_info_category fk_t_aux_info_category_t_aux_info_target; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_category
    ADD CONSTRAINT fk_t_aux_info_category_t_aux_info_target FOREIGN KEY (target_type_id) REFERENCES public.t_aux_info_target(target_type_id);

--
-- Name: TABLE t_aux_info_category; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_category TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_aux_info_category TO writeaccess;

