--
-- Name: t_aux_info_description; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_description (
    aux_description_id integer NOT NULL,
    aux_description public.citext NOT NULL,
    parent_id integer,
    sequence smallint DEFAULT 0 NOT NULL,
    data_size integer DEFAULT 64 NOT NULL,
    helper_append character(1) DEFAULT 'N'::bpchar NOT NULL,
    active character(1) DEFAULT 'Y'::bpchar NOT NULL
);


ALTER TABLE public.t_aux_info_description OWNER TO d3l243;

--
-- Name: t_aux_info_description_aux_description_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_aux_info_description ALTER COLUMN aux_description_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_aux_info_description_aux_description_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_aux_info_description pk_t_aux_info_description; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_description
    ADD CONSTRAINT pk_t_aux_info_description PRIMARY KEY (aux_description_id);

--
-- Name: TABLE t_aux_info_description; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_description TO readaccess;

