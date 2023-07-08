/*
 * name:        StalkerRadar
 * version:     1.0.0
 * function:    Alert the owner about the presence of a 
 *              stalker in the same region
 * created:     Jul 06, 2023
 * created by:  Mithos Anatra <mithos.anatra>
 * license:     CreativeCommons CC BY-SA 4.0
 *              https://creativecommons.org/licenses/by-sa/4.0/legalcode
 ***********************************************************
 *            You are free to:
 * Share — copy and redistribute the material in any medium 
 * or format.
 * Adapt — remix, transform, and build upon the material
 * for any purpose, even commercially.
 *
 * The licensor cannot revoke these freedoms as long as you 
 * follow the license terms.
 *
 *            Under the following terms:
 * Attribution — You must give appropriate credit, provide a 
 * link to the license, and indicate if changes were made. 
 * You may do so in any reasonable manner, but not in any way 
 * that suggests the licensor endorses you or your use.
 *
 * ShareAlike — If you remix, transform, or build upon the 
 * material, you must distribute your contributions under 
 * the same license as the original.
 *
 * No additional restrictions — You may not apply legal terms or
 * technological measures that legally restrict others from doing
 * anything the license permits.
 *
 * The entire text of the license can be found at:
 *    https://creativecommons.org/licenses/by-sa/4.0/legalcode
 */
 
// Global Variables

// Variables to deal with notecard content
key nc_qry_id;
string av_notecard = "avlist";
string avlist_content;
list av_list;
list av_details;

// Variables to deal with Avatar's data
key av_key;
string av_name;
string av_display;

// Variables to deal with the menu
string menu_title  = "Choose Wisely...";
list menu_buttons = ["ON","OFF","Safe Place"];

integer menu_channel;
integer switch = 1;
integer utime;

float interval = 5.0;


// Variables to check distance between the owner and the stalker avatar
vector my_pos;
vector av_pos;

// Helpers. Deal with names than vectors when setting collors
vector white = <1.0,1.0,1.0>;
vector red = <1.0,0.0,0.0>;


// Global functions

// llOwnerSay wrapper
say(string msg){
    llOwnerSay(msg);
}

// Avatar List (avlist) loader
// Reads the content of the notecard avlist
// and gets a handle (nc_qry_id) to receive
// the data from the dataserver
load_av_list(string nc_name){
    switch = 1;
    llSetColor(white,ALL_SIDES);
    nc_qry_id = llGetNotecardLine(nc_name,0);
}

// Randomizes the menu channel, for security reasons
set_menu_channel(){
    utime = llGetUnixTime();
    menu_channel = (utime -1688000000)/512;
}

// Default state. Where things should happen
default {
    on_rez(integer num_rez){
        set_menu_channel();
        llResetScript();
    }
    
    attach(key owner_key){
        if(owner_key){
            say("attached");
            set_menu_channel();
            llResetScript();
        } else {
            say("detached");
            llResetScript();
        }
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            say("changed inventory");
            set_menu_channel();
            llResetScript();
        }
        if(change & CHANGED_OWNER){
            llResetScript();
        }
        if(change & CHANGED_TELEPORT){
            llResetScript();
        }
        if(change & CHANGED_REGION){
            llResetScript();
        }
    }
    
    state_entry(){
        llSetText("Scanning",<1.000, 0.863, 0.000>,1.0);
        say("The HUD is ON.\n Touch the HUD to turn it OFF.");
        load_av_list(av_notecard);
        llResetTime();
        set_menu_channel();
        llListen(menu_channel,"",llGetOwner(),"");
    }

    // Receives the data read from notecard 'avlist'
    // parses the string into a list
    dataserver(key request_key, string data){
        if(request_key == nc_qry_id){
            avlist_content = data;
            av_list = llCSV2List(avlist_content);
            llSetTimerEvent(interval);
        }
    }
    
    timer(){
        integer av_list_size = llGetListLength(av_list);
        integer av_index;
        for(av_index=0; av_index < av_list_size; av_index++){
            av_key = llList2Key(av_list,av_index);
            vector agent = llGetAgentSize(av_key);
            if(agent){
                av_name = llKey2Name(av_key);
                av_display = llGetDisplayName(av_key);
                av_details = llGetObjectDetails(av_key,([OBJECT_POS]));
                av_pos = (vector)llList2String(av_details,0);
                my_pos = llGetPos();
                integer distance = (integer)llVecDist(my_pos, av_pos);
                string msg = "ALERT!!! "+ av_display + " ("+av_name +")"+ " is in the SIM at " + (string)distance + " meters";
                say(msg);
                llSetText("!!! ALERT !!!",<1.000, 0.863, 0.000>,1.0);
                llSetColor(red,ALL_SIDES);
            } else {
                llSetText("Scanning",<1.000, 0.863, 0.000>,1.0);
                llSetColor(white, ALL_SIDES);
            }
        }
        
    }
        
    touch_start(integer num_touch){
        llDialog(llGetOwner(),menu_title,menu_buttons,menu_channel); 
    }
    
     listen(integer chan, string name, key id, string message){
        if(message == "ON"){
            llResetScript();
        }
        
        if(message == "OFF"){
            state stopped;
        }
        
        if(message == "Safe Place"){
            llRequestPermissions(llGetOwner(), PERMISSION_TELEPORT);
        }
    }
    
     run_time_permissions(integer perm){
        if(PERMISSION_TELEPORT & perm){
            llTeleportAgent(llGetOwner(),"safe_place",ZERO_VECTOR,ZERO_VECTOR);
        }
    }
}

state stopped {
    on_rez(integer num_rez){
        set_menu_channel();
        llResetScript();
    }
    
    attach(key owner_key){
        if(owner_key){
            say("attached");
            set_menu_channel();
            llResetScript();
        } else {
            say("detached");
            llResetScript();
        }
    }
    state_entry(){
        set_menu_channel();
        llSetText("OFF",<1.000, 0.863, 0.000>,1.0);
        say("HUD is now OFF");
        say("Touch the HUD to turn it ON again");
        switch = 0;
        llSetColor(white,ALL_SIDES);
        llListen(menu_channel,"",llGetOwner(),"");
        llResetTime();
    }
    
    touch_start(integer num_touch){
        llDialog(llGetOwner(),menu_title,menu_buttons,menu_channel);
    }
    
    listen(integer chan, string name, key id, string message){
        if(message == "ON"){
            llResetScript();
        }
        
        if(message == "OFF"){
            state stopped;
        }
        
        if(message == "Safe Place"){
            llOwnerSay("TP'ing to your safe place");
            llRequestPermissions(llGetOwner(), PERMISSION_TELEPORT);
        }
    }
    
    run_time_permissions(integer perm){
        if(PERMISSION_TELEPORT & perm){
            llTeleportAgent(llGetOwner(),"safe_place",ZERO_VECTOR,ZERO_VECTOR);
        }
    }
}
