--
-- Name: add_new_terms_default_ontologies(boolean, boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_terms_default_ontologies(_infoonly boolean DEFAULT false, _previewsql boolean DEFAULT false) RETURNS TABLE(ontology public.citext, term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, parent_term_name public.citext, parent_term_id public.citext, grandparent_term_name public.citext, grandparent_term_id public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new ontology terms to the ontology-specific tables for the default ontologies:
**      CL, GO, MI (PSI_MI), MOD (PSI_Mod), PRIDE, and DOID
**
**      Calls function add_new_terms, which pulls data from  t_ontology, t_term, and t_term_relationship (using v_term_lineage)
**      and updates the ontology-specific table (t_cv_cl, t_cv_go, t_cv_mi, t_cv_mod, t_cv_pride, or t_cv_doid)
**
**      Note that BTO, ENVO, MS, and NEWT have dedicated functions for adding new terms
**      - add_new_bto_terms
**      - add_new_envo_terms
**      - add_new_ms_terms
**      - add_new_newt_terms
**
**  Arguments:
**    _infoOnly       When true, preview updates
**    _previewSql     When true, preview the SQL (but do not execute it)
**
**  Usage:
**      SELECT * FROM ont.add_new_terms_default_ontologies (_infoOnly => false, _previewSql => false);
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          12/04/2013 mem - Added CL
**          03/17/2014 mem - Added DOID (disease ontology)
**          04/04/2022 mem - Ported to PostgreSQL
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          06/09/2024 mem - No longer call add_new_terms for NEWT; instead, use function add_new_newt_terms
**
*****************************************************/
DECLARE
    _ontology citext;
BEGIN

    ---------------------------------------------------
    -- Call add_new_terms for the ontologies of interest
    -- This will pull data from t_ontology, t_term, and
    -- t_term_relationship (using v_term_lineage) and update
    -- the ontology-specific table (t_cv_cl, t_cv_go, etc.)
    ---------------------------------------------------

    -- Note that BTO, ENVO, MS, and NEWT have dedicated functions for adding new terms

    CREATE TEMP TABLE Tmp_OntologiesToUpdate (
        ontology citext
    );

    INSERT INTO Tmp_OntologiesToUpdate (ontology)
    VALUES ('CL'),
           ('GO'),
           ('MI'),
           ('MOD'),
           ('PRIDE'),
           ('DOID');

    FOR _ontology IN
        SELECT u.ontology
        FROM Tmp_OntologiesToUpdate u
    LOOP

        RETURN QUERY
        SELECT _ontology,
               s.term_pk, s.term_name, s.identifier, s.is_leaf,
               s.parent_term_name, s.parent_term_id,
               s.grandparent_term_name, s.grandparent_term_id
        FROM ont.add_new_terms(_ontologyName => _ontology,
                               _infoOnly     => _infoOnly,
                               _previewSql   => _previewSql) s;

    END LOOP;

    DROP TABLE Tmp_OntologiesToUpdate;
END
$$;


ALTER FUNCTION ont.add_new_terms_default_ontologies(_infoonly boolean, _previewsql boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_terms_default_ontologies(_infoonly boolean, _previewsql boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_terms_default_ontologies(_infoonly boolean, _previewsql boolean) IS 'AddNewTermsDefaultOntologies';

