--
-- Name: t_instrument_group_allowed_ds_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_group_allowed_ds_type (
    instrument_group public.citext NOT NULL,
    dataset_type public.citext NOT NULL,
    comment public.citext DEFAULT ''::public.citext,
    dataset_usage_count integer DEFAULT 0,
    dataset_usage_last_year integer DEFAULT 0
);


ALTER TABLE public.t_instrument_group_allowed_ds_type OWNER TO d3l243;

--
-- Name: t_instrument_group_allowed_ds_type pk_t_instrument_group_allowed_ds_type; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_group_allowed_ds_type
    ADD CONSTRAINT pk_t_instrument_group_allowed_ds_type PRIMARY KEY (instrument_group, dataset_type);

--
-- Name: t_instrument_group_allowed_ds_type fk_t_instrument_group_allowed_ds_type_t_dataset_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_group_allowed_ds_type
    ADD CONSTRAINT fk_t_instrument_group_allowed_ds_type_t_dataset_type_name FOREIGN KEY (dataset_type) REFERENCES public.t_dataset_type_name(dataset_type) ON UPDATE CASCADE;

--
-- Name: t_instrument_group_allowed_ds_type fk_t_instrument_group_allowed_ds_type_t_instrument_group_in; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_group_allowed_ds_type
    ADD CONSTRAINT fk_t_instrument_group_allowed_ds_type_t_instrument_group_in FOREIGN KEY (instrument_group) REFERENCES public.t_instrument_group(instrument_group) ON UPDATE CASCADE;

--
-- Name: TABLE t_instrument_group_allowed_ds_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_group_allowed_ds_type TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_instrument_group_allowed_ds_type TO writeaccess;

