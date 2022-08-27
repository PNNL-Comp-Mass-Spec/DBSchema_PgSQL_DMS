--
-- Name: v_log_errors_production_dbs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_log_errors_production_dbs AS
 SELECT 'DMS_Capture'::text AS db,
    v_log_errors.entry_id,
    v_log_errors.posted_by,
    v_log_errors.entered,
    v_log_errors.type,
    v_log_errors.message,
    v_log_errors.entered_by
   FROM cap.v_log_errors
UNION
 SELECT 'DMS5'::text AS db,
    v_log_errors.entry_id,
    v_log_errors.posted_by,
    v_log_errors.entered,
    v_log_errors.type,
    v_log_errors.message,
    v_log_errors.entered_by
   FROM public.v_log_errors
UNION
 SELECT 'DMS_Pipeline'::text AS db,
    v_log_errors.entry_id,
    v_log_errors.posted_by,
    v_log_errors.entered,
    v_log_errors.type,
    v_log_errors.message,
    v_log_errors.entered_by
   FROM sw.v_log_errors
UNION
 SELECT 'DMS_Data_Package'::text AS db,
    v_log_errors.entry_id,
    v_log_errors.posted_by,
    v_log_errors.entered,
    v_log_errors.type,
    v_log_errors.message,
    v_log_errors.entered_by
   FROM dpkg.v_log_errors;


ALTER TABLE public.v_log_errors_production_dbs OWNER TO d3l243;

--
-- Name: TABLE v_log_errors_production_dbs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_log_errors_production_dbs TO readaccess;
GRANT SELECT ON TABLE public.v_log_errors_production_dbs TO writeaccess;

