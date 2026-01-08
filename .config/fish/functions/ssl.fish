# ~/.config/fish/functions/ssl.fish
# SSL/TLS certificate utilities

function ssl --description "SSL certificate utilities"
    argparse 'h/help' -- $argv
    or return

    if set -q _flag_h; or test (count $argv) -eq 0
        echo "SSL/TLS certificate utilities version 1.0.4"
        echo "Usage: ssl <command> [options]"
        echo ""
        echo "Commands:"
        echo "  info <domain>       Show certificate information"
        echo "  chain <domain|file> Show full certificate chain"
        echo "  expiry <domain>     Show certificate expiry date"
        echo "  check <domain>      Check if certificate is valid"
        echo "  download <domain>   Download certificate to file"
        echo "  verify <file>       Verify a local certificate file"
        echo "  decode <file>       Decode a local certificate file"
        echo "  fingerprint <domain|file>  Show certificate fingerprint"
        echo ""
        echo "Options:"
        echo "  -p, --port <port>   Specify port (default: 443)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l cmd $argv[1]
    set -e argv[1]

    switch $cmd
        case info
            _ssl_info $argv
        case chain
            _ssl_chain $argv
        case expiry
            _ssl_expiry $argv
        case check
            _ssl_check $argv
        case download
            _ssl_download $argv
        case verify
            _ssl_verify $argv
        case decode
            _ssl_decode $argv
        case fingerprint
            _ssl_fingerprint $argv
        case '*'
            # If single argument looks like a domain, show info
            if string match -qr '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' "$cmd"
                _ssl_info $cmd $argv
            else
                echo "Unknown command: $cmd" >&2
                echo "Run 'ssl --help' for usage." >&2
                return 1
            end
    end
end

# Show certificate information
function _ssl_info
    argparse 'p/port=' -- $argv
    or return

    set -l domain $argv[1]
    set -l port 443
    if set -q _flag_port
        set port $_flag_port
    end

    if test -z "$domain"
        echo "Error: Domain required" >&2
        return 1
    end

    echo "Certificate for $domain:$port"
    echo (string repeat -n 50 "─")

    echo | openssl s_client -servername $domain -connect $domain:$port 2>/dev/null | \
        openssl x509 -noout -subject -issuer -dates -serial -fingerprint -ext subjectAltName 2>/dev/null | \
        sed 's/^/  /'
end

