--
CREATE OR REPLACE FUNCTION pc.get_annotation_type_id
(
    _annotationName text,
    _authorityID int
)
RETURNS int
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Gets Annotation Type ID for a given Annotation Name
**
**  Auth:   kja
**  Date:   01/11/2006
**          05/01/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _annotationTypeID int;
BEGIN
    SELECT annotation_type_id
    INTO _annotationTypeID
    FROM pc.t_annotation_types
    WHERE type_name = _annotationName AND authority_id = _authorityID;

    If Not Found Then
        Return null;
    Else
        Return _annotationTypeID;
    End If;
END
$$;

COMMENT ON FUNCTION pc.get_annotation_type_id IS 'GetAnnotationTypeID';
