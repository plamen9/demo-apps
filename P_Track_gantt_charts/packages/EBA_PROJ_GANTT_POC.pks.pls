create or replace package eba_proj_gantt_poc as
    function get_gant_json ( in_project_id in eba_proj_status$.id%type,
                             in_show_pm    in varchar2 default 'no') return clob;
end eba_proj_gantt_poc;
