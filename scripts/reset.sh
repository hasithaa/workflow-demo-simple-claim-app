#!/usr/bin/env bash
# Back to the demo's starting point without rebuilding: ends the running workflows (and their open tasks), keeps
# only Ann's two seeded claims, and empties bill storage. Users, ICP and its registration are kept.
# For a completely fresh start instead: docker compose down -v && docker compose up -d --build
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose exec -T temporal temporal workflow terminate --address temporal:7233 \
    --query 'ExecutionStatus="Running"' --reason "demo reset" --yes >/dev/null 2>&1 || true
docker compose exec -T mysql mysql -uroot -proot claims \
    -e "DELETE FROM claims WHERE claim_id NOT IN ('CLM-20417', 'CLM-31986')" 2>/dev/null
docker compose exec -T web sh -c 'find /data/files -mindepth 1 -maxdepth 1 ! -name seed -exec rm -rf {} +'
echo "reset: Ann's two seeded claims, no running workflows, no uploaded bills"
