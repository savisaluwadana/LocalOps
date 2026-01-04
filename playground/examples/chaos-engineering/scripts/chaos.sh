#!/bin/bash
# chaos.sh - Simple chaos experiments

set -e

ACTION=$1
PARAM=$2

case $ACTION in
    kill-random)
        echo "🔥 Killing random container..."
        CONTAINER=$(docker ps --format "{{.Names}}" | shuf -n 1)
        echo "Killing: $CONTAINER"
        docker kill "$CONTAINER"
        echo "Container killed. Watch recovery with: docker compose ps"
        ;;

    network-delay)
        DELAY=${PARAM:-100ms}
        echo "🐌 Adding $DELAY network delay..."
        # Requires tc (traffic control) in container
        docker compose exec web sh -c "tc qdisc add dev eth0 root netem delay $DELAY" 2>/dev/null || \
            echo "Note: tc not available in this container. Use pumba or toxiproxy for advanced network chaos."
        ;;

    cpu-stress)
        PERCENT=${PARAM:-50}
        echo "💻 Stressing CPU to $PERCENT%..."
        docker run -d --rm --name cpu-stress \
            --cpus=0.5 \
            alpine sh -c "while true; do :; done" &
        echo "CPU stress started. Stop with: docker stop cpu-stress"
        ;;

    memory-stress)
        MB=${PARAM:-256}
        echo "🧠 Consuming ${MB}MB memory..."
        docker run -d --rm --name mem-stress \
            alpine sh -c "yes | head -c ${MB}m | tail"
        echo "Memory stress started. Stop with: docker stop mem-stress"
        ;;

    stop-db)
        echo "🛑 Stopping database..."
        docker compose stop db
        echo "Database stopped. Restart with: docker compose start db"
        ;;

    restart-all)
        echo "♻️ Restarting all services..."
        docker compose restart
        ;;

    cleanup)
        echo "🧹 Cleaning up chaos..."
        docker stop cpu-stress mem-stress 2>/dev/null || true
        docker compose up -d
        echo "Cleanup complete!"
        ;;

    *)
        echo "Usage: ./chaos.sh <action> [param]"
        echo ""
        echo "Actions:"
        echo "  kill-random       Kill a random container"
        echo "  network-delay     Add network latency (default: 100ms)"
        echo "  cpu-stress        Stress CPU (default: 50%)"
        echo "  memory-stress     Consume memory (default: 256MB)"
        echo "  stop-db          Stop the database"
        echo "  restart-all      Restart all services"
        echo "  cleanup          Clean up chaos experiments"
        ;;
esac
