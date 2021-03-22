create or replace package body eba_proj_gantt_poc as 
    function get_gant_json ( in_project_id in eba_proj_status$.id%type,
                             in_show_pm in varchar2 default 'no') return clob is
      l_json_data clob;
    begin

      --l_json_data := 
      --'{"data": [{"id":"1.0","text":"<strong>PL/SQL DA milestone 1</strong>","start_date":"01-02-2021","duration":60,"progress":0.1,"open":"true"},{"id":"2.0","text":"<strong>PL/SQL DA milestone 2</strong>","start_date":"01-03-2021","duration":90,"progress":0.1,"open":"true"}]}';

      SELECT '{"data": [' || LISTAGG(json_data, ', ') || ']}'   a 
      INTO l_json_data
      from (  
            --SELECT JSON_OBJECT(id,text,start_date,duration,progress,open) json_data
         select json_object('id'          VALUE id,
                            'text'        VALUE text,
                            'start_date'  VALUE start_date,
                            'duration'    VALUE duration,
                            'progress'    VALUE progress,
                            'open'        VALUE open
                   ) json_data
            FROM 
            (SELECT milestone_number id, 
                    case in_show_pm 
                     when 'yes' then initcap(first_name || ' ' || last_name)||' - '||Milestone_Name 
                     when 'no' then Milestone_Name
                     else Milestone_Name
                    end text,
                    to_char(milestone_Start_Date,'dd-mm-yyyy') start_date, duration,0.1 progress, 'true' open FROM  
               (select *      
                from eba_proj_status_ms m,
                     eba_proj_status_ms_no_v mn,
                     eba_proj_status p,
                     eba_proj_status_users u
                where mn.project_id = m.project_id
                  and mn.milestone_id = m.id
                  and p.id = m.project_id
                  and lower(m.milestone_owner) = lower(u.username)
                     and mn.project_id = in_project_id )  ) );
 
  /*    SELECT '{"data": [' || LISTAGG(a, ', ') || ']}'   a 
      INTO l_json_data
      from (  
               SELECT JSON_OBJECT(id,text,start_date,duration,progress,open) a
               FROM 
               (SELECT n id,Owner||' - '||Name text,TO_CHAR(Start_Date,'dd-mm-yyyy') start_date, duration,0.1 progress, 'true' open FROM 
               (select n, row_type, row_type_label, row_type_icon, name, milestone_description, start_date, end_date, completed_date, owner,estimated_hours,duration, HOURS_SPENT, nvl(HOURS_PERCENT||'%','') HOURS_PERCENT, round(MANPOWER,2) MANPOWER,
                   '<span class="t-Badge t-Badge--basic t-Badge--xsmall is-'
                       ||apex_escape.html(color_code)||' w100p">'||apex_escape.html(status)||'</span>' status,
                   disp_link, edit_link, add_link, ai_link,
                   (   select pj.project from eba_proj_status pj where pj.id = pj_id ) project_name, pj_id project_id
               from (  select mn.milestone_number||'.0' n,
                           '<strong>'||apex_escape.html(m.milestone_name)||'</strong>' name,
                           'Milestone' row_type_label,
                           'milestone' row_type,
                           case when upper(m.milestone_status) = 'OPEN' then 'fa-flag-o'
                                else 'fa-flag' end as row_type_icon,
                           m.milestone_start_date start_date,
                           m.milestone_date end_date,
                           m.completed_date completed_date,
                           m.milestone_status status,
                           case when m.owner_role_id is null then
                               eba_proj_fw.get_name_from_email_address(m.milestone_owner)
                           else
                               nvl((select r.name||': '||listagg(decode(u.first_name,null,eba_proj_fw.get_name_from_email_address(u.username),decode(u.last_name, null, eba_proj_fw.get_name_from_email_address(u.username), initcap(u.first_name || ' ' || u.last_name))),', ')
                                       within group (order by lower(u.username)) owner
                                   from eba_proj_user_ref rf,
                                       eba_proj_status_users u,
                                       eba_proj_roles r
                                   where rf.role_id = m.owner_role_id
                                       and rf.project_id = m.project_id
                                       and u.id = rf.user_id
                                       and r.id = rf.role_id
                                   group by r.name
                               ), (select 'No '||r.name||' defined'
                                   from eba_proj_roles r
                                   where r.id = m.owner_role_id)
                               )
                           end as owner,
                           m.project_id pj_id,
                           m.id ms_id,
                           null ai_id,
                           case when upper(m.milestone_status) = 'OPEN' and trunc(m.milestone_date) > trunc(sysdate) then 'success'
                               when upper(m.milestone_status) = 'OPEN' and trunc(m.milestone_date) = trunc(sysdate) then 'warning'
                               when upper(m.milestone_status) = 'OPEN'  then 'danger'
                               else 'complete' end as color_code,
                           p.row_key o0,
                           mn.milestone_number o1,
                           0                   o2,
                           apex_util.prepare_url('f?p='||:APP_ID||':107:'||:APP_SESSION||':::107:P107_ID,P107_PROJECT_ID,P200_ID:'
                               ||m.id||','||m.project_id||','||m.project_id) disp_link,
                           apex_util.prepare_url('f?p='||:APP_ID||':48:'||:APP_SESSION||':::48:P48_ID:'||m.id) edit_link,
                           case when eba_proj_fw.are_ms_ai_restricted( p_application_id => :APP_ID,
                                                                       p_username   => upper(:APP_USER),
                                                                       p_project_id => m.project_id ) = 'N'
                                   and eba_proj_stat_ui.get_authorization_level( p_username => upper(:APP_USER) ) >= 2 then
                               '<button type="button" class="t-Button t-Button--small t-Button--simple u-pullRight" onClick="'
                                   ||apex_util.prepare_url('f?p='||:APP_ID||':73:'||:APP_SESSION||':::73:P73_PROJECT_ID,P73_MILESTONE_ID:'
                                                           ||m.project_id||','||m.id)||'">Add Action Item</button>'
                            end as add_link,
                            null as ai_link,
                            m.milestone_description,
                            m.estimated_hours,m.duration,m.HOURS_SPENT,m.HOURS_PERCENT, m.MANPOWER
                       from eba_proj_status_ms m,
                           eba_proj_status_ms_no_v mn,
                           eba_proj_status p
                       where mn.project_id = m.project_id
                           and mn.milestone_id = m.id
                           and p.id = m.project_id
                           and (:P35_MILESTONE_OWNER is null
                               or ( m.owner_role_id is null and lower(m.milestone_owner) = lower(:P35_MILESTONE_OWNER))
                               or exists ( select null
                                           from eba_proj_user_ref rf,
                                               eba_proj_status_users u
                                           where rf.role_id = m.owner_role_id
                                               and rf.project_id = m.project_id
                                               and u.id = rf.user_id
                                               and lower(u.username) = lower(:P35_MILESTONE_OWNER) )
                               )
                           and ( nvl(:P35_SHOW,'Open') = 'All'
                               or (m.milestone_status = 'Open'
                                   and nvl(:P35_SHOW,'Open') = 'Open' ))
                           and (nvl(:P35_IS_MAJOR,'ALL') = 'ALL'
                               or (nvl(is_major_yn,'N') = 'Y'
                                   and nvl(:P35_IS_MAJOR,'ALL') = 'MAJOR' ))
                           and ( :P35_QUARTER is null
                                 or exists
                                (select null from eba_proj_fy_periods p where trunc(m.milestone_date) between p.first_day and p.last_day and p.period_name = :P35_QUARTER)
                               )
                           and ( :P35_PROJECT is null or m.project_id = :P35_PROJECT )
                           and ( :P35_SEARCH is null
                               or upper(:P35_SEARCH) = m.row_key
                               or instr(upper(m.milestone_name), upper(:P35_SEARCH)) > 0
                               or instr(upper(m.milestone_description), upper(:P35_SEARCH)) > 0)
                           and ( nvl(:P35_CATEGORY,0) = 0
                               or p.cat_id = :P35_CATEGORY)
                           -- and m.version_nb = nvl(:P35_SCHEDULE_VERSION,m.version_nb) -- PM: NULL can't be equal to NULL
                           and nvl(m.version_nb,'999999') = nvl(nvl(:P35_SCHEDULE_VERSION,m.version_nb),'999999') -- PM: corrected version
                   union all
                       select mn.milestone_number||'.'||an.action_item_number n,
                           apex_escape.html(a.action) name,
                           'Action Item' row_type_label,
                           'action-item' row_type,
                           case when upper(a.action_status) = 'OPEN' then 'fa fa-square-o icon-action-item'
                                else 'fa fa-check-square-o icon-action-item' end as row_type_icon,
                           null start_date,
                           a.due_date end_date,
                           a.completed_date completed_date,
                           a.action_status status,
                           case when a.owner_role_id is null then
                               eba_proj_fw.get_name_from_email_address(a.action_owner_01)
                                   ||nvl2(a.action_owner_02,', '||eba_proj_fw.get_name_from_email_address(a.action_owner_02),null)
                                   ||nvl2(a.action_owner_03,', '||eba_proj_fw.get_name_from_email_address(a.action_owner_03),null)
                                   ||nvl2(a.action_owner_04,', '||eba_proj_fw.get_name_from_email_address(a.action_owner_04),null)
                           else
                               nvl((select r.name||': '||listagg(decode(u.first_name,null,eba_proj_fw.get_name_from_email_address(u.username),decode(u.last_name, null, eba_proj_fw.get_name_from_email_address(u.username), initcap(u.first_name || ' ' || u.last_name))),', ')
                                       within group (order by lower(u.username)) owner
                                   from eba_proj_user_ref rf,
                                       eba_proj_status_users u,
                                       eba_proj_roles r
                                   where rf.role_id = a.owner_role_id
                                       and rf.project_id = a.project_id
                                       and u.id = rf.user_id
                                       and r.id = rf.role_id
                                   group by r.name
                               ), (select 'No '||r.name||' defined'
                                   from eba_proj_roles r
                                   where r.id = a.owner_role_id)
                               )
                           end as owner,
                           a.project_id pj_id,
                           a.milestone_id ms_id,
                           a.id ai_id,
                           case when upper(a.action_status) = 'OPEN' and trunc(a.due_date) > trunc(sysdate) then 'success'
                               when upper(a.action_status) = 'OPEN' and trunc(m.milestone_date) = trunc(sysdate) then 'warning'
                               when upper(a.action_status) = 'OPEN'  then 'danger'
                               else 'complete' end as color_code,
                           p.row_key o0,
                           mn.milestone_number   o1,
                           an.action_item_number o2,
                           apex_util.prepare_url('f?p='||:APP_ID||':78:'||:APP_SESSION||':::107:LAST_VIEW,P78_GOTO,P78_ACTION_ITEM_ID,P55_ID,P200_ID:200,MS,'
                               ||a.id||','||a.project_id||','||a.project_id) disp_link,
                           apex_util.prepare_url('f?p='||:APP_ID||':73:'||:APP_SESSION||':::73:P73_ID:'||a.id) edit_link,
                           null add_link,
                           case when a.link_url is not null then '<a href="' ||apex_escape.html(a.link_url)|| '" target="_blank" title="'
                               ||apex_escape.html(a.link_text)
                               ||'" class="t-Button t-Button--small t-Button--noUI"><span class="t-Icon fa fa-link"></span></a>' 
                           end as ai_link,
                           m.milestone_description,
                           m.estimated_hours, m.duration,m.HOURS_SPENT,m.HOURS_PERCENT, m.MANPOWER
                       from eba_proj_status_ais a,
                           eba_proj_status_ms m,
                           eba_proj_status_ms_no_v mn,
                           eba_proj_status_ai_no_tbl an,
                           eba_proj_status p
                       where mn.project_id = a.project_id
                           and mn.milestone_id = a.milestone_id
                           and an.project_id = a.project_id
                           and an.action_item_id = a.id
                           and m.project_id = a.project_id
                           and m.id = a.milestone_id
                           and p.id = m.project_id
                           and apex_util.get_build_option_status( p_application_id => :APP_ID,
                                                                  p_build_option_name => 'Project Action Items') = 'INCLUDE'
                           and (:P35_MILESTONE_OWNER is null
                               or ( m.owner_role_id is null and lower(m.milestone_owner) = lower(:P35_MILESTONE_OWNER))
                               or exists ( select null
                                           from eba_proj_user_ref rf,
                                               eba_proj_status_users u
                                           where rf.role_id = m.owner_role_id
                                               and rf.project_id = m.project_id
                                               and u.id = rf.user_id
                                               and lower(u.username) = lower(:P35_MILESTONE_OWNER) )
                               )
                           and ( nvl(:P35_SHOW,'Open') = 'All'
                               or (m.milestone_status = nvl(:P35_SHOW,'Open')
                                  and a.action_status = nvl(:P35_SHOW,'Open'))
                               )
                           and (nvl(:P35_IS_MAJOR,'ALL') = 'ALL'
                               or (nvl(is_major_yn,'N') = 'Y'
                                   and nvl(:P35_IS_MAJOR,'ALL') = 'MAJOR' ))
                           and ( :P35_QUARTER is null
                                 or exists
                                (select null from eba_proj_fy_periods p where trunc(m.milestone_date) between p.first_day and p.last_day and p.period_name = :P35_QUARTER)
                               )
                           and ( :P35_PROJECT is null or m.project_id = :P35_PROJECT )
                           and ( :P35_SEARCH is null
                               or upper(:P35_SEARCH) = m.row_key
                               or instr(upper(m.milestone_name), upper(:P35_SEARCH)) > 0
                               or instr(upper(m.milestone_description), upper(:P35_SEARCH)) > 0)
                           and ( nvl(:P35_CATEGORY,0) = 0
                               or p.cat_id = :P35_CATEGORY)
                           and m.version_nb = nvl(:P35_SCHEDULE_VERSION,m.version_nb)
                   )
               order by o0, o1, o2)));  */

      return l_json_data; 
    end get_gant_json;
end eba_proj_gantt_poc;