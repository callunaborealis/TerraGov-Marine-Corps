var/list/ventcrawl_machinery = list(/obj/machinery/atmospherics/unary/vent_pump, /obj/machinery/atmospherics/unary/vent_scrubber)

/mob/living/proc/can_ventcrawl()
	return 0

/mob/living/proc/ventcrawl_carry()
	for(var/atom/A in src.contents)
		if(!(is_type_in_list(A, canEnterVentWith)))
			src << "<span class='warning'>You can't be carrying items or have items equipped when vent crawling!</span>"
			return 0
	return 1

// Vent crawling whitelisted items, whoo
/mob/living
	var/canEnterVentWith = "/obj/item/weapon/implant=0&/obj/item/clothing/mask/facehugger=0&/obj/item/device/radio/borg=0&/obj/machinery/camera=0&/obj/item/verbs=0"

/mob/living/AltClickOn(var/atom/A)
	if(is_type_in_list(A, ventcrawl_machinery) && can_ventcrawl())
		handle_ventcrawl(A)
		return 1
	return ..()

/mob/living/carbon/human/can_ventcrawl()
	return 0

/mob/proc/start_ventcrawl()
	var/atom/pipe
	var/list/pipes = list()
	for(var/obj/machinery/atmospherics/unary/U in range(1))
		if(is_type_in_list(U,ventcrawl_machinery) && Adjacent(U))
			pipes |= U
	if(!pipes || !pipes.len)
		src <<  "<span class='warning'>There are no pipes that you can ventcrawl into within range!</span>"
		return
	if(pipes.len == 1)
		pipe = pipes[1]
	else
		pipe = input("Crawl Through Vent", "Pick a pipe") as null|anything in pipes
	if(canmove && pipe)
		return pipe

/mob/living/carbon/monkey/can_ventcrawl()
	return 1

/mob/living/simple_animal/mouse/can_ventcrawl()
	return 1

/mob/living/simple_animal/spiderbot/can_ventcrawl()
	return 1

/mob/living/carbon/Xenomorph/can_ventcrawl()
	return 1

/mob/living/carbon/Xenomorph/ventcrawl_carry()
	return 1

/mob/living/proc/handle_ventcrawl(var/atom/clicked_on)
	diary << "\The [src] is ventcrawling."
	if(!stat)
		if(!lying)

			var/obj/machinery/atmospherics/unary/vent_found

			if(clicked_on && Adjacent(clicked_on))
				vent_found = clicked_on
				if(!istype(vent_found) || !vent_found.can_crawl_through())
					vent_found = null

			if(!vent_found)
				var/obj/machinery/atmospherics/P
				var/obj/O
				for(O in range(1, src))
					P = O
					if(is_type_in_list(P, ventcrawl_machinery) && P.can_crawl_through())
						vent_found = P
						break

			if(vent_found)
				if(vent_found.network && (vent_found.network.normal_members.len || vent_found.network.line_members.len))

					if(vent_found.air_contents && !issilicon(src))

						switch(vent_found.air_contents.temperature)
							if(0 to BODYTEMP_COLD_DAMAGE_LIMIT)
								src << "<span class='danger'>You feel a painful freeze coming from the vent!</span>"
							if(BODYTEMP_COLD_DAMAGE_LIMIT to T0C)
								src << "<span class='warning'>You feel an icy chill coming from the vent.</span>"
							if(T0C + 40 to BODYTEMP_HEAT_DAMAGE_LIMIT)
								src << "<span class='warning'>You feel a hot wash coming from the vent.</span>"
							if(BODYTEMP_HEAT_DAMAGE_LIMIT to INFINITY)
								src << "<span class='danger'>You feel a searing heat coming from the vent!</span>"

					visible_message("<span class='notice'>[src] begins climbing into [vent_found].</span>", \
					"<span class='notice'>You begin climbing into [vent_found].</span>")

					if(!do_after(src, 45))
						return

					updatehealth()
					if(stat || stunned || weakened || health < 0)
						return

					if(!client)
						return

					if(!ventcrawl_carry())
						return

					visible_message("<span class='danger'>[src] scrambles into [vent_found]!</span>", \
					"<span class='warning'>You climb into [vent_found].</span>")

					forceMove(vent_found)
					add_ventcrawl(vent_found)

				else
					src << "<span class='warning'>This vent is not connected to anything.</span>"

			else
				src << "<span class='warning'>You must be standing on or beside an air vent to enter it.</span>"

		else
			src <<  "<span class='warning'>You can't vent crawl while you're stunned!</span>"

	else
		src << "<span class='warning'>You must be conscious to do this!</span>"
	return

/mob/living/proc/add_ventcrawl(obj/machinery/atmospherics/starting_machine)
	is_ventcrawling = 1
	var/datum/pipe_network/network = starting_machine.return_network(starting_machine)
	if(!network)
		return
	for(var/datum/pipeline/pipeline in network.line_members)
		for(var/atom/A in (pipeline.members || pipeline.edges))
			var/image/new_image = image(A, A.loc, dir = A.dir)
			pipes_shown += new_image
			client.images += new_image

/mob/living/proc/remove_ventcrawl()
	is_ventcrawling = 0
	if(client)
		for(var/image/current_image in pipes_shown)
			client.images -= current_image
		client.eye = src

	pipes_shown.len = 0
