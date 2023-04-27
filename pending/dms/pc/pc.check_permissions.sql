--
CREATE OR REPLACE PROCEDURE pc.check_permissions
(
    _parameter1 int = 5,
    _parameter2 datatype OUTPUT
)
LANGUAGE plpgsql
AS $$
DECLARE
    _state  int;
    _name text;
BEGIN
    /*
    */

    _name := SYSTEM_USER    ;

    _state := IS_MEMBER('PNL\EMSL-Prism.Users.Web_Analysis');

    RETURN
END
$$;

COMMENT ON PROCEDURE pc.check_permissions IS 'CheckPermissions';
