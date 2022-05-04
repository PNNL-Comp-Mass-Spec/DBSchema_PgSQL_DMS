--
-- Name: t_lc_cart_settings_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_cart_settings_history (
    entry_id integer NOT NULL,
    cart_id integer NOT NULL,
    valve_to_column_extension public.citext,
    operating_pressure public.citext,
    interface_configuration public.citext,
    valve_to_column_extension_dimensions public.citext,
    mixer_volume public.citext,
    sample_loop_volume public.citext,
    sample_loading_time public.citext,
    split_flow_rate public.citext,
    split_column_dimensions public.citext,
    purge_flow_rate public.citext,
    purge_column_dimensions public.citext,
    purge_volume public.citext,
    acquisition_time public.citext,
    solvent_a public.citext,
    solvent_b public.citext,
    comment public.citext,
    date_of_change timestamp without time zone,
    entered timestamp without time zone NOT NULL,
    entered_by public.citext
);


ALTER TABLE public.t_lc_cart_settings_history OWNER TO d3l243;

--
-- Name: t_lc_cart_settings_history_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_lc_cart_settings_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_lc_cart_settings_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_lc_cart_settings_history pk_t_lc_cart_settings; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart_settings_history
    ADD CONSTRAINT pk_t_lc_cart_settings PRIMARY KEY (entry_id);

--
-- Name: t_lc_cart_settings_history fk_t_lc_cart_settings_history_t_lc_cart; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart_settings_history
    ADD CONSTRAINT fk_t_lc_cart_settings_history_t_lc_cart FOREIGN KEY (cart_id) REFERENCES public.t_lc_cart(cart_id);

--
-- Name: TABLE t_lc_cart_settings_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_cart_settings_history TO readaccess;

