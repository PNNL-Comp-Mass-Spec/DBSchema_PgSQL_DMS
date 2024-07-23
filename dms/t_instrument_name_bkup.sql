--
-- Name: t_instrument_name_bkup; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_name_bkup (
    instrument_id integer NOT NULL,
    instrument public.citext,
    instrument_class public.citext,
    instrument_group public.citext,
    source_path_id integer,
    storage_path_id integer,
    capture_method public.citext,
    status public.citext,
    room_number public.citext,
    description public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_instrument_name_bkup OWNER TO d3l243;

--
-- Name: t_instrument_name_bkup pk_t_instrument_name_bkup; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_name_bkup
    ADD CONSTRAINT pk_t_instrument_name_bkup PRIMARY KEY (instrument_id);

--
-- Name: TABLE t_instrument_name_bkup; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_name_bkup TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_instrument_name_bkup TO writeaccess;

