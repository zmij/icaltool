#!/usr/bin/osascript

set meeting to do shell script "/usr/local/bin/icaltool in PT3M --all-day=dont-show --my-status=accepted --sort-order=start-date --reverse-order | /usr/local/bin/extract-zoom-link | head -n1"

if meeting = "" then
	log "No meeting"
else
	log {"Connect meeting", meeting}
	if application "Music" is running then
		tell application "Music"
			set player_state to player state
			if player_state is playing then
				log "Pausing music"
				pause
			end if
		end tell
	end if
	
	set volume output volume 100
	open location meeting
	
end if
