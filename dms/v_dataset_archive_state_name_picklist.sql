--
-- Name: v_dataset_archive_state_name_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_archive_state_name_picklist AS
 SELECT archive_state_id AS id,
    archive_state AS name
   FROM public.t_dataset_archive_state_name dasn;


ALTER VIEW public.v_dataset_archive_state_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_dataset_archive_state_name_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_archive_state_name_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_archive_state_name_picklist TO writeaccess;

