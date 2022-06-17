--
-- Name: get_experiment_plex_members_for_entry(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_experiment_plex_members_for_entry(_plexexperimentid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Builds delimited list of experiment plex members for a given experiment plex
**
**  Auth:   mem
**  Date:   11/09/2018 mem
**          11/19/2018 mem - Update column name
**          06/16/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list text;
    _result text;
    _missingTagCount int := 0;
    _channelCount int := 0;
BEGIN
    SELECT Sum(Case When char_length(Coalesce(ReporterIons.tag_name, '')) = 0 Then 1 Else 0 End), Count(*)
    INTO _missingTagCount, _channelCount
    FROM t_experiment_plex_members PlexMembers
        INNER JOIN t_experiments ChannelExperiment
            ON PlexMembers.exp_id = ChannelExperiment.exp_id
        INNER JOIN t_experiments E
            ON PlexMembers.plex_exp_id = E.exp_id
        LEFT OUTER JOIN t_sample_labelling_reporter_ions ReporterIons
            ON PlexMembers.channel = ReporterIons.channel AND
                E.labelling = ReporterIons.label
    WHERE PlexMembers.plex_exp_id = _plexExperimentID;

    SELECT string_agg(LookupQ.PlexMemberInfo, chr(10) ORDER BY LookupQ.channel)
    INTO _list
    FROM ( SELECT PlexMembers.channel,
                  Coalesce(ReporterIons.tag_name, PlexMembers.channel::text) || ', ' ||
                  PlexMembers.exp_id::text || ', ' ||
                  ChannelType.channel_type_name || ', ' ||
                  Coalesce(PlexMembers.comment, '') AS PlexMemberInfo
           FROM t_experiment_plex_members PlexMembers
                INNER JOIN t_experiments ChannelExperiment
                  ON PlexMembers.exp_id = ChannelExperiment.exp_id
                INNER JOIN t_experiment_plex_channel_type_name ChannelType
                  ON PlexMembers.channel_type_id = ChannelType.channel_type_id
                INNER JOIN t_experiments E
                  ON PlexMembers.plex_exp_id = E.exp_id
                LEFT OUTER JOIN t_sample_labelling_reporter_ions ReporterIons
                  ON PlexMembers.channel = ReporterIons.channel AND
                     E.labelling = ReporterIons.label
           WHERE PlexMembers.plex_exp_id = _plexExperimentID ) LookupQ;

    If _missingTagCount > 0 And _missingTagCount = _channelCount Then
        _result := 'Channel, Exp_ID, Channel Type, Comment';
    Else
        _result := 'Tag, Exp_ID, Channel Type, Comment';
    End If;

    If char_length(Coalesce(_list, '')) > 0 Then
        _result := _result || chr(10) || _list;
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_experiment_plex_members_for_entry(_plexexperimentid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_experiment_plex_members_for_entry(_plexexperimentid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_experiment_plex_members_for_entry(_plexexperimentid integer) IS 'GetExperimentPlexMembersForEntry';

