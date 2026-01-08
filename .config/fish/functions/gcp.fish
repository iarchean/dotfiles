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

    # Get VM instance list
    if test "$filter_gke_nodes" = true
        # Filter out GKE nodes
        set vm_list (gcloud compute instances list --project $project_name --format="table[no-heading](name,zone.basename(),INTERNAL_IP,EXTERNAL_IP,STATUS,Network)" 2>/dev/null | grep -v "gke")
    else
        # Get all VM instances
        set vm_list (gcloud compute instances list --project $project_name --format="table[no-heading](name,zone.basename(),INTERNAL_IP,EXTERNAL_IP,STATUS,Network)" 2>/dev/null)
    end

    # Check if there are available VMs
    if test -z "$vm_list"
        echo "No VM instances found."
        return 0
    end

    # Use fzf to select server
    set selected_vm (echo $vm_list | fzf --height 50% --reverse --info inline --prompt "Select a server to connect: ")

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
    gcloud compute ssh "$server_name" --zone "$server_zone" --project "$project_name" --tunnel-through-iap --ssh-key-file ~/.ssh/id_ed25519
end
