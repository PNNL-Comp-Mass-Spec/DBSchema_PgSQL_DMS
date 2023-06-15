--
CREATE OR REPLACE PROCEDURE pc.add_annotation_type
(
    _name text,
    _description text,
    _example text,
    _authID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds an annotation type (for a naming authority) to t_annotation_types
**
**  Arguments:
**    _name             Annotation type name
**    _description      Description
**    _example          Example annotation
**    _authID           Naming authority ID
**
**  Returns:
**    _returnCode will have the annotation type ID if a new row was added to t_annotation_types
**    _returnCode will be the negative value of the annotation type ID if the annotation type already exists in t_annotation_types
**
**  Auth:   kja
**  Date:   01/11/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _annotationTypeID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    _annotationTypeID := get_annotation_type_id (_name, _authID)

    if Coalesce(_annotationTypeID, 0) > 0 Then
        _message := format('Annotation type "%s" already exists for naming authority ID %s', _name, _authId);
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return negative _annotationTypeID if the annotation type already exists for the naming authority
        _returnCode := format('-%s', _annotationTypeID);
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    INSERT INTO pc.t_annotation_types (type_name, description, example, Authority_ID)
    VALUES (_name, _description, _example, _authID)
    RETURNING annotation_type_id
    INTO _annotationTypeID;

    _returnCode := _annotationTypeID::text;
END
$$;

COMMENT ON PROCEDURE pc.add_annotation_type IS 'AddAnnotationType';
