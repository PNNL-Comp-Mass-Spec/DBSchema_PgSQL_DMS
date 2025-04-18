--
-- Name: t_filter_sets; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_sets (
    filter_set_id integer NOT NULL,
    filter_type_id integer NOT NULL,
    filter_set_name public.citext NOT NULL,
    filter_set_description public.citext DEFAULT ''::public.citext NOT NULL,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_modified timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_filter_sets OWNER TO d3l243;

--
-- Name: t_filter_sets_filter_set_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_filter_sets ALTER COLUMN filter_set_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_filter_sets_filter_set_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_filter_sets pk_t_filter_sets; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_filter_sets
    ADD CONSTRAINT pk_t_filter_sets PRIMARY KEY (filter_set_id);

ALTER TABLE public.t_filter_sets CLUSTER ON pk_t_filter_sets;

--
-- Name: t_filter_sets fk_t_filter_sets_t_filter_set_types; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_filter_sets
    ADD CONSTRAINT fk_t_filter_sets_t_filter_set_types FOREIGN KEY (filter_type_id) REFERENCES public.t_filter_set_types(filter_type_id);

--
-- Name: TABLE t_filter_sets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_sets TO readaccess;
GRANT SELECT ON TABLE public.t_filter_sets TO writeaccess;

