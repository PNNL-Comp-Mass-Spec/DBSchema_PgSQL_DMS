--
-- Name: t_instrument_group_allowed_ds_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_group_allowed_ds_type (
    instrument_group public.citext NOT NULL,
    dataset_type public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_instrument_group_allowed_ds_type OWNER TO d3l243;

--
-- Name: t_instrument_group_allowed_ds_type pk_t_instrument_group_allowed_ds_type; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_group_allowed_ds_type
    ADD CONSTRAINT pk_t_instrument_group_allowed_ds_type PRIMARY KEY (instrument_group, dataset_type);

--
-- Name: TABLE t_instrument_group_allowed_ds_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_group_allowed_ds_type TO readaccess;

