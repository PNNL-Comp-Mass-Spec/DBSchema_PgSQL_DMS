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
**  Desc:   Adds or changes an annotation naming authority
**
**
**
**  Auth:   kja
**  Date:   01/11/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _memberID int;
    _annotationTypeID int;
    _transName text;
BEGIN
    _annotationTypeID := 0;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    execute _annotationTypeID = GetAnnotationTypeID _name, _authID

    if _annotationTypeID > 0 Then
        return -_annotationTypeID
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddNamingAuthority';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO pc.t_annotation_types
               (type_name, description, example, Authority_ID)
    VALUES     (_name, _description, _example, _authID)

    SELECT @@Identity          INTO _annotationTypeID

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Insert operation failed: "' || _name || '"';
        RAISERROR (_msg, 10, 1)
        return 51007
    End If;

    commit transaction _transName

    return _annotationTypeID
END
$$;

COMMENT ON PROCEDURE pc.add_annotation_type IS 'AddAnnotationType';
