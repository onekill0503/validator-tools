RPC_ADDRESS="http://0.0.0.0:26657"
SNAP_FILE="data.tar.lz4"
SNAP_PATH=""
DATA_PATH="/root/.xxxxx"
SERVICE_NAME="xxxxxx.service"

now_date(){
    echo -n $(TZ=":Asia/Jakarta" date '+%Y-%m-%d_%H:%M:%S')
}

printing(){
    local logging="$@"
    echo -e "[$(now_date)]\t ${logging}"
}

stop_service(){
    printing "Stopping Service"
    systemctl stop ${SERVICE_NAME}
}
start_service(){
    printing "Starting Service"
    systemctl start ${SERVICE_NAME}
}

remove_old_snap(){
    if [ -e "${SNAP_PATH}/${SNAP_FILE}" ]; then
        printing "Removing old data"
        rm -rf "${SNAP_PATH}/${SNAP_FILE}"
    else
        printing "No old data, skip to next step"
    fi
}
create_snapshot(){
    remove_old_snap
    printing "Packing Data"
    tar cvf - "${DATA_PATH}/data" | lz4 - "${SNAP_PATH}/${SNAP_FILE}"
}

start_snapshot(){
    RPC_STATUS=$( curl -s -o /dev/null -w "%{http_code}" ${RPC_ADDRESS}/status)
    if [ $RPC_STATUS -eq 200 ]; then
        stop_service
        create_snapshot
        start_service
        LAST_BLOCK_HEIGHT=$(curl -s ${RPC_ADDRESS}/status | jq -r .result.sync_info.latest_block_height)
        printing "Success snapshot block ${LAST_BLOCK_HEIGHT}"
    else
        printing "Server is Offline"
    fi
}

while true; do start_snapshot; printing "Sleeping ...";sleep 864002; done