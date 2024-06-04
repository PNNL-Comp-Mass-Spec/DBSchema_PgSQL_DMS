--
-- Name: add_annotation_type(text, text, text, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_annotation_type(IN _name text, IN _description text, IN _example text, IN _authid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add an annotation type (for a naming authority) to pc.t_annotation_types
**
**  Arguments:
**    _name         Annotation type name
**    _description  Description
**    _example      Example annotation
**    _authID       Naming authority ID (corresponding to pc.t_naming_authorities)
**    _message      Status message
**    _returnCode   Return code
**
**  Returns:
**    _returnCode will have the annotation type ID if a new row was added to t_annotation_types
**    _returnCode will be the negative value of the annotation type ID if the annotation type already exists in t_annotation_types
**
**  Auth:   kja
**  Date:   01/11/2006
**          08/18/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _annotationTypeID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _name        := Trim(Coalesce(_name, ''));
    _description := Trim(Coalesce(_description, ''));
    _example     := Trim(Coalesce(_example, ''));
    _authID      := Coalesce(_authID, 0);

    If Not Exists (SELECT authority_id FROM pc.t_naming_authorities WHERE authority_id = _authID) Then
        _message := format('Invalid naming authority ID; %s not found in pc.t_naming_authorities', _authID);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    _annotationTypeID := pc.get_annotation_type_id(_name, _authID);

    If Coalesce(_annotationTypeID, 0) > 0 Then
        _message := format('Annotation type "%s" already exists for naming authority ID %s', _name, Coalesce(_authId, 0));
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return negative _annotationTypeID if the annotation type already exists for the naming authority
        _returnCode := format('-%s', _annotationTypeID);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    INSERT INTO pc.t_annotation_types (
        type_name,
        description,
        example,
        authority_id
    )
    VALUES (_name, _description, _example, _authID)
    RETURNING annotation_type_id
    INTO _annotationTypeID;

    _returnCode := _annotationTypeID::text;
END
$$;


ALTER PROCEDURE pc.add_annotation_type(IN _name text, IN _description text, IN _example text, IN _authid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_annotation_type(IN _name text, IN _description text, IN _example text, IN _authid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_annotation_type(IN _name text, IN _description text, IN _example text, IN _authid integer, INOUT _message text, INOUT _returncode text) IS 'AddAnnotationType';

