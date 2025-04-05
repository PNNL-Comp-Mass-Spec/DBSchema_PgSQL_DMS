--
-- Name: t_filter_set_criteria_names; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_criteria_names (
    criterion_id integer NOT NULL,
    criterion_name public.citext NOT NULL,
    criterion_description public.citext
);


ALTER TABLE public.t_filter_set_criteria_names OWNER TO d3l243;

--
-- Name: t_filter_set_criteria_names_criterion_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_filter_set_criteria_names ALTER COLUMN criterion_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_filter_set_criteria_names_criterion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_filter_set_criteria_names pk_t_filter_set_criteria_names; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_filter_set_criteria_names
    ADD CONSTRAINT pk_t_filter_set_criteria_names PRIMARY KEY (criterion_id);

ALTER TABLE public.t_filter_set_criteria_names CLUSTER ON pk_t_filter_set_criteria_names;

--
-- Name: TABLE t_filter_set_criteria_names; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_criteria_names TO readaccess;
GRANT SELECT ON TABLE public.t_filter_set_criteria_names TO writeaccess;

