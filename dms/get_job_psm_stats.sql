--
-- Name: get_job_psm_stats(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_job_psm_stats(_job integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of PSM stats for given analysis job
**
**  Auth:   mem
**  Date:   02/22/2012 mem - Initial version
**          05/08/2012 mem - Now showing FDR-based stats if Total_PSMs_FDR_Filter > 0
**          05/11/2012 mem - Now displaying FDR as a percentage
**          01/17/2014 mem - Added support for MSGF_Threshold_Is_EValue = 1
**          07/15/2020 mem - Report % PSMs without TMT or iTRAQ
**          06/15/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stats text;
BEGIN
    SELECT CASE WHEN Total_PSMs_FDR_Filter > 0
                THEN
                   'Spectra Searched: ' || Spectra_Searched::text      || ', ' ||
                   'Total PSMs: '       || Total_PSMs_FDR_Filter::text ||
                   CASE WHEN Dynamic_Reporter_Ion > 0
                        THEN ' (' || Percent_PSMs_Missing_NTerm_Reporter_Ion::text || '% missing N-Terminal reporter ion), '
                   ELSE ', '
                   END ||
                'Unique Peptides: '  || Unique_Peptides_FDR_Filter::text || ', ' ||
                'Unique Proteins: '  || Unique_Proteins_FDR_Filter::text ||
                '  (FDR < '          || (FDR_Threshold*100.0)::decimal(9,2) || '%)'
           ELSE
                'Spectra Searched: ' || Spectra_Searched::text || ', ' ||
                'Total PSMs: '       || Total_PSMs::text       || ', ' ||
                'Unique Peptides: '  || Unique_Peptides::text  || ', ' ||
                'Unique Proteins: '  || Unique_Proteins::text  ||
                '  (' || CASE WHEN MSGF_Threshold_Is_EValue > 0 THEN 'EValue' ELSE 'MSGF' END || ' < ' || MSGF_Threshold::text || ')'
            END
    INTO _stats
    FROM t_analysis_job_psm_stats
    WHERE job = _job;

    RETURN Coalesce(_stats, '');
END
$$;


ALTER FUNCTION public.get_job_psm_stats(_job integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_psm_stats(_job integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_job_psm_stats(_job integer) IS 'GetJobPSMStats';

