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
**      CL, GO, MI (PSI_MI), MOD (PSI_Mod), PRIDE, NEWT, and DOID
**
**  Usage:
**      SELECT * FROM ont.add_new_terms_default_ontologies( _infoOnly => false, _previewSql => false);
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          12/04/2013 mem - Added CL
**          03/17/2014 mem - Added DOID (disease ontology)
**          04/04/2022 mem - Ported to PostgreSQL
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**
*****************************************************/
DECLARE
    _ontology citext;
BEGIN
    CREATE TEMP TABLE Tmp_OntologiesToUpdate (
        ontology citext
    );

    -- Note that BTO, ENVO, and MS have dedicated functions for adding new terms

    INSERT INTO Tmp_OntologiesToUpdate (ontology)
    VALUES ('CL'),
           ('GO'),
           ('MI'),
           ('MOD'),
           ('PRIDE'),
           ('NEWT'),
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

    Drop Table Tmp_OntologiesToUpdate;
END
$$;


ALTER FUNCTION ont.add_new_terms_default_ontologies(_infoonly boolean, _previewsql boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_terms_default_ontologies(_infoonly boolean, _previewsql boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_terms_default_ontologies(_infoonly boolean, _previewsql boolean) IS 'AddNewTermsDefaultOntologies';

