--
-- Name: v_procedures; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_procedures AS
 SELECT routine_catalog,
    routine_schema,
    routine_name,
    routine_type,
    data_type,
    type_udt_catalog,
    type_udt_schema,
    type_udt_name,
    specific_catalog,
    specific_schema,
    specific_name,
    routine_body,
    routine_definition,
    external_name,
    external_language,
    parameter_style,
    is_deterministic,
    sql_data_access,
    is_null_call,
    schema_level_routine,
    max_dynamic_result_sets,
    security_type,
    as_locator,
    is_udt_dependent
   FROM information_schema.routines
  WHERE ((NOT ((specific_schema)::name = 'pg_catalog'::name)) AND (NOT ((routine_name)::name ~~ '_pg_%'::text)) AND (NOT ((routine_name)::name ~~ 'citext%'::text)) AND (NOT ((routine_name)::name ~~ 'pg_qualstats%'::text)) AND (NOT ((routine_name)::name ~~ 'pg_stat_kcache%'::text)) AND (NOT ((routine_name)::name ~~ 'pg_stat_statements%'::text)) AND (NOT ((routine_name)::name ~~ 'pgp_%'::text)) AND (NOT ((routine_name)::name ~~ 'pgstat%'::text)) AND (NOT ((routine_name)::name ~~ 'postgres_fdw_%'::text)) AND (NOT ((routine_name)::name ~~ 'regexp%'::text)) AND (NOT ((routine_name)::name ~~ 'tds_fdw_%'::text)) AND (NOT ((routine_name)::name ~~ 'textic%'::text)) AND (NOT ((routine_name)::name = ANY (ARRAY['armor'::name, 'cleanup_tables'::name, 'connectby'::name, 'crosstab'::name, 'crosstab2'::name, 'crosstab3'::name, 'crosstab4'::name, 'crypt'::name, 'dearmor'::name, 'decrypt'::name, 'decrypt_iv'::name, 'digest'::name, 'encrypt'::name, 'encrypt_iv'::name, 'gen_random_bytes'::name, 'gen_random_uuid'::name, 'gen_salt'::name, 'get_active_workers'::name, 'get_heap_fillfactor'::name, 'get_heap_freespace'::name, 'hmac'::name, 'max'::name, 'min'::name, 'normal_rand'::name, 'pg_relpages'::name, 'replace'::name, 'split_part'::name, 'squeeze_table'::name, 'strpos'::name, 'tables_internal_trig_func'::name, 'translate'::name]))));


ALTER VIEW public.v_procedures OWNER TO d3l243;

--
-- Name: TABLE v_procedures; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_procedures TO readaccess;
GRANT SELECT ON TABLE public.v_procedures TO writeaccess;

