--
-- Name: t_aux_info_subcategory; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_subcategory (
    aux_subcategory_id integer NOT NULL,
    aux_subcategory public.citext,
    aux_category_id integer,
    sequence smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.t_aux_info_subcategory OWNER TO d3l243;

--
-- Name: t_aux_info_subcategory_aux_subcategory_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_aux_info_subcategory ALTER COLUMN aux_subcategory_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_aux_info_subcategory_aux_subcategory_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_aux_info_subcategory pk_t_aux_info_subcategory; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_subcategory
    ADD CONSTRAINT pk_t_aux_info_subcategory PRIMARY KEY (aux_subcategory_id);

ALTER TABLE public.t_aux_info_subcategory CLUSTER ON pk_t_aux_info_subcategory;

--
-- Name: t_aux_info_subcategory fk_t_aux_info_subcategory_t_aux_info_category; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_subcategory
    ADD CONSTRAINT fk_t_aux_info_subcategory_t_aux_info_category FOREIGN KEY (aux_category_id) REFERENCES public.t_aux_info_category(aux_category_id);

--
-- Name: TABLE t_aux_info_subcategory; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_subcategory TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_aux_info_subcategory TO writeaccess;

