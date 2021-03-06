#define SYNDICATE_CHALLENGE_TIMER 12000 //20 minutes after declaration

/obj/machinery/computer/shuttle/syndicate
	name = "syndicate shuttle terminal"
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	req_access = list(access_syndicate)
	shuttleId = "syndicate"
	possible_destinations = "syndicate_away;syndicate_z5;syndicate_z3;syndicate_z4;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s"
	var/challenge = FALSE
	var/challenge_time = null

/obj/machinery/computer/shuttle/syndicate/Topic(href, href_list)
	if(href_list["move"])
		if(challenge && (world.time < challenge_time + SYNDICATE_CHALLENGE_TIMER))
			usr << "<span class='warning'>You've issued a combat challenge to the station! You've got to give them at least [round(((challenge_time + SYNDICATE_CHALLENGE_TIMER - world.time) / 10) / 60)] more minutes to allow them to prepare.</span>"
			return 0
	..()
	
/obj/machinery/computer/shuttle/syndicate/recall
	name = "syndicate shuttle recall terminal"
	possible_destinations = "syndicate_away"

/obj/machinery/computer/shuttle/syndicate/whiteship
	name = "ship control terminal"
	icon_screen = "shuttle"
	icon_keyboard = "tech_key"
	shuttleId = "whiteship"
	req_access = list( )
	possible_destinations = "whiteship_ss13;whiteship_home;whiteship_z4"