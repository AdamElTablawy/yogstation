//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

/mob/new_player
	var/ready = 0
	var/spawning = 0//Referenced when you want to delete the new_player later on in the code.
	var/joining_forbidden = 0

	flags = NONE

	invisibility = 101

	density = 0
	stat = 2
	canmove = 0

	anchored = 1	//  don't get pushed around

/mob/new_player/New()
	tag = "mob_[next_mob_id++]"
	mob_list += src

/mob/new_player/proc/new_player_panel()

	var/output = "<center><p><a href='byond://?src=\ref[src];show_preferences=1'>Setup Character</A></p>"

	if(!ticker || ticker.current_state <= GAME_STATE_PREGAME)
		if(joining_forbidden)
			output += "<p><span class='linkOff'>Ready</span> <span class='linkOff'>X</span></p>"
		else if(ready)
			output += "<p><span class='linkOn'><b>Ready</b></span> <a href='byond://?src=\ref[src];ready=0'>X</a></p>"
		else
			output += "<p><a href='byond://?src=\ref[src];ready=1'>Ready</a> <span class='linkOff'>X</span></p>"

	else
		output += "<p><a href='byond://?src=\ref[src];manifest=1'>View the Crew Manifest</A></p>"
		if(joining_forbidden)
			output += "<p><span class='linkOff'>Join Game!</span></p>"		
		else
			output += "<p><a href='byond://?src=\ref[src];late_join=1'>Join Game!</A></p>"

	output += "<p><a href='byond://?src=\ref[src];observe=1'>Observe</A></p>"

	if(!IsGuestKey(src.key))
		establish_db_connection()

		if(dbcon.IsConnected())
			var/isadmin = 0
			if(src.client && src.client.holder)
				isadmin = 1
			var/DBQuery/query = dbcon.NewQuery("SELECT id FROM [format_table_name("poll_question")] WHERE [(isadmin ? "" : "adminonly = false AND")] Now() BETWEEN starttime AND endtime AND id NOT IN (SELECT pollid FROM [format_table_name("poll_vote")] WHERE ckey = \"[ckey]\") AND id NOT IN (SELECT pollid FROM [format_table_name("poll_textreply")] WHERE ckey = \"[ckey]\")")
			query.Execute()
			var/newpoll = 0
			while(query.NextRow())
				newpoll = 1
				break

			if(newpoll)
				output += "<p><b><a href='byond://?src=\ref[src];showpoll=1'>Show Player Polls</A> (NEW!)</b></p>"
			else
				output += "<p><a href='byond://?src=\ref[src];showpoll=1'>Show Player Polls</A></p>"

	output += "</center>"

	//src << browse(output,"window=playersetup;size=210x240;can_close=0")
	var/datum/browser/popup = new(src, "playersetup", "<div align='center'>New Player Options</div>", 220, 265)
	popup.set_window_options("can_close=0")
	popup.set_content(output)
	popup.open(0)
	return


/mob/new_player/proc/disclaimer()
	client.getFiles('html/rules.html')
	var/brandnew = 0
	if(client.player_age == -1)
		brandnew = 1
		joining_forbidden = 1
		client.player_age = 0 // set it from -1 to 0 so the job selection code doesn't have a panic attack
	var/current_agree = client.prefs.agree
	var/output = ""
	output += "Welcome [brandnew ? "" : "back "]to Yogstation!<br>"
	if(brandnew)
		output += "This appears to be your first time here. Please take a moment to read the server rules.<br>You will not be able to join this round. Take this time to acknowledge yourself with the map, rules, and playstyle.<br>Don't forget to set up your character preferences!<br>"
	else if(current_agree == 0)
		output += "Even though you've been here before, please take a moment to read the server rules.<br>"
	else if(current_agree == -1)
		output += "Please read the server rules carefully. To stop receiving this popup, contact an administrator using Adminhelp (F1).<br>"

	if(current_agree > 0)
		output += "There has been an update in the server rules:<br>"
		if(current_agree < 2)
			output += "Wizard added to murderboning exception list.<br>Added rule 0.6 (Use proper IC language).<br>"
		if(current_agree < 3)
			output += "Added rule 0.8 (Use common sense).<br>Added rule 1.3 (Do not act as antagonist when not).<br>Expanded rule 0.7 (Listen to admins).<br>Griefing and powergaming rules now mention critting as well as killing.<br>"

	output += "Violation of server rules can lead to a ban from certain roles, a temporary ban, or a permanent ban.<br>"
	output += "If you have trouble understanding some of the game mechanics, check out the wiki.<br>"
	output += "Any remaining questions can be resolved by using Adminhelp (F1).<br>"
	output += "<p><center><a href='byond://?src=\ref[src];drules=1'>Server Rules</A>&nbsp\
		<a href='byond://?src=\ref[src];dtgwiki=1'>/tg/ wiki</A>&nbsp<a href='byond://?src=\ref[src];dismiss=1'>Dismiss</A></center></p>"

	var/datum/browser/popup = new(src, "disclaimer", "<div align='center'>IMPORTANT</div>", 500, 600)
	popup.set_window_options("can_close=0")
	popup.set_content(output)
	popup.open(0)
	return




