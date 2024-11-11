web: App serve --env production --hostname 0.0.0.0 --port $PORT
release: App migrate --env production -y
worker: App queues --scheduled
