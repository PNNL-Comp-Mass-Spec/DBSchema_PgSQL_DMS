--
CREATE OR REPLACE PROCEDURE pc.get_naming_authority_id
(
    _authName text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Gets AuthorityID for a given Authority Name
**
**
**  Auth:   kja
**  Date:   12/16/2005
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _authId int;
BEGIN
    _authId := 0;

    SELECT authority_id FROM pc.t_naming_authorities INTO _authId
     WHERE ("name" = _authName)

    return _authId
END
$$;

COMMENT ON PROCEDURE pc.get_naming_authority_id IS 'GetNamingAuthorityID';
