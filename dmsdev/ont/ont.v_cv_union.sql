--
-- Name: v_cv_union; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_union AS
 SELECT 'BTO'::public.citext AS source,
    t_cv_bto.term_pk,
    t_cv_bto.term_name,
    t_cv_bto.identifier,
    t_cv_bto.is_leaf,
    t_cv_bto.parent_term_name,
    t_cv_bto.parent_term_id,
    t_cv_bto.grandparent_term_name,
    t_cv_bto.grandparent_term_id
   FROM ont.t_cv_bto
UNION
 SELECT 'ENVO'::public.citext AS source,
    t_cv_envo.term_pk,
    t_cv_envo.term_name,
    t_cv_envo.identifier,
    t_cv_envo.is_leaf,
    t_cv_envo.parent_term_name,
    t_cv_envo.parent_term_id,
    t_cv_envo.grandparent_term_name,
    t_cv_envo.grandparent_term_id
   FROM ont.t_cv_envo
UNION
 SELECT 'CL'::public.citext AS source,
    t_cv_cl.term_pk,
    t_cv_cl.term_name,
    t_cv_cl.identifier,
    t_cv_cl.is_leaf,
    t_cv_cl.parent_term_name,
    t_cv_cl.parent_term_id,
    t_cv_cl.grandparent_term_name,
    t_cv_cl.grandparent_term_id
   FROM ont.t_cv_cl
UNION
 SELECT 'GO'::public.citext AS source,
    t_cv_go.term_pk,
    t_cv_go.term_name,
    t_cv_go.identifier,
    t_cv_go.is_leaf,
    t_cv_go.parent_term_name,
    t_cv_go.parent_term_id,
    t_cv_go.grandparent_term_name,
    t_cv_go.grandparent_term_id
   FROM ont.t_cv_go
UNION
 SELECT 'PSI-MI'::public.citext AS source,
    t_cv_mi.term_pk,
    t_cv_mi.term_name,
    t_cv_mi.identifier,
    t_cv_mi.is_leaf,
    t_cv_mi.parent_term_name,
    t_cv_mi.parent_term_id,
    t_cv_mi.grandparent_term_name,
    t_cv_mi.grandparent_term_id
   FROM ont.t_cv_mi
UNION
 SELECT 'PSI-Mod'::public.citext AS source,
    t_cv_mod.term_pk,
    t_cv_mod.term_name,
    t_cv_mod.identifier,
    t_cv_mod.is_leaf,
    t_cv_mod.parent_term_name,
    t_cv_mod.parent_term_id,
    t_cv_mod.grandparent_term_name,
    t_cv_mod.grandparent_term_id
   FROM ont.t_cv_mod
UNION
 SELECT 'PSI-MS'::public.citext AS source,
    t_cv_ms.term_pk,
    t_cv_ms.term_name,
    t_cv_ms.identifier,
    t_cv_ms.is_leaf,
    t_cv_ms.parent_term_name,
    t_cv_ms.parent_term_id,
    t_cv_ms.grandparent_term_name,
    t_cv_ms.grandparent_term_id
   FROM ont.t_cv_ms
UNION
 SELECT 'NEWT'::public.citext AS source,
    t_cv_newt.term_pk,
    t_cv_newt.term_name,
    (t_cv_newt.identifier)::public.citext AS identifier,
    t_cv_newt.is_leaf,
    t_cv_newt.parent_term_name,
    t_cv_newt.parent_term_id,
    t_cv_newt.grandparent_term_name,
    t_cv_newt.grandparent_term_id
   FROM ont.t_cv_newt
UNION
 SELECT 'PRIDE'::public.citext AS source,
    t_cv_pride.term_pk,
    t_cv_pride.term_name,
    t_cv_pride.identifier,
    t_cv_pride.is_leaf,
    t_cv_pride.parent_term_name,
    t_cv_pride.parent_term_id,
    t_cv_pride.grandparent_term_name,
    t_cv_pride.grandparent_term_id
   FROM ont.t_cv_pride
UNION
 SELECT 'DOID'::public.citext AS source,
    t_cv_doid.term_pk,
    t_cv_doid.term_name,
    t_cv_doid.identifier,
    t_cv_doid.is_leaf,
    t_cv_doid.parent_term_name,
    t_cv_doid.parent_term_id,
    t_cv_doid.grandparent_term_name,
    t_cv_doid.grandparent_term_id
   FROM ont.t_cv_doid;


ALTER VIEW ont.v_cv_union OWNER TO d3l243;

--
-- Name: TABLE v_cv_union; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_cv_union TO readaccess;
GRANT SELECT ON TABLE ont.v_cv_union TO writeaccess;

