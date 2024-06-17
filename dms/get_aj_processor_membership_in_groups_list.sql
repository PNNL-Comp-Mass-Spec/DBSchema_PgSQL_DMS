--
-- Name: get_aj_processor_membership_in_groups_list(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_aj_processor_membership_in_groups_list(_processorid integer, _enabledisablefilter integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of processor group IDs for given analysis job processor ID
**
**  Arguments:
**    _processorID          Processor ID
**    _enableDisableFilter  Enable/disable filter: 0 means disabled only, 1 means enabled only, anything else means all
**
**  Returns:
**      Comma-separated list
**
**  Auth:   grk
**  Date:   02/12/2007
**          02/20/2007 grk - Fixed reference to group ID
**          02/22/2007 mem - Now grouping processors by Membership_Enabled values
**          02/23/2007 mem - Added parameter _enableDisableFilter
**          06/17/2022 mem - Ported to PostgreSQL
**          07/06/2022 mem - Fix concatenation typo
**          05/30/2023 mem - Use format() for string concatenation
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _combinedList text;
    _enabledGroups text;
    _disabledGroups text;
BEGIN
    _enableDisableFilter := Coalesce(_enableDisableFilter, 2);

    _combinedList := '';
    _enabledGroups := '';
    _disabledGroups := '';

    If _enableDisableFilter <> 0 Then
        SELECT string_agg(format('%s: %s', AJPG.group_id, AJPG.Group_Name), ', ' ORDER BY AJPG.group_name)
        INTO _enabledGroups
        FROM t_analysis_job_processor_group_membership AJPGM INNER JOIN
             t_analysis_job_processor_group AJPG ON AJPGM.group_id = AJPG.group_id
        WHERE AJPGM.processor_id = _processorID AND
              membership_enabled = 'Y';
    End If;

    If _enableDisableFilter <> 1 Then
        SELECT string_agg(format('%s: %s', AJPG.group_id, AJPG.Group_Name), ', ' ORDER BY AJPG.group_name)
        INTO _disabledGroups
        FROM t_analysis_job_processor_group_membership AJPGM INNER JOIN
             t_analysis_job_processor_group AJPG ON AJPGM.group_id = AJPG.group_id
        WHERE AJPGM.processor_id = _processorID AND
              membership_enabled <> 'Y';
    End If;

    If Coalesce(_enabledGroups, '') <> '' Then
        If Not _enableDisableFilter In (0, 1) Then
            _combinedList := 'Enabled: ';
        End If;

        _combinedList := format('%s%s', _combinedList, _enabledGroups);
    End If;

    If Coalesce(_disabledGroups, '') <> '' Then
        If Coalesce(_combinedList, '') <> '' Then
            _combinedList := format('%s%s', _combinedList, '; ');
        End If;

        If Not _enableDisableFilter In (0, 1) Then
            _combinedList := format('%s%s', _combinedList, 'Disabled: ');
        End If;

        _combinedList := format('%s%s', _combinedList, _disabledGroups);
    End If;

    RETURN Coalesce(_combinedList, '');

END
$$;


ALTER FUNCTION public.get_aj_processor_membership_in_groups_list(_processorid integer, _enabledisablefilter integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_aj_processor_membership_in_groups_list(_processorid integer, _enabledisablefilter integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_aj_processor_membership_in_groups_list(_processorid integer, _enabledisablefilter integer) IS 'GetAJProcessorMembershipInGroupsList';

