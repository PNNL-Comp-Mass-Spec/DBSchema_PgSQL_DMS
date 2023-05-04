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
**  Desc:
**      Adds or updates an annotation naming authority in t_naming_authorities
**
**  Arguments:
**    _name         Authority name
**    _description  Description
**    _webAddress   website
**
**  Returns:
**    _returnCode will have the naming authority ID if a new row was added to t_naming_authorities
**    _returnCode will be the negative value of the authority ID if the authority already exists in t_naming_authorities
**
**  Auth:   kja
**  Date:   12/14/2005
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _authId int;
BEGIN

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT authority_id
    INTO _authId
    FROM pc.t_naming_authorities
    WHERE name = _authName::citext;

    If FOUND Then
        _message := format('Naming authority "%s" already exists, ID %s', _authName, _authId
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return negative _authId if _authName already exists
        _returnCode := format('-%s', _authId);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    INSERT INTO pc.t_naming_authorities (name, description, web_address)
    VALUES (_name, _description, _webAddress)
    RETURNING authority_id
    INTO _authId;

    _returnCode := _authId::text;
END
$$;

COMMENT ON PROCEDURE pc.add_naming_authority IS 'AddNamingAuthority';
