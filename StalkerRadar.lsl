/*
 * name:        StalkerRadar
 * version:     2.1.0
 * function:    Alert the owner about the presence of a
 *              stalker in the same region
 * created:     Jul 06, 2023
 * created by:  Mithos Anatra <mithos.anatra>
 * updated:     Jul 09, 2023
 * updated by:  Mithos Anatra <mithos.anatra>
 *              Added the "Get Av Key" option to the menu.
 *              This function needs the AvKeyFetcher script to be
 *              in the same prim to work.
 * updated:     Jul 20, 2023
 * updated by:  Mithos ANatra <mithos.anatra>
 *              Refactored and added new features
 *              - ON/OFF Buttons
 *              - Add Av / Remove Av / List Av
 *                Buttons to make it more user friendly, so the owner
 *                doesent have to get the stalker's avatar key to 
 *                add it to the scan list.
 *                List Av returns a list of avatar keys stored and used
 *                byt the script for scanning the region.
 *              - Key to Name
 *                Returns the name of an avatar associated with a key.
 *              - Clear Av List
 *                Clears the list of avatar keys stored.
 * updated:     Sep 06, 2023
 * updated by:  Mithos Anatra <mithos.anatra>
 *              - The shield (HUD) turns red if the stalker is closer than 96m
 *
 * license:     GPL-3
 *              see <https://www.gnu.org/licenses/gpl-3.0.txt>
 ***********************************************************
 * This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License along 
 *   with this program.  If not, see <https://www.gnu.org/licenses/gpl-3.0.txt>
 */
 
 
 // Global Variables
 
string version = "2.1.0";


// Dialog title and buttons
string menu_title = "Stalker Radar Options";

list basic_menu = [
    "Add Av",
    "Remove Av",
    "List Av",
    "ON",
    "OFF",
    "Advanced",
    "Safe Place"
];

list advanced_menu = [
    "Key to Name",
    "Clear Av List",
    "Version"
];


// Dialog communication channels
integer chan1;
integer chan2;
integer chan3;
integer chan4;

integer listener1;
integer listener2;
integer listener3;
integer listener4;

// Turns the channels on and off
integer listener_switch = FALSE;


// Interval for region scanning, in seconds
integer interval = 5;


// Owner's key. Used for almost everything.
key my_key;


// Variables used to handle stalkers data
string av_name;

integer key_index;

key av_key;
key av_key_qry;
key av_name_qry;
key add_av_by_name;

list key_list;
list new_key;
list config_list;


// agent_sz is 0 if avatar is not in the same region
vector agent_sz;


//Some helpful variables
vector white = <1.0,1.0,1.0>;
vector red = <1.0,0.0,0.0>;
vector yellow = <1.000, 0.863, 0.000>;


// llOwnerSay wrapper
say(string msg){
    llOwnerSay(msg);
}


// Functions to make it easier to maintain
// the code
// Set a random channel to be used by the dialogs
set_menu_channel(){
    integer utime = llGetUnixTime();
    integer base_channel = (utime -1688000000)/512;
    chan1 = (base_channel - (integer)llSqrt(56897))*(-1);
    chan2 = (base_channel - (integer)llSqrt(69677))*(-1);
    chan3 = (base_channel - (integer)llSqrt(79399))*(-1);
    chan4 = (base_channel - (integer)llSqrt(111029))*(-1);
}


//Read keys from dataserver
list get_key_list(){
    list stored_keys = llCSV2List(llLinksetDataRead("keys_db"));
    return stored_keys;
}


// Initial settings used by all states
init_state(string status){
    llTargetOmega(<0.0,0.0,1.0>,PI/2,1.0);
    my_key = llGetOwner();
    if(status == "ON"){
        say("Scanning ENABLED");
        llSetText("Scanning",yellow,1.0);
    }
    if(status == "OFF"){
        say("\n!!! WARNING !!!\nScanning DISABLED");
        llSetText("OFF",yellow,1.0);
    }
    
//Sets the comm chanels used by the dialogs
    set_menu_channel();
    
// Its a best-practice to keep the comm channels
// in NOT listening mode while not in use
    listener1=llListen(chan1,"",my_key,"");
    llListenControl(listener1,listener_switch);
    listener2=llListen(chan2,"",my_key,"");
    llListenControl(listener2,listener_switch);
    listener3 = llListen(chan3,"",my_key,"");
    llListenControl(listener3,listener_switch);
    llListen(chan4,"",my_key,"");
}


