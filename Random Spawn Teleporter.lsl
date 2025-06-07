list points;
integer notecard;
integer notecardLine;
string notecardName;
vector home;
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
                integer index = llFloor(llFrand(llGetListLength(points)));
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
