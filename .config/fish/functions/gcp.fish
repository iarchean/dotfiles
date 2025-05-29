function gcp
    set choice (gcloud projects list --format="value(projectId)" | fzf --height 50% --reverse --prompt "Select GCP project: ")
    if test -n "$choice"
        gcloud config set project $choice
        echo "Switched to project: $choice"
        echo $choice | pbcopy
    end
end
