--
-- Name: get_annotation_type_id(text, integer); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.get_annotation_type_id(_annotationname text, _authorityid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get Annotation Type ID for a given Annotation Name
**
**  Arguments:
**      _annotationName     Annotation name to find
**      _authorityID        Authority id; ignored if null
**
**  Auth:   kja
**  Date:   01/11/2006 kja - Initial version
**          05/01/2023 mem - Ported to PostgreSQL
**                         - Ignore _authorityID if it is null
**          05/22/2023 mem - Capitalize reserved words
**
*****************************************************/
DECLARE
    _annotationTypeID int;
BEGIN
    SELECT annotation_type_id
    INTO _annotationTypeID
    FROM pc.t_annotation_types
    WHERE type_name = _annotationName::citext AND
          (authority_id = _authorityID OR _authorityID IS NULL);

    If Not FOUND Then
        RETURN null;
    Else
        RETURN _annotationTypeID;
    End If;
END
$$;


ALTER FUNCTION pc.get_annotation_type_id(_annotationname text, _authorityid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_annotation_type_id(_annotationname text, _authorityid integer); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON FUNCTION pc.get_annotation_type_id(_annotationname text, _authorityid integer) IS 'GetAnnotationTypeID';

