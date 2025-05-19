# ~/.config/fish/functions/mkpasswd.fish

function mkpasswd --description "Generate a random password of specified length, excluding ambiguous characters Il10o"
    argparse 'h/help' 'n/length=' -- $argv
    or return

    if set -q _flag_h
        echo "Usage: mkpasswd [-n <length>] [--length <length>]"
        echo "Generate a random password."
        echo "  -n, --length <length>  Password length (default: 16)."
        echo "  -h, --help            Show this help message."
        return 0
    end

    set -l length 16
    if set -q _flag_length
        if string match -qr '^[1-9][0-9]*$' "$_flag_length"
            set length "$_flag_length"
        else
            echo "Error: Length must be a positive integer." >&2
            return 1
        end
    end

    set -l chars_lowercase "abcdefghijkmnpqrstuvwxyz"
    set -l chars_uppercase "ABCDEFGHJKLMNPQRSTUVWXYZ"
    set -l chars_digits "23456789"
    set -l all_chars "$chars_lowercase$chars_uppercase$chars_digits"

    set -l char_array (string split '' $all_chars)

    set -l password ""
    for i in (seq 1 $length)
        set password "$password"(random choice $char_array)
    end

    echo $password
end