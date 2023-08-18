--
-- Name: v_data_package_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_package_picklist AS
 SELECT v_data_package_export.data_pkg_id AS id,
    v_data_package_export.name,
    (((v_data_package_export.id)::text || ': '::text) || (v_data_package_export.name)::text) AS id_with_name
   FROM dpkg.v_data_package_export;


ALTER TABLE public.v_data_package_picklist OWNER TO d3l243;

--
-- Name: TABLE v_data_package_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_package_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_data_package_picklist TO writeaccess;

