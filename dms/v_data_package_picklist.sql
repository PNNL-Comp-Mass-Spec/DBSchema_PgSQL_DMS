--
-- Name: v_data_package_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_package_picklist AS
 SELECT data_pkg_id AS id,
    package_name AS name,
    (((data_pkg_id || (': '::public.citext)::text) || (package_name)::text))::public.citext AS id_with_name
   FROM dpkg.t_data_package dp;


ALTER VIEW public.v_data_package_picklist OWNER TO d3l243;

--
-- Name: VIEW v_data_package_picklist; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_data_package_picklist IS 'Used by chooser "data_package_list"; see https://dmsdev.pnl.gov/config_db/edit_table/dms_chooser.db/chooser_definitions';

--
-- Name: TABLE v_data_package_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_package_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_data_package_picklist TO writeaccess;

