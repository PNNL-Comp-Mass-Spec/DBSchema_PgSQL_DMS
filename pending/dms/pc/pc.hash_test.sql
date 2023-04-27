--
CREATE OR REPLACE PROCEDURE pc.hash_test
(
    _parameter1 int = 5,
    _parameter2 datatype OUTPUT
)
LANGUAGE plpgsql
AS $$
DECLARE
    _hashThis text;;
BEGIN
    /*
    */

SELECT CONVERT(nvarchar,'dslfdkjLK85kldhnv$n000#knf'); INTO _hashThis
SELECT HashBytes('SHA1', _hashThis);

RETURN
END
$$;

COMMENT ON PROCEDURE pc.hash_test IS 'HashTest';
