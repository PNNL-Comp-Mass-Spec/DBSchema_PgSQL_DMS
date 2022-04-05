--
-- Name: add_new_terms_default_ontologies(integer, integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_terms_default_ontologies(_infoonly integer DEFAULT 0, _previewsql integer DEFAULT 0) RETURNS TABLE(ontology public.citext, term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, parent_term_name public.citext, parent_term_id public.citext, grandparent_term_name public.citext, grandparent_term_id public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new ontology terms to the ontology-specific tables for the default ontologies:
**      CL, GO, MI (PSI_MI), MOD (PSI_Mod), PRIDE, NEWT, and DOID
**
**  Usage:
**      SELECT * FROM ont.add_new_terms_default_ontologies( _infoOnly => 0, _previewSql => 0);
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          12/04/2013 mem - Added CL
**          03/17/2014 mem - Added DOID (disease ontology)
**          04/04/2022 mem - Ported to PostgreSQL
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
    Values ('CL'),
           ('GO'),
           ('MI'),
           ('MOD'),
           ('PRIDE'),
           ('NEWT'),
           ('DOID');

    For _ontology In
        SELECT u.ontology
        FROM Tmp_OntologiesToUpdate u
    Loop

        RETURN QUERY
        SELECT _ontology,
               s.term_pk, s.term_name, s.identifier, s.is_leaf,
               s.parent_term_name, s.parent_term_id,
               s.grandparent_term_name, s.grandparent_term_id
        FROM ont.add_new_terms(_ontologyName => _ontology,
                               _infoOnly => _infoOnly,
                               _previewSql => _previewSql) s;

    End Loop;

    Drop Table Tmp_OntologiesToUpdate;
END
$$;


ALTER FUNCTION ont.add_new_terms_default_ontologies(_infoonly integer, _previewsql integer) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_terms_default_ontologies(_infoonly integer, _previewsql integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_terms_default_ontologies(_infoonly integer, _previewsql integer) IS 'AddNewTermsDefaultOntologies';