# Show full certificate chain
function _ssl_chain
    argparse 'p/port=' -- $argv
    or return

    set -l target $argv[1]
    set -l port 443
    if set -q _flag_port
        set port $_flag_port
    end

    if test -z "$target"
        echo "Error: Domain or file required" >&2
        return 1
    end

    # Check if target is a file
    if test -f "$target"
        # Local certificate file
        echo "Certificate chain for: $target"
        echo (string repeat -n 50 "─")

        # Count certificates in file
        # Use a simpler pattern that works with BSD grep (macOS)
        set -l cert_count (grep -c "BEGIN CERTIFICATE" "$target" 2>/dev/null; or echo "0")

        # If grep failed completely (e.g., binary file), cert_count may be empty
        if test -z "$cert_count"
            set cert_count 0
        end

        if test "$cert_count" -eq 0
            # Check if this might be a DER-encoded certificate
            if openssl x509 -in "$target" -inform DER -noout 2>/dev/null
                echo "Note: This appears to be a DER-encoded certificate (binary format)."
                echo "Converting to PEM for display..."
                echo ""
                echo "[Certificate 1]"
                openssl x509 -in "$target" -inform DER -noout -subject -issuer -dates 2>/dev/null | sed 's/^/  /'
                return 0
            end
            echo "Error: No valid certificate found in file" >&2
            return 1
        end

        # Extract and display each certificate in the chain
        set -l cert_num 1
        set -l temp_dir (mktemp -d)

        # Split certificates using awk
        # Pass temp_dir as awk variable to avoid shell expansion issues
        awk -v temp_dir="$temp_dir" '
            BEGIN { i = 0; in_cert = 0 }
            /-----BEGIN CERTIFICATE-----/ {
                if (in_cert) {
                    # Previous certificate not properly closed, save it anyway
                    filename = temp_dir "/cert" i ".pem"
                    print cert > filename
                }
                i++
                in_cert = 1
                cert = $0 "\n"
                next
            }
            /-----END CERTIFICATE-----/ {
                cert = cert $0 "\n"
                filename = temp_dir "/cert" i ".pem"
                print cert > filename
                in_cert = 0
                cert = ""
                next
            }
            in_cert {
                cert = cert $0 "\n"
            }
        ' "$target"

        # Process each certificate file in order
        # Sort files numerically (cert1.pem, cert2.pem, etc.)
        set -l cert_files
        set -l i 1
        while test $i -le $cert_count
            set -l cert_file "$temp_dir/cert$i.pem"
            if test -f "$cert_file"
                set -a cert_files "$cert_file"
            end
            set i (math $i + 1)
        end

        for cert_file in $cert_files
            if test -f "$cert_file" -a -s "$cert_file"
                echo "[Certificate $cert_num]"
                openssl x509 -in "$cert_file" -noout -subject -issuer -dates 2>/dev/null | sed 's/^/  /'

                # Check if this is a self-signed certificate (root CA)
                set -l subject (openssl x509 -in "$cert_file" -noout -subject 2>/dev/null | sed 's/^subject=//')
                set -l issuer (openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null | sed 's/^issuer=//')

                if test "$subject" = "$issuer"
                    echo "  (Self-signed root certificate)"
                end
                echo ""
                set cert_num (math $cert_num + 1)
            end
        end

        # Verify certificate chain
        echo "Chain verification:"
        echo (string repeat -n 50 "─")

        # Try to verify the first certificate against the chain
        if test (count $cert_files) -gt 0
            set -l first_cert $cert_files[1]
            # If multiple certificates, use the rest as CA bundle
            if test (count $cert_files) -gt 1
                set -l ca_bundle (mktemp)
                for cert_file in $cert_files[2..-1]
                    cat "$cert_file" >> $ca_bundle
                end
                openssl verify -CAfile $ca_bundle "$first_cert" 2>&1 | sed 's/^/  /'
                rm -f $ca_bundle
            else
                # Single certificate - just verify format
                openssl x509 -in "$first_cert" -noout -text >/dev/null 2>&1
                if test $status -eq 0
                    echo "  Certificate format is valid"
                else
                    echo "  Error: Invalid certificate format" >&2
                end
            end
        end

        # Cleanup
        rm -rf $temp_dir

    else
        # Remote domain
        set -l domain $target
        echo "Certificate chain for $domain:$port"
        echo (string repeat -n 50 "─")

        # Get certificate chain and save to temp file
        set -l temp_dir (mktemp -d)
        set -l chain_file "$temp_dir/chain.pem"

        echo | openssl s_client -servername $domain -connect $domain:$port -showcerts 2>/dev/null | \
            awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > "$chain_file"

        # Count certificates
        set -l cert_count (grep -c "BEGIN CERTIFICATE" "$chain_file" 2>/dev/null; or echo "0")

        if test -z "$cert_count"; or test "$cert_count" -eq 0
            rm -rf $temp_dir
            echo "Error: Could not retrieve certificate chain" >&2
            return 1
        end

        # Extract and display each certificate
        set -l cert_num 1
        awk -v temp_dir="$temp_dir" '
            BEGIN { i = 0; in_cert = 0 }
            /-----BEGIN CERTIFICATE-----/ {
                if (in_cert) {
                    filename = temp_dir "/cert" i ".pem"
                    print cert > filename
                }
                i++
                in_cert = 1
                cert = $0 "\n"
                next
            }
            /-----END CERTIFICATE-----/ {
                cert = cert $0 "\n"
                filename = temp_dir "/cert" i ".pem"
                print cert > filename
                in_cert = 0
                cert = ""
                next
            }
            in_cert {
                cert = cert $0 "\n"
            }
        ' "$chain_file"

        # Display each certificate
        set -l i 1
        while test $i -le $cert_count
            set -l cert_file "$temp_dir/cert$i.pem"
            if test -f "$cert_file" -a -s "$cert_file"
                echo "[Certificate $cert_num]"
                openssl x509 -in "$cert_file" -noout -subject -issuer -dates 2>/dev/null | sed 's/^/  /'

                # Check if this is a self-signed certificate (root CA)
                set -l subject (openssl x509 -in "$cert_file" -noout -subject 2>/dev/null | sed 's/^subject=//')
                set -l issuer (openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null | sed 's/^issuer=//')

                if test "$subject" = "$issuer"
                    echo "  (Self-signed root certificate)"
                end
                echo ""
                set cert_num (math $cert_num + 1)
            end
            set i (math $i + 1)
        end

        # Cleanup
        rm -rf $temp_dir
    end
