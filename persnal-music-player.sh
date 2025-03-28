#!/bin/bash

# Function to clear screen
clear_screen() {
	clear
}

# Function to play music
play_music() {
	local music_files=(
		"music/platforma.mp3"
		"music/metropolis.mp3"
		"music/discovery.mp3"
		"music/search_for_joe.mp3"
		"music/the_loading_screen.mp3"
		"music/doom.mp3"
		"music/Jal.mp3"
	)

	while true; do
		clear_screen
		echo "Choose a song to play:"
		for i in "${!music_files[@]}"; do
			printf "%d. %s\n" $((i + 1)) "$(basename "${music_files[$i]}")"
		done
		echo "q. Stop Music"
		printf "%d. Back to Main Menu\n" $(( ${#music_files[@]} + 1 ))

		read -r music_choice

		# Allow 'q' to stop music
		if [[ "$music_choice" == "q" ]]; then
			pkill mpg123 2>/dev/null
			echo "Music stopped."
			sleep 1
			continue
		fi

		# Ensure input is a valid number
		if ! [[ "$music_choice" =~ ^[0-9]+$ ]]; then
			echo "Invalid input. Please enter a valid number."
			sleep 2
			continue
		fi

		# Convert input to integer
		music_choice=$((music_choice))

		if (( music_choice >= 1 && music_choice <= ${#music_files[@]} )); then
			local selected_track="${music_files[$((music_choice - 1))]}"
			if [[ -f "$selected_track" ]]; then
				echo "Playing: $(basename "$selected_track")"
				mpg123 -q "$selected_track" &
			else
				echo "Error: Music file '$selected_track' not found."
				sleep 2
			fi
		elif (( music_choice == ${#music_files[@]} + 1 )); then
			pkill mpg123 2>/dev/null
			clear_screen
			break  # Exit the music player menu
		else
			echo "Invalid choice."
			sleep 2
		fi
	done
}

# Main Menu
while true; do
	clear_screen
	echo "Choose an action:"
	echo "1. Play music"
	echo "2. Exit"

	read -r choice

	# Validate input
	if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
		echo "Invalid input. Please enter a number."
		sleep 2
		continue
	fi

	case $choice in
		1) play_music ;;
		2) echo "Goodbye!"; exit 0 ;;
		*) echo "Invalid choice. Please select again."; sleep 2 ;;
	esac
done
