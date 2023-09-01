--
-- Name: add_naming_authority(text, text, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_naming_authority(IN _name text, IN _description text, IN _webaddress text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an annotation naming authority in pc.t_naming_authorities
**
**  Arguments:
**    _name             Authority name
**    _description      Description
**    _webAddress       Website URL
**
**  Returns:
**    _returnCode will have the naming authority ID if a new row was added to pc.t_naming_authorities
**    _returnCode will be the negative value of the authority ID if the authority already exists in pc.t_naming_authorities
**
**  Auth:   kja
**  Date:   12/14/2005
**          08/18/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _authId int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _name        := Trim(Coalesce(_name, ''));
    _description := Trim(Coalesce(_description, ''));
    _webAddress  := Trim(Coalesce(_webAddress, ''));

    If _name = '' Then
        _message := 'Authority name cannot be null or empty';
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT authority_id
    INTO _authId
    FROM pc.t_naming_authorities
    WHERE name = _name::citext;

    If FOUND Then
        _message := format('Naming authority "%s" already exists, ID %s', _name, _authId);
        RAISE WARNING '%', _message;

        -- The Organism Database Handler expects this procedure to return negative _authId if _name already exists
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


ALTER PROCEDURE pc.add_naming_authority(IN _name text, IN _description text, IN _webaddress text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

