--
-- Name: v_role_members; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_role_members AS
 WITH RECURSIVE x AS (
         SELECT (m.member)::regrole AS member,
            (m.roleid)::regrole AS role,
            (((m.member)::regrole || ' -> '::text) || (m.roleid)::regrole) AS path
           FROM pg_auth_members m
          WHERE (m.roleid > (16384)::oid)
        UNION ALL
         SELECT x_1.member,
            (m.roleid)::regrole AS roleid,
            ((x_1.path || ' -> '::text) || (m.roleid)::regrole)
           FROM (pg_auth_members m
             JOIN x x_1 ON ((m.member = (x_1.role)::oid)))
        )
 SELECT member,
    role,
    path
   FROM x
  ORDER BY (member)::text, (role)::text;


ALTER VIEW public.v_role_members OWNER TO d3l243;

--
-- Name: TABLE v_role_members; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_role_members TO readaccess;
GRANT SELECT ON TABLE public.v_role_members TO writeaccess;

