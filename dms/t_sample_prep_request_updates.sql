--
-- Name: t_sample_prep_request_updates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_prep_request_updates (
    entry_id integer NOT NULL,
    request_id integer NOT NULL,
    system_account public.citext NOT NULL,
    date_of_change timestamp without time zone NOT NULL,
    beginning_state_id smallint NOT NULL,
    end_state_id smallint NOT NULL
);


ALTER TABLE public.t_sample_prep_request_updates OWNER TO d3l243;

--
-- Name: t_sample_prep_request_updates_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_sample_prep_request_updates ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_sample_prep_request_updates_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_sample_prep_request_updates pk_t_sample_prep_request_updates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request_updates
    ADD CONSTRAINT pk_t_sample_prep_request_updates PRIMARY KEY (entry_id);

--
-- Name: TABLE t_sample_prep_request_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_prep_request_updates TO readaccess;