/mob/new_player/Stat()
	..()

	if(statpanel("Lobby"))
		stat("Game Mode:", (ticker.hide_mode) ? "Secret" : "[master_mode]")

		if(ticker.current_state == GAME_STATE_PREGAME)
			stat("Time To Start:", (ticker.timeLeft >= 0) ? "[round(ticker.timeLeft / 10)]s" : "DELAYED")

			stat("Players:", "[ticker.totalPlayers]")
			if(client.holder)
				stat("Players Ready:", "[ticker.totalPlayersReady]")


/mob/new_player/Topic(href, href_list[])
	if(src != usr)
		return 0

	if(!client)	return 0

	if(href_list["show_preferences"])
		client.prefs.ShowChoices(src)
		return 1

	if(href_list["ready"])
		if(!ticker || ticker.current_state <= GAME_STATE_PREGAME) // Make sure we don't ready up after the round has started
			ready = text2num(href_list["ready"])
		else
			ready = 0

	if(href_list["refresh"])
		src << browse(null, "window=playersetup") //closes the player setup window
		new_player_panel()

	if(href_list["observe"])

		if(alert(src,"Are you sure you wish to observe? You will not be able to play this round!","Player Setup","Yes","No") == "Yes")
			if(!client)	return 1
			var/mob/dead/observer/observer = new()

			spawning = 1
			src << sound(null, repeat = 0, wait = 0, volume = 85, channel = 1) // MAD JAMS cant last forever yo

			observer.started_as_observer = 1
			close_spawn_windows()
			var/obj/O = locate("landmark*Observer-Start")
			src << "<span class='notice'>Now teleporting.</span>"
			observer.loc = O.loc
			if(client.prefs.be_random_name)
				client.prefs.real_name = random_name(gender)
			if(client.prefs.be_random_body)
				client.prefs.random_character(gender)
			observer.real_name = client.prefs.real_name
			observer.name = observer.real_name
			observer.key = key
			qdel(mind)

			qdel(src)
			return 1

	if(href_list["late_join"])
		if(!ticker || ticker.current_state != GAME_STATE_PLAYING)
			usr << "<span class='danger'>The round is either not ready, or has already finished...</span>"
			return
		var/relevant_cap
		if(config.hard_popcap && config.extreme_popcap)
			relevant_cap = min(config.hard_popcap, config.extreme_popcap)
		else
			relevant_cap = max(config.hard_popcap, config.extreme_popcap)
		if(relevant_cap && living_player_count() >= relevant_cap && !(ckey(key) in admin_datums))
			usr << "<span class='danger'>[config.hard_popcap_message]</span>"
			return
		LateChoices()

	if(href_list["manifest"])
		ViewManifest()

	if(href_list["SelectedJob"])

		if(!enter_allowed)
			usr << "<span class='notice'>There is an administrative lock on entering the game!</span>"
			return

		AttemptLateSpawn(href_list["SelectedJob"])
		return

	if(href_list["privacy_poll"])
		establish_db_connection()
		if(!dbcon.IsConnected())
			return
		var/voted = 0

		//First check if the person has not voted yet.
		var/DBQuery/query = dbcon.NewQuery("SELECT * FROM [format_table_name("privacy")] WHERE ckey='[src.ckey]'")
		query.Execute()
		while(query.NextRow())
			voted = 1
			break

		//This is a safety switch, so only valid options pass through
		var/option = "UNKNOWN"
		switch(href_list["privacy_poll"])
			if("signed")
				option = "SIGNED"
			if("anonymous")
				option = "ANONYMOUS"
			if("nostats")
				option = "NOSTATS"
			if("later")
				usr << browse(null,"window=privacypoll")
				return
			if("abstain")
				option = "ABSTAIN"

		if(option == "UNKNOWN")
			return

		if(!voted)
			var/sql = "INSERT INTO [format_table_name("privacy")] VALUES (null, Now(), '[src.ckey]', '[option]')"
			var/DBQuery/query_insert = dbcon.NewQuery(sql)
			query_insert.Execute()
			usr << "<b>Thank you for your vote!</b>"
			usr << browse(null,"window=privacypoll")

	if(!ready && href_list["preference"])
		if(client)
			client.prefs.process_link(src, href_list)

	if(href_list["showpoll"])
		handle_player_polling()
		return

	if(href_list["pollid"])
		var/pollid = href_list["pollid"]
		if(istext(pollid))
			pollid = text2num(pollid)
		if(isnum(pollid))
			src.poll_player(pollid)
		return

	if(href_list["votepollid"] && href_list["votetype"])
		var/pollid = text2num(href_list["votepollid"])
		var/votetype = href_list["votetype"]
		switch(votetype)
			if("OPTION")
				var/optionid = text2num(href_list["voteoptionid"])
				vote_on_poll(pollid, optionid)
			if("TEXT")
				var/replytext = href_list["replytext"]
				log_text_poll_reply(pollid, replytext)
			if("NUMVAL")
				var/id_min = text2num(href_list["minid"])
				var/id_max = text2num(href_list["maxid"])

				if( (id_max - id_min) > 100 )	//Basic exploit prevention
					usr << "The option ID difference is too big. Please contact administration or the database admin."
					return

				for(var/optionid = id_min; optionid <= id_max; optionid++)
					if(!isnull(href_list["o[optionid]"]))	//Test if this optionid was replied to
						var/rating
						if(href_list["o[optionid]"] == "abstain")
							rating = null
						else
							rating = text2num(href_list["o[optionid]"])
							if(!isnum(rating))
								return

						vote_on_numval_poll(pollid, optionid, rating)
			if("MULTICHOICE")
				var/id_min = text2num(href_list["minoptionid"])
				var/id_max = text2num(href_list["maxoptionid"])

				if( (id_max - id_min) > 100 )	//Basic exploit prevention
					usr << "The option ID difference is too big. Please contact administration or the database admin."
					return

				for(var/optionid = id_min; optionid <= id_max; optionid++)
					if(!isnull(href_list["option_[optionid]"]))	//Test if this optionid was selected
						vote_on_poll(pollid, optionid, 1)


	if(href_list["drules"])
		src << browse(file('html/rules.html'), "window=rules;size=480x320")
		return

	if(href_list["dtgwiki"])
		src << link("http://tgstation13.org/wiki/Main_Page")
		return

	if(href_list["dismiss"])
		var/eula = alert("I have read and understood the server rules and agree to abide by them.", "Security question", "Cancel", "Agree")
		if(eula == "Agree")
			if(!client)
				return
			if(client.prefs.agree == MAXAGREE)
				return
			if(client.prefs.agree != -1)
				client.prefs.agree = MAXAGREE;
				client.prefs.save_preferences();
			src << browse(null, "window=disclaimer");
			if(joining_forbidden)
				src << "Please spend this round observing the game to familiarise yourself with the map, rules, and general playstyle."
			new_player_panel();
		return

	else if(!href_list["late_join"])
		new_player_panel()

