--
-- Name: v_table_index_duplicates; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_index_duplicates AS
 SELECT (pg_namespace.nspname)::public.citext AS table_schema,
    (pg_class.relname)::public.citext AS table_name,
    duplicateindexq.index_size_bytes,
    duplicateindexq.idx1,
    duplicateindexq.idx2,
    duplicateindexq.idx3,
    duplicateindexq.idx4
   FROM ((( SELECT min(sub.indrelid) AS indrelid_first,
            min((sub.idx)::oid) AS idx_first,
            sum(pg_relation_size(sub.idx)) AS index_size_bytes,
            (array_agg(sub.idx))[1] AS idx1,
            (array_agg(sub.idx))[2] AS idx2,
            (array_agg(sub.idx))[3] AS idx3,
            (array_agg(sub.idx))[4] AS idx4
           FROM ( SELECT pg_index.indrelid,
                    (pg_index.indexrelid)::regclass AS idx,
                    (((((((((pg_index.indrelid)::text || '
'::text) || (pg_index.indclass)::text) || '
'::text) || (pg_index.indkey)::text) || '
'::text) || COALESCE((pg_index.indexprs)::text, ''::text)) || '
'::text) || COALESCE((pg_index.indpred)::text, ''::text)) AS key
                   FROM pg_index) sub
          GROUP BY sub.key
         HAVING (count(*) > 1)) duplicateindexq
     LEFT JOIN pg_class ON ((pg_class.oid = duplicateindexq.indrelid_first)))
     LEFT JOIN pg_namespace ON ((pg_namespace.oid = pg_class.relnamespace)))
  ORDER BY duplicateindexq.index_size_bytes DESC;


ALTER VIEW public.v_table_index_duplicates OWNER TO d3l243;

--
-- Name: TABLE v_table_index_duplicates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_table_index_duplicates TO readaccess;
GRANT SELECT ON TABLE public.v_table_index_duplicates TO writeaccess;

