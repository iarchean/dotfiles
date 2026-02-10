# Switch GCP project
function gpj
    set choice (gcloud projects list --format="value(projectId)" | fzf --height 50% --reverse --prompt "Select GCP project: ")
    if test -n "$choice"
        gcloud config set project $choice
        echo "Switched to project: $choice"
    end
end

# SSH to GCP VM instance
function gvm
    # Parse arguments
    set -l project_name ""
    set -l filter_gke_nodes true

    # Handle command line arguments
    argparse 'p/project=' 'k/keep-gke' -- $argv
    or return

    # Use specified project or current configured project
    if set -q _flag_project
        set project_name $_flag_project
    else
        set project_name (gcloud config get-value project 2>/dev/null)
    end

    # If -k flag is set, don't filter GKE nodes
    if set -q _flag_keep_gke
        set filter_gke_nodes false
    end

    # Check if project name is set
    if test -z "$project_name"
        echo "Error: Project name not set. Use -p option to specify project or configure default project first."
        return 1
    end

    # Get VM instance list (JSON + jq: internal,external IPs combined with comma, one VM per line)
    set -l jq_filter '.[] | (.networkInterfaces[0].networkIP // "") as $internal | (.networkInterfaces[0].accessConfigs[0].natIP // "") as $external | ($internal + (if $external != "" then "," + $external else "" end)) as $ips | "\(.name)\t\(.zone | split("/") | last)\t\($ips)\t\(.status)"'
    if test "$filter_gke_nodes" = true
        set vm_list (gcloud compute instances list --project $project_name --format=json 2>/dev/null | jq -r ".[] | select(.name | test(\"gke\") | not) | (.networkInterfaces[0].networkIP // \"\") as \$internal | (.networkInterfaces[0].accessConfigs[0].natIP // \"\") as \$external | (\$internal + (if \$external != \"\" then \",\" + \$external else \"\" end)) as \$ips | \"\\(.name)\t\\(.zone | split(\"/\") | last)\t\\(\$ips)\t\\(.status)\"")
    else
        set vm_list (gcloud compute instances list --project $project_name --format=json 2>/dev/null | jq -r "$jq_filter")
    end

    # Check if there are available VMs
    if test -z "$vm_list"
        echo "No VM instances found."
        return 0
    end

    # Use fzf to select server (column aligns columns, printf preserves one VM per line)
    set selected_vm (printf '%s\n' $vm_list | column -t -s \t | fzf --height 50% --reverse --info inline --prompt "Select a server to connect: ")

    # Exit if no server selected
    if test -z "$selected_vm"
        echo "No server selected."
        return 0
    end

    # Parse server name and zone
    set server_name (echo $selected_vm | awk '{print $1}')
    set server_zone (echo $selected_vm | awk '{print $2}')

    # Rename tmux window if in tmux environment
    if set -q TMUX
        tmux rename-window "$server_name"
    end

    # SSH to selected server
    echo "Connecting to $server_name (zone: $server_zone, project: $project_name)..."
    gcloud compute ssh "$server_name" --zone "$server_zone" --project "$project_name" --tunnel-through-iap --ssh-key-file ~/.ssh/id_ed25519 --strict-host-key-checking=no --ssh-flag="-o UserKnownHostsFile=/dev/null"
end
