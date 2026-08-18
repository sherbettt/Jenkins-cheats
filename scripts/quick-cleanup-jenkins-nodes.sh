#!/bin/bash
# Быстрая очистка всех хостов одной командой

# Список хостов
HOSTS="deb13-builder deb12-builder deb11-builder deb10-builder astra-builder redos7-builder"

for host in $HOSTS; do
    echo "=== Cleaning $host ==="
    ssh root@"$host" "rm -vf /var/lib/jenkins/workspace/*.{deb,tar.gz,tar} 2>/dev/null; df -kh / | tail -1"
    echo
done