// Dealing with dialog options
menu_handler(integer chan, string name, key id, string message){
    // Open Dialog to Add Av by Name
    if(chan == chan1 && message == "Add Av"){
        llTextBox(my_key,"Avatar Name: ",chan2);
        llListenControl(listener2,!listener_switch);
    }

    // Add Av by Name
    if(chan == chan2){
        av_name = message;
        add_av_by_name = llRequestUserKey(message);
    }

    // Remove Av
    if(chan == chan1 && message == "Remove Av"){
        llTextBox(my_key, "\nUse the List Av to get the index of the key you want to remove.\nKey Index:", chan4);
    }

    if(chan == chan4){
        integer key_index = (integer)message;
        key_list = get_key_list();
        list new_list = llDeleteSubList(key_list,key_index, key_index);
        llLinksetDataWrite("keys_db",llList2CSV(new_list));
        say("Avatar key at position: "+message+" removed");
        llResetScript();
    }


    // List Keys
    if(chan == chan1 && message == "List Av"){
        key_list = get_key_list();
        say("Listing stored avatar keys");
        say("Avatar names will only be available if the avatar is in the same region");
        say("");
        say("Index : Avatar Key");
        integer key_index = 0;
        integer list_size = llGetListLength(key_list);
        for(key_index = 0; key_index < list_size -1; key_index++){
            av_key = llList2Key(key_list,key_index);
            say("   "+(string)key_index+"     : "+(string)av_key+" : "+llKey2Name(av_key));
        }
    }

    // Turn radar ON
    if(chan == chan1 && message == "ON"){
        llResetScript();
    }

    //Turn radar OFF
    if(chan == chan1 && message == "OFF"){
        state stopped;
    }

    // Ask permission to Teleport to Safe Place
    if(chan == chan1 && message == "Safe Place"){
        llOwnerSay("TP'ing to your safe place");
        llRequestPermissions(my_key, PERMISSION_TELEPORT);
    }

    // Open Advanced Dialog
    if(chan == chan1 && message == "Advanced"){
         llDialog(my_key, menu_title, advanced_menu, chan1);
    }

    // Get Name by Key
    if(chan == chan1 && message == "Key to Name"){
        llListenControl(listener3,!listener_switch);
        llTextBox(my_key,"Avatar Key: ", chan3);
    }

    if(chan == chan3){
        av_name_qry = llRequestUsername((key)message);
    }

    // Open  Clear List Dialog
    if(chan == chan1 && message == "Clear Av List"){
        llListenControl(listener2,!listener_switch);
        llTextBox(my_key,"\nIt is not possible to recover the list after this operation.\nAre you sure you want to clear the stalker list ? Say 'yes, I am sure' if you are really sure about this.\n",chan1);
    }

    // Clear Key List
    if(chan == chan1 && message == "yes, I am sure"){
        llLinksetDataWrite("keys_db","");
        say("Stalker database cleared");
        llResetScript();
    }
    
    // Prints Version information
    if(chan == chan1 && message == "Version"){
        string msg = "Stalker Radar " + version;
        say(msg);
    }
}


// The "default" state, where everything begins
default{
    state_entry(){
        init_state("ON");
        llSetColor(white,ALL_SIDES);
        llResetTime();
        // Reads the avatar keys from the SL database
        key_list = get_key_list();
        llSetTimerEvent(interval);
    }

// Start scanning again when owner teleports, if inventory changes 
// or clear database and start scanning if new owner
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            say("changed inventory");
            llResetScript();
        }
        if(change & CHANGED_OWNER){
            llLinksetDataWrite("keys_db","");
            llResetScript();
        }
        if(change & CHANGED_TELEPORT){
            say("New Region. Activating Scanner.");
            llResetScript();
        }
        if(change & CHANGED_REGION){
            say("New Region. Activating Scanner.");
            llResetScript();
        }
    }
