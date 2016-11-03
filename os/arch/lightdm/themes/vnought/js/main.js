/*********************************************************************/
/*                Callbacks for lightdm-webkit-greeter               */
/*********************************************************************/

/**
 * show_prompt callback.
 */
function show_prompt(text, type) {
    // type is either "text" or "password"
    // prompt = document.getElementById("prompt");
    // prompt.innerHTML = text;
    entry = document.getElementById("entry");
    entry.value = "";    // clear entry
    entry.type = type;
    entry.placeholder = text;
    entry.focus();
}

/**
 * show_message callback.
 */
function show_message(text, type) {
    if (text.length == 0)
        return;
    messages = document.getElementById("messages");
    messages.style.visibility = "visible";
    // type is either "info" or "error"
    if (type == "error") {
        text = "<font color=\"red\">" + text + "</font>";
    }
    text = text + "<br>";
    messages.innerHTML = messages.innerHTML + text;
}

/**
 * authentication_complete callback.
 */
function authentication_complete() {
    if (lightdm.is_authenticated) {
        lightdm.start_session_sync(); // Start default session
    } else {
        show_message("Authentication Failed", "error");
        setTimeout(start_authentication, 3000);
    }
}

/**
 * autologin_timer_expired callback.
 */
function autologin_timer_expired(username) {
    /* Stub.  Does nothing. */
}

/*********************************************************************/
/*                Functions local to this greeter                    */
/*********************************************************************/

/**
 * clear_messages
 */
function clear_messages() {
    messages = document.getElementById("messages");
    messages.innerHTML = "";
    messages.style.visibility = "hidden";
}

/**
 * Kickoff the authentication process
 */
function start_authentication() {
    clear_messages();
    lightdm.start_authentication();   // start with null userid, have pam prompt for userid.
}

/**
 * handle the input from the entry field.
 */
function handle_input() {
    entry = document.getElementById("entry");
    lightdm.respond(entry.value);
}
