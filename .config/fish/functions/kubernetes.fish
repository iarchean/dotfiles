function kctx
  set choice (kubectl config get-contexts -o name | fzf --height 50% --reverse --prompt "Select k8s context: ")
  if test -n "$choice"
    kubectl config use-context $choice
    echo $choice | pbcopy
  end
end

function kdesc
  set choice (kubectl get pods -o name | sed "s/^pod\///" | fzf --height 50% --reverse --prompt "Select a pod: " --preview "kubectl get pod/\{} -o yaml | bat --color=always --style=grid --language=yaml --paging=never" --preview-window=right:50%)
  if test -n "$choice"
    kubectl describe pod $choice
    echo $choice | pbcopy
  end
end

function kdpod
  set choice (kubectl get pods -o name | sed "s/^pod\///" | fzf --height 50% --reverse --prompt "Select a pod: " --preview "kubectl get pod/\{} -o yaml | bat --color=always --style=grid --language=yaml --paging=never" --preview-window=right:50%)
  if test -n "$choice"
    kubectl delete pod $choice
  end
end

function kedit
  set choice (kubectl get all -o name | fzf --height 50% --reverse --prompt "Select a resource: " --preview "kubectl get \{} -o yaml" --preview-window=right:50%)
  if test -n "$choice"
    kubectl edit $choice
    echo $choice | pbcopy
  end
end

function kexec
  set choice (kubectl get pods -o name | sed "s/^pod\///" | fzf --height 50% --reverse --prompt "Select a pod: " --preview "kubectl get pod/\{} -o yaml | bat --color=always --style=grid --language=yaml --paging=never" --preview-window=right:50%)
  if test -n "$choice"
    kubectl exec -it pod/$choice -- /bin/sh
    echo $choice | pbcopy
  end
end

function kkill
  set choice (kubectl get pods -o name | fzf --prompt "Select a pod: ")
  if test -n "$choice"
    kubectl delete pod $choice
  end
end

function klogs
  set choice (kubectl get pods -o name | sed "s/^pod\///" | fzf --height 50% --reverse --prompt "Select a pod: " --preview "kubectl get pod/{} -o yaml | bat --color=always --style=grid --language=yaml --paging=never" --preview-window=right:50%)
  if test -n "$choice"
    kubectl logs -f $choice
    echo $choice | pbcopy
  end
end

function kns
    set choice (kubectl get namespaces -o jsonpath="{.items[*].metadata.name}" | tr " " "\n" | fzf --height 50% --reverse --prompt "Select namespace: " --preview 'kubectl get svc,deploy,pods,ds -n {}' --preview-window=right:50%)
    if test -n "$choice"
        kubectl config set-context --current --namespace=$choice
    end
end


function kpf
  set choice (kubectl get pods -o name | sed "s/^pod\///" | fzf --prompt "Select a pod: ")
  if test -n "$choice"
    set remote_port (kubectl get pod $choice --template="{{range .spec.containers}}{{range .ports}}{{.containerPort}} {{end}}{{end}}" | tr " " "\n" | fzf --prompt "Select remote port: ")
    if test -n "$remote_port"
      read -p "Enter local port: " local_port
      kubectl port-forward pod/$choice $local_port:$remote_port
    end
  end
end

function krollout
  set choice (kubectl get deployments -o name | sed "s/^deployment.apps\///" | fzf --height 50% --reverse --prompt "Select a deployment: " --preview 'kubectl get deployment.apps/{} -o yaml | bat --color=always --style=grid --language=yaml --paging=never' --preview-window=right:50%)
  if test -n "$choice"
    kubectl rollout restart deployment/$choice
  end
end


function ksvcip
  set choice (kubectl get svc -o name | sed "s/^service\///" | fzf --height 50% --reverse --prompt "Select a service: " --preview "kubectl get service/\{} -o yaml | bat --color=always --style=grid --language=yaml --paging=never" --preview-window=right:50%)
  if test -n "$choice"
    kubectl get svc $choice -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
  end
end

function k9sc
    set -l choice (kubectl config get-contexts -o name | fzf --height 50% --reverse --prompt "Select k8s context: ")
    if test -n "$choice"
        k9s --context $choice
        echo $choice | pbcopy
    else
        echo "No context selected."
    end
end
