--
-- Name: v_archive_update_state_name_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_update_state_name_picklist AS
 SELECT t_dataset_archive_update_state_name.archive_update_state_id AS id,
    t_dataset_archive_update_state_name.archive_update_state AS name
   FROM public.t_dataset_archive_update_state_name;


ALTER TABLE public.v_archive_update_state_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_archive_update_state_name_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_update_state_name_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_archive_update_state_name_picklist TO writeaccess;

