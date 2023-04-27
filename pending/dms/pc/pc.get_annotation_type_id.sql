--
CREATE OR REPLACE PROCEDURE pc.get_annotation_type_id
(
    _annName text,
    _authID int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Gets AnnotationTypeID for a given Annotation Name
**
**
**  Auth:   kja
**  Date:   01/11/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _annotationTypeID int;
BEGIN
    _annotationTypeID := 0;

    SELECT annotation_type_id FROM pc.t_annotation_types INTO _annotationTypeID
    WHERE (type_name = _annName and authority_id = _authID)

    return _annotationTypeID
END
$$;

COMMENT ON PROCEDURE pc.get_annotation_type_id IS 'GetAnnotationTypeID';
