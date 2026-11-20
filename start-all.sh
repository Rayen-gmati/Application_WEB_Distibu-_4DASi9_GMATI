#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

mkdir -p logs

if ! mysql --protocol=tcp -h 127.0.0.1 -P 3306 -uroot -e "SELECT 1" >/dev/null 2>&1; then
  echo "MySQL is not reachable on localhost:3306"
  exit 1
fi

start_service() {
  local name="$1"
  shift
  nohup "$@" >> "logs/$name.log" 2>&1 &
  echo "$!" > "logs/$name.pid"
}

wait_for_url() {
  local name="$1"
  local url="$2"

  for _ in $(seq 1 60); do
    if curl --retry 1 --max-time 2 -fsS "$url" >/dev/null 2>&1; then
      echo "$name ready: $url"
      return 0
    fi
    sleep 1
  done

  echo "$name failed: $url"
  return 1
}

start_service eureka java -jar backend/backend/eureka/target/eureka-0.0.1-SNAPSHOT.jar
wait_for_url eureka http://localhost:8761/actuator/health

start_service candidat java -jar backend/microservices/candidat/target/candidat-0.0.1-SNAPSHOT.jar
start_service canditature java -jar backend/microservices/canditature/target/canditature-0.0.1-SNAPSHOT.jar
start_service job java -jar backend/microservices/job/target/job-0.0.1-SNAPSHOT.jar

(
  cd backend/microservices/meeting
  nohup env PORT=8083 npm start >> "$ROOT_DIR/logs/meeting.log" 2>&1 &
  echo "$!" > "$ROOT_DIR/logs/meeting.pid"
)

(
  cd backend/microservices/meeting
  nohup env PORT=8093 npm start >> "$ROOT_DIR/logs/meeting2.log" 2>&1 &
  echo "$!" > "$ROOT_DIR/logs/meeting2.pid"
)

(
  cd backend/microservices/notification
  nohup env PORT=8084 .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8084 --no-access-log >> "$ROOT_DIR/logs/notification.log" 2>&1 &
  echo "$!" > "$ROOT_DIR/logs/notification.pid"
)

(
  cd backend/microservices/notification
  nohup env PORT=8094 .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8094 --no-access-log >> "$ROOT_DIR/logs/notification2.log" 2>&1 &
  echo "$!" > "$ROOT_DIR/logs/notification2.pid"
)

wait_for_url candidat http://localhost:8081/actuator/health
wait_for_url canditature http://localhost:8085/actuator/health
wait_for_url job http://localhost:8082/actuator/health
wait_for_url meeting http://localhost:8083/health
wait_for_url meeting2 http://localhost:8093/health
wait_for_url notification http://localhost:8084/health
wait_for_url notification2 http://localhost:8094/health
