--
-- Name: v_lc_cart_settings_history_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_settings_history_detail_report AS
 SELECT csh.entry_id AS id,
    lccart.cart_name AS cart,
    csh.date_of_change,
    csh.entered,
    csh.entered_by,
    csh.valve_to_column_extension,
    csh.valve_to_column_extension_dimensions,
    csh.interface_configuration,
    csh.operating_pressure,
    csh.mixer_volume,
    csh.sample_loop_volume,
    csh.sample_loading_time,
    csh.split_flow_rate,
    csh.split_column_dimensions,
    csh.purge_flow_rate,
    csh.purge_volume,
    csh.purge_column_dimensions,
    csh.acquisition_time,
    csh.solvent_a,
    csh.solvent_b,
    csh.comment
   FROM (public.t_lc_cart_settings_history csh
     JOIN public.t_lc_cart lccart ON ((csh.cart_id = lccart.cart_id)));


ALTER TABLE public.v_lc_cart_settings_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_settings_history_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_settings_history_detail_report TO readaccess;

