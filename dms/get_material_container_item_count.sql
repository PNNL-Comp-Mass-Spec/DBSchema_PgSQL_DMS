--
-- Name: get_material_container_item_count(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_material_container_item_count(_containerid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a count of the number of items in a material container
**
**  Arguments:
**    _containerID    Container ID
**
**  Auth:   mem
**  Date:   07/09/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _result int;
BEGIN
    SELECT COUNT(contentsq.material_id)
    INTO _result
    FROM (SELECT B.biomaterial_id AS material_id
          FROM t_biomaterial B
          WHERE B.container_id = _containerID AND B.material_active = 'Active'
          UNION
          SELECT E.exp_id AS material_id
          FROM t_experiments E
          WHERE E.container_id = _containerID AND E.material_active = 'Active'
          UNION
          SELECT C.compound_id AS material_id
          FROM t_reference_compound C
          WHERE C.container_id = _containerID
         ) ContentsQ;

    RETURN Coalesce(_result, 0);
END
$$;


ALTER FUNCTION public.get_material_container_item_count(_containerid integer) OWNER TO d3l243;

