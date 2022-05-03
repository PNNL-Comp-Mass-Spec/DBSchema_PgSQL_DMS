--
-- Name: t_filter_set_criteria; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_criteria (
    filter_set_criteria_id integer NOT NULL,
    filter_criteria_group_id integer NOT NULL,
    criterion_id integer NOT NULL,
    criterion_comparison character(2) NOT NULL,
    criterion_value double precision NOT NULL
);


ALTER TABLE public.t_filter_set_criteria OWNER TO d3l243;

--
-- Name: t_filter_set_criteria_filter_set_criteria_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_filter_set_criteria ALTER COLUMN filter_set_criteria_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_filter_set_criteria_filter_set_criteria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_filter_set_criteria pk_t_filter_set_criteria; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_filter_set_criteria
    ADD CONSTRAINT pk_t_filter_set_criteria PRIMARY KEY (filter_set_criteria_id);

--
-- Name: TABLE t_filter_set_criteria; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_criteria TO readaccess;

