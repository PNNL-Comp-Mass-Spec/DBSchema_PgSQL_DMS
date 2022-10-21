--
-- Name: get_new_job_id(text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_new_job_id(_note text, _infoonly boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets a unique number for making a new job
**
**  Example usage:
**
**      SELECT *
**      FROM public.get_new_job_id('Job created in DMS', true);
**
**      _job := public.get_new_job_id('Job created in DMS', false)
**
**  Auth:   grk
**  Date:   08/04/2009
**          08/05/2009 grk - initial release (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          08/05/2009 mem - Now using SCOPE_IDENTITY() to determine the ID of the newly added row
**          06/24/2015 mem - Added parameter _infoOnly
**          10/20/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _id int;
BEGIN

    If Coalesce(_infoOnly, false) Then
        -- Preview the next job number
        SELECT MAX(job) + 1
        INTO _id
        FROM t_analysis_job_id;

        If FOUND Then
            RETURN _id;
        Else
            RETURN 1;
        End If;
    End If;

    -- Insert new row in job ID table to create unique ID
    --
    INSERT INTO t_analysis_job_id ( note)
    VALUES (Coalesce(_note, ''))
    RETURNING job
    INTO _id;

    RETURN _id;
END
$$;


ALTER FUNCTION public.get_new_job_id(_note text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_new_job_id(_note text, _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_new_job_id(_note text, _infoonly boolean) IS 'GetNewJobID';

