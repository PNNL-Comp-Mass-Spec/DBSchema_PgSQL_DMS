--
-- Name: t_data_analysis_request_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request_updates (
    id integer NOT NULL,
    request_id integer NOT NULL,
    old_state_id smallint NOT NULL,
    new_state_id smallint NOT NULL,
    entered timestamp without time zone NOT NULL,
    entered_by public.citext NOT NULL
);


ALTER TABLE public.t_data_analysis_request_updates OWNER TO d3l243;

--
-- Name: t_data_analysis_request_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_data_analysis_request_updates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_data_analysis_request_updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_data_analysis_request_updates pk_t_data_analysis_request_updates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_updates
    ADD CONSTRAINT pk_t_data_analysis_request_updates PRIMARY KEY (id);

--
-- Name: TABLE t_data_analysis_request_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request_updates TO readaccess;

