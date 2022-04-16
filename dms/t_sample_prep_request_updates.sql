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
-- Name: TABLE t_sample_prep_request_updates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_prep_request_updates TO readaccess;

