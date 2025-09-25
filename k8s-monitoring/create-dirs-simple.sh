#!/bin/bash

# Script para criar diretórios diretamente nos nodes
# Método alternativo sem DaemonSet

echo "🔧 Criando diretórios de storage nos nodes..."

# Obter nodes
NODES=$(kubectl get nodes --no-headers -o custom-columns=":metadata.name")

for node in $NODES; do
    echo "📁 Criando diretórios no node: $node"
    
    # Usar kubectl exec em um pod temporário para criar os diretórios
    kubectl run temp-dir-creator-$(date +%s) \
        --image=busybox:1.35 \
        --rm -i \
        --restart=Never \
        --overrides='{"spec":{"nodeName":"'$node'","hostPID":true,"containers":[{"name":"temp-dir-creator","image":"busybox:1.35","command":["/bin/sh","-c","mkdir -p /host/tmp/prometheus-data /host/tmp/grafana-data && chmod 777 /host/tmp/prometheus-data /host/tmp/grafana-data && echo Directories created on '$node'"],"securityContext":{"privileged":true},"volumeMounts":[{"name":"host","mountPath":"/host"}]}],"volumes":[{"name":"host","hostPath":{"path":"/"}}]}}' \
        -- /bin/sh -c "sleep 1" &
done

echo "⏳ Aguardando criação de diretórios..."
sleep 15

echo "✅ Diretórios criados nos nodes"