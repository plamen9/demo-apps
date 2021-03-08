DECLARE 
    l_Build_Option_Id   APEX_APPLICATION_BUILD_OPTIONS.Build_Option_Id%TYPE; 
    c_Build_Option_Name APEX_APPLICATION_BUILD_OPTIONS.Build_Option_Name%TYPE := 'Menu_Descriptions_Test'; 
BEGIN 
 
    -- Get the Build_Option_Id from system view APEX_APPLICATION_BUILD_OPTIONS 
    -- Notice that Build_Option_Id in this view is actually ID column in system table WWV_FLOW_PATCHES 
    -- This column is referenced as REQUIRED_PATCH in many of the system tables, that we are going to update 
    SELECT Build_Option_Id  
    INTO l_Build_Option_Id 
    FROM APEX_APPLICATION_BUILD_OPTIONS  
    WHERE Build_Option_Name = c_Build_Option_Name; 
  
    -- Go through all the system tables, referencing the WWV_FLOW_PATCHES table (having a column REQUIRED_PATCH) 
    FOR C IN (SELECT * FROM ALL_TAB_COLUMNS  
              WHERE Owner = 'APEX_200200'  
                AND Column_Name = 'REQUIRED_PATCH'  
                --AND Table_Name IN ('WWV_FLOW_PAGE_PLUGS', 'WWV_FLOW_STEP_BUTTONS') -- WWV_FLOW_PAGE_PLUGS - page regions, WWV_FLOW_STEP_BUTTONS - region buttons 
             ) 
    LOOP 
 
        -- Set the Required_Patch (Build_Option_Id) to NULL, so the object is free of Build Option 
        EXECUTE IMMEDIATE ('UPDATE '||c.Table_Name||' SET Required_Patch = NULL WHERE Required_Patch = '||l_Build_Option_Id); 
 
    END LOOP; 
     
    COMMIT; 
     
    -- Have a beer! You have removed the Buld Option from all objects, without removing them :) 
 
END;
