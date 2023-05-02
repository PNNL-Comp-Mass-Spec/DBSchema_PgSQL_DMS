--
CREATE OR REPLACE PROCEDURE pc.add_naming_authority
(
    _name text,
    _description text,
    _webAddress text,
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
**  Date:   12/14/2005
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _memberID int;
    _authId int;
    _transName text;
BEGIN
    _authId := 0;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    execute _authId = GetNamingAuthorityID _name

    if _authId > 0 Then
        return -_authId
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddNamingAuthority';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO pc.t_naming_authorities
               ("name", description, web_address)
    VALUES     (_name, _description, _webAddress)
    RETURNING authority_id
    INTO _authId

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Insert operation failed: "' || _name || '"';
        RAISERROR (_msg, 10, 1)
        return 51007
    End If;

    commit transaction _transName

    return _authID
END
$$;

COMMENT ON PROCEDURE pc.add_naming_authority IS 'AddNamingAuthority';
