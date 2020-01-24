--
-- Name: get_psutil_mem(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.get_psutil_mem(OUT total double precision, OUT used double precision, OUT free double precision, OUT buff_cache double precision, OUT available double precision, OUT percent double precision, OUT swap_total double precision, OUT swap_used double precision, OUT swap_free double precision, OUT swap_percent double precision) RETURNS record
    LANGUAGE plpythonu SECURITY DEFINER
    AS $$
from psutil import virtual_memory, swap_memory
vm = virtual_memory()
sw = swap_memory()
return vm.total, vm.used, vm.free, vm.buffers + vm.cached, vm.available, vm.percent, sw.total, sw.used, sw.free, sw.percent
$$;


ALTER FUNCTION public.get_psutil_mem(OUT total double precision, OUT used double precision, OUT free double precision, OUT buff_cache double precision, OUT available double precision, OUT percent double precision, OUT swap_total double precision, OUT swap_used double precision, OUT swap_free double precision, OUT swap_percent double precision) OWNER TO d3l243;

--
-- Name: FUNCTION get_psutil_mem(OUT total double precision, OUT used double precision, OUT free double precision, OUT buff_cache double precision, OUT available double precision, OUT percent double precision, OUT swap_total double precision, OUT swap_used double precision, OUT swap_free double precision, OUT swap_percent double precision); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_psutil_mem(OUT total double precision, OUT used double precision, OUT free double precision, OUT buff_cache double precision, OUT available double precision, OUT percent double precision, OUT swap_total double precision, OUT swap_used double precision, OUT swap_free double precision, OUT swap_percent double precision) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_psutil_mem(OUT total double precision, OUT used double precision, OUT free double precision, OUT buff_cache double precision, OUT available double precision, OUT percent double precision, OUT swap_total double precision, OUT swap_used double precision, OUT swap_free double precision, OUT swap_percent double precision); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_psutil_mem(OUT total double precision, OUT used double precision, OUT free double precision, OUT buff_cache double precision, OUT available double precision, OUT percent double precision, OUT swap_total double precision, OUT swap_used double precision, OUT swap_free double precision, OUT swap_percent double precision) TO pgwatch2;

