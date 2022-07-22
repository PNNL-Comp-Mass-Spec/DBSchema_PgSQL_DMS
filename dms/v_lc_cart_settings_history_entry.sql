--
-- Name: v_lc_cart_settings_history_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_settings_history_entry AS
 SELECT to_char(csh.date_of_change, 'yyyy-mm-dd'::text) AS date_of_change,
    csh.entry_id AS id,
    csh.valve_to_column_extension,
    csh.valve_to_column_extension_dimensions,
    csh.operating_pressure,
    csh.interface_configuration,
    csh.mixer_volume,
    csh.sample_loop_volume,
    csh.sample_loading_time,
    csh.split_flow_rate,
    csh.split_column_dimensions,
    csh.purge_flow_rate,
    csh.purge_column_dimensions,
    csh.purge_volume,
    csh.acquisition_time,
    csh.comment,
    lccart.cart_name,
    csh.entered,
    csh.entered_by,
    csh.solvent_a,
    csh.solvent_b
   FROM (public.t_lc_cart_settings_history csh
     JOIN public.t_lc_cart lccart ON ((csh.cart_id = lccart.cart_id)));


ALTER TABLE public.v_lc_cart_settings_history_entry OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_settings_history_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_settings_history_entry TO readaccess;