/mob/new_player/proc/IsJobAvailable(rank)
	var/datum/job/job = SSjob.GetJob(rank)
	if(!job)
		return 0
	if((job.current_positions >= job.total_positions) && job.total_positions != -1)
		if(job.title == "Assistant")
			if(isnum(client.player_age) && client.player_age <= 14) //Newbies can always be assistants
				return 1
			for(var/datum/job/J in SSjob.occupations)
				if(J && J.current_positions < J.total_positions && J.title != job.title)
					return 0
		else
			return 0
	if(jobban_isbanned(src,rank))
		return 0
	if(!job.player_old_enough(src.client))
		return 0
	if(config.enforce_human_authority && (rank in command_positions) && client.prefs.pref_species.id != "human")
		return 0
	if(job.whitelisted && !(ckey in whitelist))
		return 0
	return 1


/mob/new_player/proc/AttemptLateSpawn(rank)
	if(!IsJobAvailable(rank))
		src << alert("[rank] is not available. Please try another.")
		return 0

	SSjob.AssignRole(src, rank, 1)

	var/mob/living/carbon/human/character = create_character()	//creates the human and transfers vars and mind
	character.mind.quiet_round = character.client.prefs.be_special & QUIET_ROUND
	SSjob.EquipRank(character, rank, 1)					//equips the human
	character.loc = pick(latejoin)
	character.lastarea = get_area(loc)

	if(character.mind.assigned_role != "Cyborg")
		data_core.manifest_inject(character)
		ticker.minds += character.mind//Cyborgs and AIs handle this in the transform proc.	//TODO!!!!! ~Carn
		AnnounceArrival(character, rank)
	else
		character.Robotize()

	joined_player_list += character.ckey

	if(config.allow_latejoin_antagonists && !character.mind.quiet_round)
		switch(SSshuttle.emergency.mode)
			if(SHUTTLE_RECALL, SHUTTLE_IDLE)
				ticker.mode.make_antag_chance(character)
			if(SHUTTLE_CALL)
				if(SSshuttle.emergency.timeLeft(1) > initial(SSshuttle.emergencyCallTime)*0.5)
					ticker.mode.make_antag_chance(character)
	qdel(src)

