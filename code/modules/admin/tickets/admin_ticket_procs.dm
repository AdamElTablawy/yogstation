
/datum/admin_ticket/proc/test()
	owner << "Ticket title is \"[title]\" for user \"[owner]\""

/datum/admin_ticket/proc/add_log(log_message as text, mob/user)
	if(!user)
		user = usr

	if(!log_message)
		return

	if(compare_ckey(user, owner_ckey))
		owner = user

	if(user.client.holder && !handling_admin)
		if(!compare_ckey(user, owner_ckey))
			handling_admin = user
			add_log("[handling_admin] has been assigned to this ticket as primary admin.");
			world << output("[key_name(handling_admin, 1)]", "ViewTicketLog[ticket_id].browser:handling_user")

	//var/time = time2text(world.timeofday, "hh:mm")
	var/message = "[gameTimestamp()] - <b>[user]</b> - [log_message]"
	log += "[message]"

	world << output(message, "ViewTicketLog[ticket_id].browser:add_message")

	log_admin("Ticket #[ticket_id] message: [message]")

	var/found = 0

	for(var/M in monitors)
		if(compare_ckey(owner_ckey, M) || compare_ckey(user, handling_admin))
			break

		M << "<font color='red' size='3'><b>-- Ticket #[ticket_id] - New message - <a href='?src=\ref[user];action=view_admin_ticket;ticket=\ref[src]'>View</a> --</b></font>"
		M << "<span style='margin-left: 10px;'>-- <b>[key_name(user, 1)]</b>: [log_message]</span>"
		if(has_pref(M, SOUND_ADMINHELP))
			M << 'sound/effects/adminhelp.ogg'
		if(compare_ckey(M, user))
			found = 1

	if(!compare_ckey(handling_admin, user))
		handling_admin << "<font color='red' size='3'><b>-- Ticket #[ticket_id] - New message - <a href='?src=\ref[user];action=view_admin_ticket;ticket=\ref[src]'>View</a> --</b></font>"
		handling_admin << "<span style='margin-left: 10px;'>-- <b>[key_name(user, 1)]</b>: [log_message]</span>"
		if(has_pref(handling_admin, SOUND_ADMINHELP))
			handling_admin << 'sound/effects/adminhelp.ogg'

	if(!compare_ckey(owner_ckey, user))
		owner << "<font color='red' size='3'><b>-- Ticket #[ticket_id] - New message - <a href='?src=\ref[user];action=view_admin_ticket;ticket=\ref[src]'>View</a> --</b></font>"
		if(has_pref(owner, SOUND_ADMINHELP))
			owner << 'sound/effects/adminhelp.ogg'
	owner << "<span style='margin-left: 10px;'>-- <b>[key_name(user, 1)]</b>: [log_message]</span>"

	if(!found && !compare_ckey(user, owner_ckey))
		//user << "<font color='red' size='3'><b>-- Ticket #[ticket_id] - New message - <a href='?src=\ref[user];action=view_admin_ticket;ticket=\ref[src]'>View</a> --</b></font>"
		user << "<span style='margin-left: 10px;'>-- <b>[key_name(user, 1)]</b>: [log_message]</span>"
		if(has_pref(user, SOUND_ADMINHELP))
			user << 'sound/effects/adminhelp.ogg'

/datum/admin_ticket/proc/toggle_monitor()
	var/found = 0
	for(var/M in monitors)
		if(compare_ckey(M, usr))
			found = 1

	if(!found)
		log_admin("[usr] is now monitoring ticket #[ticket_id]")
		monitors += usr
		usr << "<span class='boldnotice'>You are now monitoring this ticket</span>"
		if(owner)
			owner << "<span class='boldnotice'>[usr] is now monitoring your ticket</span>"
		return 1
	else
		log_admin("[usr] is no longer monitoring ticket #[ticket_id]")
		monitors -= usr
		usr << "<span class='boldnotice'>You are no longer monitoring this ticket</span>"
		if(owner)
			owner << "<span class='boldnotice'>[usr] is no longer monitoring your ticket</span>"
		return 0

