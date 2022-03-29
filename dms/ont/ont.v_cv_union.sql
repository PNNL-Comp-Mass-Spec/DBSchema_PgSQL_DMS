--
-- Name: v_cv_union; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_cv_union AS
 SELECT 'BTO'::text AS source,
    t_cv_bto.term_pk,
    t_cv_bto.term_name,
    t_cv_bto.identifier,
    t_cv_bto.is_leaf,
    t_cv_bto.parent_term_name,
    t_cv_bto.parent_term_id,
    t_cv_bto.grand_parent_term_name,
    t_cv_bto.grand_parent_term_id
   FROM ont.t_cv_bto
UNION
 SELECT 'ENVO'::text AS source,
    t_cv_envo.term_pk,
    t_cv_envo.term_name,
    t_cv_envo.identifier,
    t_cv_envo.is_leaf,
    t_cv_envo.parent_term_name,
    t_cv_envo.parent_term_id,
    t_cv_envo.grand_parent_term_name,
    t_cv_envo.grand_parent_term_id
   FROM ont.t_cv_envo
UNION
 SELECT 'CL'::text AS source,
    t_cv_cl.term_pk,
    t_cv_cl.term_name,
    t_cv_cl.identifier,
    t_cv_cl.is_leaf,
    t_cv_cl.parent_term_name,
    t_cv_cl.parent_term_id,
    t_cv_cl.grand_parent_term_name,
    t_cv_cl.grand_parent_term_id
   FROM ont.t_cv_cl
UNION
 SELECT 'GO'::text AS source,
    t_cv_go.term_pk,
    t_cv_go.term_name,
    t_cv_go.identifier,
    t_cv_go.is_leaf,
    t_cv_go.parent_term_name,
    t_cv_go.parent_term_id,
    t_cv_go.grand_parent_term_name,
    t_cv_go.grand_parent_term_id
   FROM ont.t_cv_go
UNION
 SELECT 'PSI-MI'::text AS source,
    t_cv_mi.term_pk,
    t_cv_mi.term_name,
    t_cv_mi.identifier,
    t_cv_mi.is_leaf,
    t_cv_mi.parent_term_name,
    t_cv_mi.parent_term_id,
    t_cv_mi.grand_parent_term_name,
    t_cv_mi.grand_parent_term_id
   FROM ont.t_cv_mi
UNION
 SELECT 'PSI-Mod'::text AS source,
    t_cv_mod.term_pk,
    t_cv_mod.term_name,
    t_cv_mod.identifier,
    t_cv_mod.is_leaf,
    t_cv_mod.parent_term_name,
    t_cv_mod.parent_term_id,
    t_cv_mod.grand_parent_term_name,
    t_cv_mod.grand_parent_term_id
   FROM ont.t_cv_mod
UNION
 SELECT 'PSI-MS'::text AS source,
    t_cv_ms.term_pk,
    t_cv_ms.term_name,
    t_cv_ms.identifier,
    t_cv_ms.is_leaf,
    t_cv_ms.parent_term_name,
    t_cv_ms.parent_term_id,
    t_cv_ms.grand_parent_term_name,
    t_cv_ms.grand_parent_term_id
   FROM ont.t_cv_ms
UNION
 SELECT 'NEWT'::text AS source,
    t_cv_newt.term_pk,
    t_cv_newt.term_name,
    t_cv_newt.identifier,
    t_cv_newt.is_leaf,
    t_cv_newt.parent_term_name,
    t_cv_newt.parent_term_id,
    t_cv_newt.grand_parent_term_name,
    t_cv_newt.grand_parent_term_id
   FROM ont.t_cv_newt
UNION
 SELECT 'PRIDE'::text AS source,
    t_cv_pride.term_pk,
    t_cv_pride.term_name,
    t_cv_pride.identifier,
    t_cv_pride.is_leaf,
    t_cv_pride.parent_term_name,
    t_cv_pride.parent_term_id,
    t_cv_pride.grand_parent_term_name,
    t_cv_pride.grand_parent_term_id
   FROM ont.t_cv_pride
UNION
 SELECT 'DOID'::text AS source,
    t_cv_doid.term_pk,
    t_cv_doid.term_name,
    t_cv_doid.identifier,
    t_cv_doid.is_leaf,
    t_cv_doid.parent_term_name,
    t_cv_doid.parent_term_id,
    t_cv_doid.grand_parent_term_name,
    t_cv_doid.grand_parent_term_id
   FROM ont.t_cv_doid;


ALTER TABLE ont.v_cv_union OWNER TO d3l243;