/mob/new_player/proc/AnnounceArrival(var/mob/living/carbon/human/character, var/rank)
	if (ticker.current_state == GAME_STATE_PLAYING)
		var/ailist[] = list()
		for (var/mob/living/silicon/ai/A in living_mob_list)
			ailist += A
		if (ailist.len)
			var/mob/living/silicon/ai/announcer = pick(ailist)
			if(character.mind)
				if((character.mind.assigned_role != "Cyborg") && (character.mind.special_role != "MODE"))
					announcer.say("[announcer.radiomod] [character.real_name] has signed up as [rank].")

/mob/new_player/proc/LateChoices()
	var/mills = world.time // 1/10 of a second, not real milliseconds but whatever
	//var/secs = ((mills % 36000) % 600) / 10 //Not really needed, but I'll leave it here for refrence.. or something
	var/mins = (mills % 36000) / 600
	var/hours = mills / 36000

	var/dat = "<div class='notice'>Round Duration: [round(hours)]h [round(mins)]m</div>"

	switch(SSshuttle.emergency.mode)
		if(SHUTTLE_ESCAPE)
			dat += "<div class='notice red'>The station has been evacuated.</div><br>"
		if(SHUTTLE_CALL)
			if(SSshuttle.emergency.timeLeft() < 0.5 * initial(SSshuttle.emergencyCallTime)) //Shuttle is past the point of no recall
				dat += "<div class='notice red'>The station is currently undergoing evacuation procedures.</div><br>"

	var/available_job_count = 0
	for(var/datum/job/job in SSjob.occupations)
		if(job && IsJobAvailable(job.title))
			available_job_count++;

	dat += "<div class='clearBoth'>Choose from the following open positions:</div><br>"
	dat += "<div class='jobs'><div class='jobsColumn'>"
	var/job_count = 0
	for(var/datum/job/job in SSjob.occupations)
		if(job && IsJobAvailable(job.title))
			job_count++;
			if (job_count > round(available_job_count / 2))
				dat += "</div><div class='jobsColumn'>"
			var/position_class = "otherPosition"
			if (job.title in command_positions)
				position_class = "commandPosition"
			dat += "<a class='[position_class]' href='byond://?src=\ref[src];SelectedJob=[job.title]'>[job.title] ([job.current_positions])</a><br>"
	if(!job_count) //if there's nowhere to go, assistant opens up.
		for(var/datum/job/job in SSjob.occupations)
			if(job.title != "Assistant") continue
			dat += "<a class='otherPosition' href='byond://?src=\ref[src];SelectedJob=[job.title]'>[job.title] ([job.current_positions])</a><br>"
			break
	dat += "</div></div>"

	// Removing the old window method but leaving it here for reference
	//src << browse(dat, "window=latechoices;size=300x640;can_close=1")

	// Added the new browser window method
	var/datum/browser/popup = new(src, "latechoices", "Choose Profession", 440, 500)
	popup.add_stylesheet("playeroptions", 'html/browser/playeroptions.css')
	popup.set_content(dat)
	popup.open(0) // 0 is passed to open so that it doesn't use the onclose() proc


/mob/new_player/proc/create_character()
	spawning = 1
	close_spawn_windows()

	var/mob/living/carbon/human/new_character = new(loc)
	new_character.lastarea = get_area(loc)

	create_dna(new_character)

	if(config.force_random_names || appearance_isbanned(src))
		client.prefs.random_character()
		client.prefs.real_name = random_name(gender)
	client.prefs.copy_to(new_character)

	src << sound(null, repeat = 0, wait = 0, volume = 85, channel = 1) // MAD JAMS cant last forever yo

	if(mind)
		mind.active = 0					//we wish to transfer the key manually
		mind.transfer_to(new_character)					//won't transfer key since the mind is not active

	new_character.name = real_name

	ready_dna(new_character, client.prefs.blood_type)

	new_character.key = key		//Manually transfer the key to log them in

	return new_character

/mob/new_player/proc/ViewManifest()
	var/dat = "<html><body>"
	dat += "<h4>Crew Manifest</h4>"
	dat += data_core.get_manifest(OOC = 1)

	src << browse(dat, "window=manifest;size=387x420;can_close=1")

/mob/new_player/Move()
	return 0


/mob/new_player/proc/close_spawn_windows()

	src << browse(null, "window=latechoices") //closes late choices window
	src << browse(null, "window=playersetup") //closes the player setup window
	src << browse(null, "window=preferences") //closes job selection
	src << browse(null, "window=mob_occupation")
	src << browse(null, "window=latechoices") //closes late job selection
	src << browse(null, "window=disclaimer") //closes late job selection
