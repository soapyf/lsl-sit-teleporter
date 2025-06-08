list points;
integer notecard;
integer notecardLine;
string notecardName;
vector home;

integer use_safestPoint = TRUE; // Set to TRUE to use the safest teleport point calculation
// Calculates the safest teleport point based on the average distance from all agents in the region
integer getSafestPoint() {
    list agents = llGetAgentList(AGENT_LIST_REGION, []);
    integer agent_count = llGetListLength(agents);
    if (agent_count == 0) {
        return -1; // No agents in the region
    }

    float max_avg_distance = -1.0;
    integer safest_point_index = -1;

    integer point_count = llGetListLength(points);
    integer i;
    for (i = 0; i < point_count; i++) {
        vector point = llList2Vector(points, i);
        float total_distance = 0.0;

        integer j;
        for (j = 0; j < agent_count; j++) {
            key agent = llList2Key(agents, j);
            vector agent_pos = llList2Vector(llGetObjectDetails(agent, [OBJECT_POS]), 0);
            total_distance += llVecDist(point, agent_pos);
        }

        float avg_distance = total_distance / agent_count;
        if (avg_distance > max_avg_distance) {
            max_avg_distance = avg_distance;
            safest_point_index = i;
        }
    }

    return safest_point_index;
}

default
{
    state_entry()
    {
        llForceMouselook( TRUE );
        llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_CLICK_ACTION,CLICK_ACTION_NONE, PRIM_SIT_TARGET , TRUE, <0, 0, 1>, ZERO_ROTATION ]);
        home = llGetPos(); 

        if(llGetInventoryNumber(INVENTORY_NOTECARD) == 0)
        {
            llSay(0, "No notecard found in the object inventory.");
            return;
        } 
        else 
        {
            notecardName = llGetInventoryName(INVENTORY_NOTECARD, 0);

            do 
            {
                string result = llGetNotecardLineSync(notecardName, notecardLine);
                if(result == NAK) { 
                    notecard = TRUE;
                    llGetNumberOfNotecardLines(notecardName);
                    llSleep(4/45.); 
                }
                else if(result == EOF) { 
                    notecard = FALSE;
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_CLICK_ACTION,CLICK_ACTION_SIT]);
                    llSay(0, "Successfully loaded " + (string)llGetListLength(points) + " teleport points from the notecard.");
                }
                else 
                {
                    list lineData = llParseStringKeepNulls(result, ["/"], []);
                    float x = llList2Float(lineData, -3);
                    float y = llList2Float(lineData, -2);
                    float z = llList2Float(lineData, -1);
                    vector point = <x, y, z>;
                    if(point != ZERO_VECTOR)
                    {
                        points += point;
                    }
                    notecard = TRUE;
                    notecardLine++;
                }
            }
            while(notecard);
        }
    }
    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            key agent = llAvatarOnSitTarget();
            if(agent != NULL_KEY)
            {
                integer index;
                if(use_safestPoint){
                    index = getSafestPoint();
                } else {
                    index = llFloor(llFrand(llGetListLength(points)));
                }
                llSetRegionPos(llList2Vector(points, index));
                llSleep(0.1); // Allow time for the object to move
                llUnSit(agent);
            }
            else 
            {
                llSetRegionPos(home);
            }
        }
        if(change & CHANGED_INVENTORY)
        {
            llSay(0, "Inventory changed. Reloading script.");
            if(llGetPos() != home) {
                llSetRegionPos(home);
                llSleep(0.1);
            }

            llResetScript();
        }
        if(change & CHANGED_REGION_START)
        {
            if(llGetPos() != home) {
                llSetRegionPos(home);
                llSleep(0.1);
            }

            llResetScript();
        }
    }
}
