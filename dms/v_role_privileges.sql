--
-- Name: v_role_privileges; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_role_privileges AS
 WITH rol AS (
         SELECT pg_roles.oid,
            (pg_roles.rolname)::text AS role_name
           FROM pg_roles
        UNION
         SELECT (0)::oid AS oid,
            'public'::text AS text
        ), schemas AS (
         SELECT n.oid AS schema_oid,
            (n.nspname)::text AS schema_name,
            n.nspowner AS owner_oid,
            'schema'::text AS object_type,
            COALESCE(n.nspacl, acldefault('n'::"char", n.nspowner)) AS acl
           FROM pg_namespace n
          WHERE ((n.nspname !~ '^pg_'::text) AND (n.nspname <> 'information_schema'::name))
        ), classes AS (
         SELECT schemas.schema_oid,
            schemas.schema_name AS object_schema,
            c.oid,
            (c.relname)::text AS object_name,
            c.relowner AS owner_oid,
                CASE
                    WHEN (c.relkind = 'r'::"char") THEN 'table'::text
                    WHEN (c.relkind = 'v'::"char") THEN 'view'::text
                    WHEN (c.relkind = 'm'::"char") THEN 'materialized view'::text
                    WHEN (c.relkind = 'c'::"char") THEN 'type'::text
                    WHEN (c.relkind = 'i'::"char") THEN 'index'::text
                    WHEN (c.relkind = 'S'::"char") THEN 'sequence'::text
                    WHEN (c.relkind = 's'::"char") THEN 'special'::text
                    WHEN (c.relkind = 't'::"char") THEN 'TOAST table'::text
                    WHEN (c.relkind = 'f'::"char") THEN 'foreign table'::text
                    WHEN (c.relkind = 'p'::"char") THEN 'partitioned table'::text
                    WHEN (c.relkind = 'I'::"char") THEN 'partitioned index'::text
                    ELSE (c.relkind)::text
                END AS object_type,
                CASE
                    WHEN (c.relkind = 'S'::"char") THEN COALESCE(c.relacl, acldefault('s'::"char", c.relowner))
                    ELSE COALESCE(c.relacl, acldefault('r'::"char", c.relowner))
                END AS acl
           FROM (pg_class c
             JOIN schemas ON ((schemas.schema_oid = c.relnamespace)))
          WHERE (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'S'::"char", 'f'::"char", 'p'::"char"]))
        ), cols AS (
         SELECT c.object_schema,
            NULL::integer AS oid,
            ((c.object_name || '.'::text) || (a.attname)::text) AS object_name,
            'column'::text AS object_type,
            c.owner_oid,
            COALESCE(a.attacl, acldefault('c'::"char", c.owner_oid)) AS acl
           FROM (pg_attribute a
             JOIN classes c ON ((a.attrelid = c.oid)))
          WHERE ((a.attnum > 0) AND (NOT a.attisdropped))
        ), procs AS (
         SELECT schemas.schema_oid,
            schemas.schema_name AS object_schema,
            p.oid,
            (p.proname)::text AS object_name,
            p.proowner AS owner_oid,
                CASE p.prokind
                    WHEN 'a'::"char" THEN 'aggregate'::text
                    WHEN 'w'::"char" THEN 'window'::text
                    WHEN 'p'::"char" THEN 'procedure'::text
                    ELSE 'function'::text
                END AS object_type,
            pg_get_function_arguments(p.oid) AS calling_arguments,
            COALESCE(p.proacl, acldefault('f'::"char", p.proowner)) AS acl
           FROM (pg_proc p
             JOIN schemas ON ((schemas.schema_oid = p.pronamespace)))
        ), udts AS (
         SELECT schemas.schema_oid,
            schemas.schema_name AS object_schema,
            t.oid,
            (t.typname)::text AS object_name,
            t.typowner AS owner_oid,
                CASE t.typtype
                    WHEN 'b'::"char" THEN 'base type'::text
                    WHEN 'c'::"char" THEN 'composite type'::text
                    WHEN 'd'::"char" THEN 'domain'::text
                    WHEN 'e'::"char" THEN 'enum type'::text
                    WHEN 't'::"char" THEN 'pseudo-type'::text
                    WHEN 'r'::"char" THEN 'range type'::text
                    WHEN 'm'::"char" THEN 'multirange'::text
                    ELSE (t.typtype)::text
                END AS object_type,
            COALESCE(t.typacl, acldefault('T'::"char", t.typowner)) AS acl
           FROM (pg_type t
             JOIN schemas ON ((schemas.schema_oid = t.typnamespace)))
          WHERE (((t.typrelid = (0)::oid) OR ( SELECT (c.relkind = 'c'::"char")
                   FROM pg_class c
                  WHERE (c.oid = t.typrelid))) AND (NOT (EXISTS ( SELECT 1
                   FROM pg_type el
                  WHERE ((el.oid = t.typelem) AND (el.typarray = t.oid))))))
        ), fdws AS (
         SELECT NULL::oid AS schema_oid,
            NULL::text AS object_schema,
            p.oid,
            (p.fdwname)::text AS object_name,
            p.fdwowner AS owner_oid,
            'foreign data wrapper'::text AS object_type,
            COALESCE(p.fdwacl, acldefault('F'::"char", p.fdwowner)) AS acl
           FROM pg_foreign_data_wrapper p
        ), fsrvs AS (
         SELECT NULL::oid AS schema_oid,
            NULL::text AS object_schema,
            p.oid,
            (p.srvname)::text AS object_name,
            p.srvowner AS owner_oid,
            'foreign server'::text AS object_type,
            COALESCE(p.srvacl, acldefault('S'::"char", p.srvowner)) AS acl
           FROM pg_foreign_server p
        ), all_objects AS (
         SELECT schemas.schema_name AS object_schema,
            schemas.object_type,
            schemas.schema_name AS object_name,
            NULL::text AS calling_arguments,
            schemas.owner_oid,
            schemas.acl
           FROM schemas
        UNION
         SELECT classes.object_schema,
            classes.object_type,
            classes.object_name,
            NULL::text AS calling_arguments,
            classes.owner_oid,
            classes.acl
           FROM classes
        UNION
         SELECT cols.object_schema,
            cols.object_type,
            cols.object_name,
            NULL::text AS calling_arguments,
            cols.owner_oid,
            cols.acl
           FROM cols
        UNION
         SELECT procs.object_schema,
            procs.object_type,
            procs.object_name,
            procs.calling_arguments,
            procs.owner_oid,
            procs.acl
           FROM procs
        UNION
         SELECT udts.object_schema,
            udts.object_type,
            udts.object_name,
            NULL::text AS calling_arguments,
            udts.owner_oid,
            udts.acl
           FROM udts
        UNION
         SELECT fdws.object_schema,
            fdws.object_type,
            fdws.object_name,
            NULL::text AS calling_arguments,
            fdws.owner_oid,
            fdws.acl
           FROM fdws
        UNION
         SELECT fsrvs.object_schema,
            fsrvs.object_type,
            fsrvs.object_name,
            NULL::text AS calling_arguments,
            fsrvs.owner_oid,
            fsrvs.acl
           FROM fsrvs
        ), acl_base AS (
         SELECT all_objects.object_schema,
            all_objects.object_type,
            all_objects.object_name,
            all_objects.calling_arguments,
            all_objects.owner_oid,
            (aclexplode(all_objects.acl)).grantor AS grantor_oid,
            (aclexplode(all_objects.acl)).grantee AS grantee_oid,
            (aclexplode(all_objects.acl)).privilege_type AS privilege_type,
            (aclexplode(all_objects.acl)).is_grantable AS is_grantable
           FROM all_objects
        )
 SELECT acl_base.object_schema,
    acl_base.object_type,
    acl_base.object_name,
    acl_base.calling_arguments,
    owner.role_name AS object_owner,
    grantor.role_name AS grantor,
    grantee.role_name AS grantee,
    acl_base.privilege_type,
    acl_base.is_grantable
   FROM (((acl_base
     JOIN rol owner ON ((owner.oid = acl_base.owner_oid)))
     JOIN rol grantor ON ((grantor.oid = acl_base.grantor_oid)))
     JOIN rol grantee ON ((grantee.oid = acl_base.grantee_oid)))
  WHERE ((acl_base.grantor_oid <> acl_base.grantee_oid) AND (NOT (acl_base.object_name ~~ 'citext%'::text)) AND (NOT (acl_base.object_name ~~ 'regexp%'::text)) AND (NOT (acl_base.object_name ~~ 'texticn%'::text)) AND (NOT (acl_base.object_name ~~ 'textic%'::text)));


ALTER VIEW public.v_role_privileges OWNER TO d3l243;

--
-- Name: TABLE v_role_privileges; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_role_privileges TO readaccess;
GRANT SELECT ON TABLE public.v_role_privileges TO writeaccess;

