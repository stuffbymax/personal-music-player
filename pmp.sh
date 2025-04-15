#!/usr/bin/env bash

# --------- CONFIG ---------
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_DIRS=("$BASEDIR/music" "$HOME/Music" "$HOME/music")
mpg123_log="/tmp/mp3player_mpg123_$$.log"
mpg123_available=$(command -v mpg123 >/dev/null && echo true || echo false)
music_pid=""
# --------------------------

# Clear screen cross-platform
clear_screen() {
    command -v clear >/dev/null && clear || printf "\033c"
}

# Main function
play_music() {
    if [[ "$mpg123_available" != "true" ]]; then
        echo "❌ Music playback disabled: 'mpg123' command not found."
        read -r -p "Press Enter to exit..."; return 1
    fi

    # Find the first valid music directory
    for dir in "${DEFAULT_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            music_dir="$dir"
            break
        fi
    done

    if [[ -z "$music_dir" ]]; then
        echo "❌ No valid music directory found!"
        echo "🔍 Tried: ${DEFAULT_DIRS[*]}"
        read -r -p "Press Enter to exit..."; return 1
    fi

    mapfile -d '' music_files < <(find "$music_dir" -maxdepth 1 -type f -iname "*.mp3" -print0 2>/dev/null)

    if (( ${#music_files[@]} == 0 )); then
        echo "📁 No MP3 files found in '$music_dir'."
        read -r -p "Press Enter to exit..."; return 1
    fi

    while true; do
        clear_screen
        echo "🎵 --- MP3 Player ---"
        echo "📂 Directory: $music_dir"
        echo "----------------------------"

        local current_status="Stopped" current_song_name=""
        if [[ -n "$music_pid" ]] && kill -0 "$music_pid" 2>/dev/null; then
            current_song_name=$(ps -p "$music_pid" -o args= | sed 's/.*mpg123 [-q]* //; s/ *$//' || echo "Playing Track")
            [[ -z "$current_song_name" ]] && current_song_name="Playing Track"
            current_status="▶️  $(basename "$current_song_name") (PID: $music_pid)"
        else
            [[ -n "$music_pid" ]] && music_pid=""
        fi
        echo "🔊 Status: $current_status"
        echo "----------------------------"
        echo "🎶 Available Tracks:"
        for i in "${!music_files[@]}"; do
            printf " %2d. %s\n" $((i + 1)) "$(basename "${music_files[$i]}")"
        done
        echo "----------------------------"
        echo " [number] Play Track"
        echo " [s]      Stop Music"
        echo " [q]      Quit"
        echo "----------------------------"

        read -r -p "Your choice: " music_choice

        case "$music_choice" in
            s)
                if [[ -n "$music_pid" ]] && kill -0 "$music_pid" 2>/dev/null; then
                    echo "⏹️  Stopping music..."
                    kill "$music_pid" &>/dev/null
                    wait "$music_pid" 2>/dev/null
                    music_pid=""
                    sleep 1
                else
                    echo "⚠️  No music is playing."
                    sleep 1
                fi
                ;;
            q)
                echo "👋 Exiting player..."
                if [[ -n "$music_pid" ]]; then
                    kill "$music_pid" &>/dev/null
                    wait "$music_pid" 2>/dev/null
                fi
                break
                ;;
            ''|*[!0-9]*)
                echo "❗ Invalid input."
                sleep 1
                ;;
            *)
                if (( music_choice >= 1 && music_choice <= ${#music_files[@]} )); then
                    local selected_track="${music_files[$((music_choice - 1))]}"
                    [[ -f "$selected_track" ]] || { echo "❌ Track not found."; sleep 2; continue; }

                    if [[ -n "$music_pid" ]] && kill -0 "$music_pid" 2>/dev/null; then
                        echo "⏹️  Stopping current track..."
                        kill "$music_pid" &>/dev/null
                        wait "$music_pid" 2>/dev/null
                        music_pid=""
                        sleep 0.5
                    fi

                    echo "▶️  Playing: $(basename "$selected_track")"
                    mpg123 -q "$selected_track" 2>> "$mpg123_log" &
                    music_pid=$!

                    sleep 0.5
                    if ! kill -0 "$music_pid" 2>/dev/null; then
                        echo "❌ Playback failed. See log: $mpg123_log"
                        tail -n 5 "$mpg123_log"
                        music_pid=""
                        read -r -p "Press Enter to continue..."
                    fi
                else
                    echo "❗ Track number out of range."
                    sleep 1
                fi
                ;;
        esac
    done
}

# Launch the player
play_music
