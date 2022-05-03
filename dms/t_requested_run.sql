--
-- Name: t_requested_run; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_requested_run (
    request_id integer NOT NULL,
    request_name public.citext NOT NULL,
    requester_prn public.citext NOT NULL,
    comment public.citext,
    created timestamp without time zone NOT NULL,
    instrument_group public.citext,
    request_type_id integer,
    instrument_setting public.citext,
    special_instructions public.citext,
    wellplate public.citext,
    well public.citext,
    priority smallint,
    note public.citext,
    exp_id integer NOT NULL,
    request_run_start timestamp without time zone,
    request_run_finish timestamp without time zone,
    request_internal_standard public.citext,
    work_package public.citext,
    batch_id integer NOT NULL,
    blocking_factor public.citext,
    block integer,
    run_order integer,
    eus_proposal_id public.citext,
    eus_usage_type_id smallint NOT NULL,
    cart_id integer NOT NULL,
    cart_config_id integer,
    cart_column smallint,
    separation_group public.citext,
    mrm_attachment integer,
    dataset_id integer,
    origin public.citext NOT NULL,
    state_name public.citext NOT NULL,
    request_name_code public.citext,
    vialing_conc public.citext,
    vialing_vol public.citext,
    location_id integer,
    queue_state smallint NOT NULL,
    queue_instrument_id integer,
    queue_date timestamp without time zone,
    entered timestamp without time zone,
    updated timestamp without time zone
);


ALTER TABLE public.t_requested_run OWNER TO d3l243;

--
-- Name: t_requested_run pk_t_requested_run; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_requested_run
    ADD CONSTRAINT pk_t_requested_run PRIMARY KEY (request_id);

--
-- Name: TABLE t_requested_run; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_requested_run TO readaccess;