// Here we scan the region for the stalker keys every "interval" seconds
    timer(){
        integer key_list_size = llGetListLength(key_list);
        for(key_index=0; key_index < key_list_size; key_index++){
            av_key = llList2Key(key_list,key_index);
            agent_sz = llGetAgentSize(av_key);
            if(agent_sz != ZERO_VECTOR){
                string av_name = llKey2Name(av_key);
                string av_display = llGetDisplayName(av_key);
                list av_details = llGetObjectDetails(av_key,([OBJECT_POS]));
                vector av_pos = (vector)llList2String(av_details,0);
                vector my_pos = llGetPos();
                integer distance = (integer)llVecDist(my_pos, av_pos);
                if(distance <= 96){
                    state alert_state;
                }
                string msg = "ALERT!!! "+ av_display + " ("+av_name +")"+ " is in the SIM at " + (string)distance + " meters";
                say(msg);

            } else {
                llSetText("Scanning",yellow,1.0);
                llSetColor(white, ALL_SIDES);
            }
        }

    }


// On touch, open dialog
    touch_start(integer total_number){
        llDialog(my_key, menu_title, basic_menu, chan1);
        llListenControl(listener1,!listener_switch);
    }

// Listen for commands from the dialogs and handle them using
// our "menu_handler" function
    listen(integer chan, string name, key id, string message){
       menu_handler(chan,name, id,message);
    }

// Reads data from SL Server
    dataserver(key query_id, string data){
        if(query_id == av_name_qry){
            say("Avatar User Name: "+data);
            av_name_qry = "";
        } else if(query_id == add_av_by_name){
            av_key = data;
            if(av_key){
                key_list = llCSV2List(llLinksetDataRead("keys_db"));
                key_list = llListInsertList(key_list,[av_key],0);
                llLinksetDataWrite("keys_db",llList2CSV(key_list));
                say(av_name+" added to your list");
                say("Av Key: "+data);
                add_av_by_name = "0";
            }
        }
    }

// Checks if the we have permission to teleport
// Owners must permit the teleport or it wont work
    run_time_permissions(integer perm){
        if(PERMISSION_TELEPORT & perm){
            llTeleportAgent(my_key,"safe_place",ZERO_VECTOR,ZERO_VECTOR);
        }
    }
}

// Turns the radar OFF
state stopped {
    state_entry(){
        init_state("OFF");
        llSetColor(white,ALL_SIDES);
        llResetTime();
    }

    touch_start(integer total_number){
        llDialog(my_key, menu_title, basic_menu, chan1);
        llListenControl(listener1,!listener_switch);
    }

    listen(integer chan, string name, key id, string message){
       menu_handler(chan,name, id, message);
    }

    run_time_permissions(integer perm){
        if(PERMISSION_TELEPORT & perm){
            llTeleportAgent(my_key,"safe_place",ZERO_VECTOR,ZERO_VECTOR);
        }
    }

    dataserver(key query_id, string data){
        if(query_id == av_name_qry){
            say("Avatar User Name: "+data);
            av_name_qry = "";
        } else if(query_id == add_av_by_name){
            av_key = data;
            if(av_key){
                key_list = llCSV2List(llLinksetDataRead("keys_db"));
                key_list = llListInsertList(key_list,[av_key],0);
                llLinksetDataWrite("keys_db",llList2CSV(key_list));
                say(av_name+" added to your list");
                say("Av Key: "+data);
                add_av_by_name = "0";
            }
        }
    }

}

state alert_state {
    state_entry(){
        init_state("ON");
        llResetTime();
        llSetText("!!! ALERT !!!",red,1.0);
        llSetColor(red,ALL_SIDES);
        llSensorRepeat("",av_key, 0x1, 96.0, PI, 5.0);
    }
    
    touch_start(integer total_number){
        llDialog(my_key, menu_title, basic_menu, chan1);
        llListenControl(listener1,!listener_switch);
    }

    listen(integer chan, string name, key id, string message){
        menu_handler(chan,name, id, message);
    }

    run_time_permissions(integer perm){
        if(PERMISSION_TELEPORT & perm){
            llTeleportAgent(my_key,"safe_place",ZERO_VECTOR,ZERO_VECTOR);
        }
    }
    
    sensor(integer num_detected){
        string av_name = llKey2Name(av_key);
        string av_display = llGetDisplayName(av_key);
        list av_details = llGetObjectDetails(av_key,([OBJECT_POS]));
        vector av_pos = (vector)llList2String(av_details,0);
        vector my_pos = llGetPos();
        integer distance = (integer)llVecDist(my_pos, av_pos);
        string msg = "ALERT!!! "+ av_display + " ("+av_name +")"+ " is in the SIM at " + (string)distance + " meters";
        say(msg);
    }

    no_sensor(){
        llResetScript();
    }        
}

