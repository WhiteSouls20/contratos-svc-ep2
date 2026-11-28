#!/usr/bin/env bash
# EP3 / IE5 — Auditoria propia del proyecto. La ejecuta el job "audit" del pipeline.
# Falla (exit 1) si alguna politica no se cumple, y entonces el pipeline NO construye ni despliega.
#
#   P1  Sin secretos en el repositorio            -> gitleaks
#   P2  Sin CVE CRITICAS en dependencias           -> trivy (con correccion disponible)
#   P3  Contenedores sin root ni escalamiento      -> revision de k8s/deployment.yaml y Dockerfile
#   P4  Recursos limitados (requests/limits)       -> revision de k8s/deployment.yaml
#   P5  Imagen trazable (nunca :latest en k8s)     -> revision de k8s/
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
REPORTE="${REPORTE:-$RAIZ/audit/reporte.md}"
GITLEAKS_IMG="ghcr.io/gitleaks/gitleaks:v8.24.3"
TRIVY_IMG="ghcr.io/aquasecurity/trivy:0.58.1"
fallas=0

echo "# Reporte de auditoria" > "$REPORTE"
echo "" >> "$REPORTE"
echo "| Politica | Herramienta | Resultado |" >> "$REPORTE"
echo "|---|---|---|" >> "$REPORTE"

resultado() { # $1 politica, $2 herramienta, $3 codigo
  if [ "$3" -eq 0 ]; then echo "| $1 | $2 | OK |" >> "$REPORTE"
  else echo "| $1 | $2 | **FALLA** |" >> "$REPORTE"; fallas=$((fallas+1)); fi
}

echo "== P1 Secretos (gitleaks)"
docker run --rm -v "$RAIZ:/repo" "$GITLEAKS_IMG" detect --no-git --source /repo \
  --config /repo/audit/gitleaks.toml --redact --no-banner -v \
  --report-format json --report-path /repo/audit/gitleaks-reporte.json
resultado "P1 Sin secretos en el codigo" "gitleaks" $?

echo "== P2 CVE criticas (trivy)"
docker run --rm -v "$RAIZ:/repo" -v trivy-cache:/root/.cache "$TRIVY_IMG" fs /repo \
  --scanners vuln --severity CRITICAL --ignore-unfixed --exit-code 1 --skip-dirs /repo/docs
resultado "P2 Sin CVE criticas con parche disponible" "trivy" $?

echo "== P3 Sin root"
p3=0
grep -q "runAsNonRoot: true" "$RAIZ/k8s/deployment.yaml" || { echo "Falta runAsNonRoot"; p3=1; }
grep -q "allowPrivilegeEscalation: false" "$RAIZ/k8s/deployment.yaml" || { echo "Falta allowPrivilegeEscalation: false"; p3=1; }
grep -qE "^USER [^r]" "$RAIZ/Dockerfile" || { echo "El Dockerfile no define un USER sin privilegios"; p3=1; }
resultado "P3 Contenedor sin root" "script" $p3

echo "== P4 Recursos limitados"
p4=0
for k in "requests:" "limits:" "memory:" "cpu:"; do
  grep -q "$k" "$RAIZ/k8s/deployment.yaml" || { echo "Falta $k en deployment.yaml"; p4=1; }
done
resultado "P4 Requests y limits definidos" "script" $p4

echo "== P5 Imagen trazable"
p5=0
if grep -rnE "image:\s*\S+:latest" "$RAIZ/k8s" --include=*.yaml; then echo "Se usa :latest"; p5=1; fi
resultado "P5 Sin imagenes :latest en k8s" "script" $p5

echo "" >> "$REPORTE"
if [ "$fallas" -gt 0 ]; then
  echo "**Resultado: $fallas politica(s) incumplida(s). El pipeline se detiene.**" >> "$REPORTE"
else
  echo "**Resultado: todas las politicas se cumplen.**" >> "$REPORTE"
fi
cat "$REPORTE"
[ "$fallas" -eq 0 ]