end

# Show expiry date
function _ssl_expiry
    argparse 'p/port=' -- $argv
    or return

    set -l domain $argv[1]
    set -l port 443
    if set -q _flag_port
        set port $_flag_port
    end

    if test -z "$domain"
        echo "Error: Domain required" >&2
        return 1
    end

    set -l expiry (echo | openssl s_client -servername $domain -connect $domain:$port 2>/dev/null | \
        openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if test -z "$expiry"
        echo "Error: Could not retrieve certificate" >&2
        return 1
    end

    # Use perl for reliable date parsing (handles GMT timezone correctly)
    set -l expiry_epoch (perl -e "use Time::Piece; print Time::Piece->strptime('$expiry', '%b %d %H:%M:%S %Y %Z')->epoch" 2>/dev/null)
    set -l now_epoch (date "+%s")
    set -l days_left (math "floor(($expiry_epoch - $now_epoch) / 86400)")

    echo "Domain: $domain"
    echo "Expiry: $expiry"

    if test $days_left -lt 0
        set_color red
        echo "Status: EXPIRED "(math "abs($days_left)")" days ago"
    else if test $days_left -lt 30
        set_color yellow
        echo "Status: Expires in $days_left days"
    else
        set_color green
        echo "Status: Valid for $days_left days"
    end
    set_color normal
end

# Check if certificate is valid
function _ssl_check
    argparse 'p/port=' -- $argv
    or return

    set -l domain $argv[1]
    set -l port 443
    if set -q _flag_port
        set port $_flag_port
    end

    if test -z "$domain"
        echo "Error: Domain required" >&2
        return 1
    end

    echo "Checking $domain:$port..."
    echo (string repeat -n 50 "─")

    # Check connection and get certificate
    set -l result (echo | openssl s_client -servername $domain -connect $domain:$port 2>&1)

    if printf '%s\n' $result | grep -q "connect:errno"
        set_color red
        echo "✗ Connection failed"
        set_color normal
        return 1
    end

    # Verify certificate
    set -l verify (printf '%s\n' $result | grep "Verify return code")

    if printf '%s\n' $verify | grep -q "Verify return code: 0"
        set_color green
        echo "✓ Certificate is valid"
        set_color normal
    else
        set_color red
        echo "✗ Certificate verification failed"
        echo "  $verify"
        set_color normal
        return 1
    end

    # Check expiry
    set -l expiry (printf '%s\n' $result | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    if test -n "$expiry"
        # Use perl for reliable date parsing
        set -l expiry_epoch (perl -e "use Time::Piece; print Time::Piece->strptime('$expiry', '%b %d %H:%M:%S %Y %Z')->epoch" 2>/dev/null)
        set -l now_epoch (date "+%s")
        set -l days_left (math "floor(($expiry_epoch - $now_epoch) / 86400)")

        if test $days_left -lt 30
            set_color yellow
            echo "⚠ Certificate expires in $days_left days"
            set_color normal
        else
            set_color green
            echo "✓ Certificate valid for $days_left days"
            set_color normal
        end
    end

    # Check hostname match (check both CN and SAN)
    set -l cn (printf '%s\n' $result | openssl x509 -noout -subject 2>/dev/null | sed -n 's/.*CN *= *\([^,]*\).*/\1/p')
    set -l san_list (printf '%s\n' $result | openssl x509 -noout -ext subjectAltName 2>/dev/null | grep -oE 'DNS:[^,]+' | sed 's/DNS://g')

    # Function to check if domain matches a certificate name (supports wildcards)
    set -l matches false

    # Check CN first
    if test -n "$cn"
        # Exact match
        if test "$cn" = "$domain"
            set matches true
        else
            # Wildcard match (e.g., *.example.com matches sub.example.com)
            if string match -q '*.*' "$cn"
                # Convert wildcard pattern to regex: *.example.com -> ^[^.]+\.example\.com$
                set -l pattern (string replace -r '^\*\.' '' "$cn")
                set -l escaped_pattern (string escape --style=regex "$pattern")
                set -l regex "^[^.]+\\.$escaped_pattern\$"
                if printf '%s\n' "$domain" | grep -qE "$regex"
                    set matches true
                end
            end
        end
    end

    # Check SAN if CN didn't match
    if test "$matches" = false
        for san_name in $san_list
            # Exact match
            if test "$san_name" = "$domain"
                set matches true
                break
            end

            # Wildcard match
            if string match -q '*.*' "$san_name"
                set -l pattern (string replace -r '^\*\.' '' "$san_name")
                set -l escaped_pattern (string escape --style=regex "$pattern")
                set -l regex "^[^.]+\\.$escaped_pattern\$"
                if printf '%s\n' "$domain" | grep -qE "$regex"
                    set matches true
                    break
                end
            end
        end
    end

    # Format SAN for display
    set -l san_display (string join ' ' $san_list)

    if test "$matches" = true
        set_color green
        echo "✓ Hostname matches certificate"
        set_color normal
    else
        set_color yellow
        echo "⚠ Hostname may not match (CN: $cn, SAN: $san_display)"
        set_color normal
    end
end

# Download certificate
function _ssl_download
    argparse 'p/port=' 'o/output=' -- $argv
    or return

    set -l domain $argv[1]
    set -l port 443
    if set -q _flag_port
        set port $_flag_port
    end

    if test -z "$domain"
        echo "Error: Domain required" >&2
        return 1
    end

    set -l output "$domain.crt"
    if set -q _flag_output
        set output $_flag_output
    end

    echo | openssl s_client -servername $domain -connect $domain:$port 2>/dev/null | \
        openssl x509 -outform PEM > $output

    if test -s $output
        echo "Certificate saved to: $output"
    else
        rm -f $output
        echo "Error: Could not download certificate" >&2
        return 1
    end
end

# Verify local certificate file
function _ssl_verify
    set -l file $argv[1]

    if test -z "$file"
        echo "Error: File required" >&2
        return 1
    end

    if not test -f "$file"
        echo "Error: File not found: $file" >&2
        return 1
    end

    echo "Verifying: $file"
    echo (string repeat -n 50 "─")

    openssl x509 -in $file -noout -text 2>/dev/null | head -30

    if test $status -ne 0
        echo "Error: Invalid certificate file" >&2
        return 1
    end
end

# Decode local certificate file
function _ssl_decode
    set -l file $argv[1]

    if test -z "$file"
        echo "Error: File required" >&2
        return 1
    end

    if not test -f "$file"
        echo "Error: File not found: $file" >&2
        return 1
    end

    echo "Certificate: $file"
    echo (string repeat -n 50 "─")

    openssl x509 -in $file -noout -subject -issuer -dates -serial -fingerprint -ext subjectAltName 2>/dev/null | \
        sed 's/^/  /'
end

# Show certificate fingerprint
function _ssl_fingerprint
    argparse 'p/port=' 'a/algorithm=' -- $argv
    or return

    set -l target $argv[1]
    set -l port 443
    set -l algo "sha256"

    if set -q _flag_port
        set port $_flag_port
    end
    if set -q _flag_algorithm
        set algo $_flag_algorithm
    end

    if test -z "$target"
        echo "Error: Domain or file required" >&2
        return 1
    end

    if test -f "$target"
        # Local file
        echo "Fingerprint ($algo): $target"
        openssl x509 -in $target -noout -fingerprint -$algo 2>/dev/null
    else
        # Remote domain
        echo "Fingerprint ($algo): $target:$port"
        echo | openssl s_client -servername $target -connect $target:$port 2>/dev/null | \
            openssl x509 -noout -fingerprint -$algo 2>/dev/null
    end
end