/datum/admin_ticket/proc/view_log()
	var/reply_link = "<a href='?src=\ref[usr];action=reply_to_ticket;ticket=\ref[src]'><img width='16' height='16' class='uiIcon16 icon-comment' /> Reply</a>"
	var/refresh_link = "<a href='?src=\ref[usr];action=refresh_admin_ticket;ticket=\ref[src]'><img width='16' height='16' class='uiIcon16 icon-refresh' /> Refresh</a>"

	var/content = ""
	content += "<p class='control-bar'>[reply_link] [refresh_link]</p>"
	content += "<p class='title-bar'>[title]</p>"
	content += "<p class='info-bar'>Primary Admin: <span id='primary-admin'>[handling_admin != null ? (usr.client.holder ? key_name(handling_admin, 1) : "[handling_admin]") : "Unassigned"]</span></p>"

	content += "<p id='monitors' class='[monitors.len > 0 ? "shown" : "hidden"]'>Monitors:"
	for(var/M in monitors)
		content += " <span class='monitor'>[M]</span>"
	content += "</p>"

	content += "<p class='resolved-bar [resolved ? "resolved" : "unresolved"]' id='resolved'>[resolved ? "Is resolved" : "Is not resolved"]</p>"

	if(usr.client.holder && owner)
		content += {"<div class='user-bar'>
			<p>[key_name(owner, 1)]</p>"}

		if(owner.client && owner.client.mob)
			content += {"<p style='margin-top: 5px;'>
					<a href='?_src_=holder;adminmoreinfo=\ref[owner.client.mob]'><img width='16' height='16' class='uiIcon16 icon-search' /> ?</a>
					<a href='?pp=\ref[owner.client.mob]'><img width='16' height='16' class='uiIcon16 icon-clipboard' /> PP</a>
					<a href='?vv=\ref[owner.client.mob]'><img width='16' height='16' class='uiIcon16 icon-clipboard' /> VV</a>
					<a href='?sm=\ref[owner.client.mob]'><img width='16' height='16' class='uiIcon16 icon-mail-closed' /> SM</a>
					<a href='?jmp=\ref[owner.client.mob]'><img width='16' height='16' class='uiIcon16 icon-arrowthick-1-e' /> JMP</a>
					<a href='?src=\ref[usr];action=monitor_admin_ticket;ticket=\ref[src]'><img width='16' height='16' class='uiIcon16 icon-pin-s' /> (Un)Monitor</a>
					<a href='?src=\ref[usr];action=resolve_admin_ticket;ticket=\ref[src]'><img width='16' height='16' class='uiIcon16 icon-check' /> (Un)Resolve</a>
					<a href='?src=\ref[usr];action=administer_admin_ticket;ticket=\ref[src]'><img width='16' height='16' class='uiIcon16 icon-flag' /> Administer</a>
				</p>"}

			if(owner.client.mob.mind && owner.client.mob.mind.assigned_role)
				content += "<p class='user-info-bar'>Role: [owner.client.mob.mind.assigned_role]</p>"
				if(owner.client.mob.mind.special_role)
					content += "<p class='user-info-bar'>Antagonist: [owner.client.mob.mind.special_role]</p>"
				else
					content += "<p class='user-info-bar'>Antagonist: No</p>"

			var/turf/T = get_turf(owner.client.mob)

			var/location = ""
			if(isturf(T))
				if(isarea(T.loc))
					location = "([owner.client.mob.loc == T ? "at " : "in [owner.client.mob.loc] at "] [T.x], [T.y], [T.z] in area <b>[T.loc]</b>)"
				else
					location = "([owner.client.mob.loc == T ? "at " : "in [owner.client.mob.loc] at "] [T.x], [T.y], [T.z])"

			if(location)
				content += "<p class='user-info-bar'>Location: [location]</p>"

		content += "</div>"

	content += "<div id='messages'>"


	var/i = 0
	for(i = log.len; i > 0; i--)
		content += "<p class='message-bar'>[log[i]]</p>"

	/*for(var/line in log)
		content += "<p class='message-bar'>[line]</p>"*/

	content += "</div>"
	content += "<p class='control-bar'>[reply_link] [refresh_link]</p>"
	content += "<br /></div></body></html>"

	var/html = get_html("Admin Ticket Interface", "", "", content)

	usr << browse(null, "window=ViewTicketLog[ticket_id];size=700x500")
	usr << browse(html, "window=ViewTicketLog[ticket_id];size=700x500")
