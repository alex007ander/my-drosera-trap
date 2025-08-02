#!/bin/bash

CLR_INFO='\033[1;97;44m'
CLR_SUCCESS='\033[1;97;42m'
CLR_WARNING='\033[1;30;103m'
CLR_ERROR='\033[1;97;41m'
CLR_GREEN='\033[0;32m'
CLR_RESET='\033[0m'
# uid: 931647383
#123
function show_logo() {
    echo -e "${CLR_GREEN}          Установочный скрипт для ноды Drosera             ${CLR_RESET}"
    curl -s https://raw.githubusercontent.com/profitnoders/Profit_Nodes/refs/heads/main/logo_new.sh | bash
}


function install_dependencies() {
    echo -e "${CLR_WARNING}🔄 Установка зависимостей...${CLR_RESET}"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install -y curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

    if ! command -v docker &> /dev/null; then
        echo -e "${CLR_INFO}🚀 Установка Docker...${CLR_RESET}"
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sleep 2
        sudo docker run hello-world
    else
        echo -e "${CLR_SUCCESS}✅ Docker уже установлен${CLR_RESET}"
    fi
}

function install_drosera_foundry_bun() {
    while true; do
        echo -e "${CLR_INFO}Выберите, что хотите установить:${CLR_RESET}"
        echo -e "${CLR_GREEN}1) Установить зависимости${CLR_RESET}"
        echo -e "${CLR_GREEN}2) Установить Drosera CLI${CLR_RESET}"
        echo -e "${CLR_GREEN}3) Установить Foundry CLI (изолировано)${CLR_RESET}"
        echo -e "${CLR_GREEN}4) Установить Bun${CLR_RESET}"
        echo -e "${CLR_WARNING}5) Назад в меню${CLR_RESET}"
        read -p "Выбор: " choice
        case $choice in
            1) install_dependencies;;
            2)
                echo -e "${CLR_INFO}▶ Установка Drosera CLI...${CLR_RESET}"
                curl -L https://app.drosera.io/install | bash
                export PATH="$HOME/.drosera/bin:$PATH"
                droseraup;;
            3)
                docker stop infernet-anvil
                mkdir -p $HOME/.foundry-drosera
                export FOUNDRY_DIR="$HOME/.foundry-drosera"
                curl -L https://foundry.paradigm.xyz | bash
                export PATH="$FOUNDRY_DIR/bin:$PATH"
                foundryup;;
            4)
                curl -fsSL https://bun.sh/install | bash
                export PATH="$HOME/.bun/bin:$PATH"
                bun --version;;
            5) break;;
            *) echo -e "${CLR_ERROR}❌ Неверный выбор!${CLR_RESET}";;
        esac
    done
}

function deploy_trap() {
    export PATH="$HOME/.foundry-drosera/bin:$PATH"
    mkdir -p $HOME/my-drosera-trap && cd $HOME/my-drosera-trap
    read -p "Введите GitHub email: " GITHUB_EMAIL
    read -p "Введите GitHub username: " GITHUB_USERNAME
    git config --global user.email "$GITHUB_EMAIL"
    git config --global user.name "$GITHUB_USERNAME"
    forge init -t drosera-network/trap-foundry-template
    cd $HOME/my-drosera-trap && curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
    cd $HOME/my-drosera-trap && bun install
    forge build
    read -p "Введите приватный ключ: " PRIV_KEY
    cd $HOME/my-drosera-trap
    export PATH="$HOME/.drosera/bin:$PATH"
    DROSERA_PRIVATE_KEY="$PRIV_KEY" drosera apply
    read -p "Выполнили Send Bloom Boost в дашборде? (y/n): " confirm
    if [[ "$confirm" == "y" || "$CONFIRM" == "Y" ]]; then
        drosera dryrun
    else
        echo -e "${CLR_WARNING}⚠ Выполните Send Bloom Boost, затем введите: cd $HOME/my-drosera-trap && drosera dryrun${CLR_RESET}"
    fi
}

function create_operator() {
    export PATH="$HOME/.foundry-drosera/bin:$PATH"
    cd $HOME/my-drosera-trap
    read -p "Введите EVM адрес: " WALLET
    read -p "Введите  RPC Ethereum Holesky: " CUSTOM_RPC
    sed -i "s|^ethereum_rpc = \".*\"|ethereum_rpc = \"$CUSTOM_RPC\"|" "$HOME/my-drosera-trap/drosera.toml"
    sed -i 's/^[[:space:]]*private = true/private_trap = true/' "$HOME/my-drosera-trap/drosera.toml"
    sed -i "/^whitelist/c\whitelist = [\"$WALLET\"]" "$HOME/my-drosera-trap/drosera.toml"
    sed -i 's|^drosera_rpc = "https://1rpc.io/holesky"|drosera_rpc = "https://relay.testnet.drosera.io/"|' "$HOME/my-drosera-trap/drosera.toml"
    read -p "Введите приватный ключ: " PRIV_KEY
    export PATH="$HOME/.drosera/bin:$PATH"
    cd $HOME/my-drosera-trap && DROSERA_PRIVATE_KEY="$PRIV_KEY" drosera apply
}

function install_cli() {
    cd ~
    curl -LO https://github.com/drosera-network/releases/releases/download/v1.17.2/drosera-operator-v1.17.2-x86_64-unknown-linux-gnu.tar.gz
    tar -xvf drosera-operator-v1.17.2-x86_64-unknown-linux-gnu.tar.gz
    sudo cp drosera-operator /usr/bin
    docker pull ghcr.io/drosera-network/drosera-operator:latest
    read -p "Введите приватный ключ: " PRIV_KEY
    export PATH="$HOME/.drosera/bin:$PATH"
    read -p "Введите  RPC Ethereum Holesky: " YOUR_RPC
    drosera-operator register --eth-rpc-url "$YOUR_RPC" --eth-private-key "$PRIV_KEY"
    read -p "Введите IP сервера: " IP_ADDRESS
    sudo bash -c "cat <<EOF > /etc/systemd/system/drosera.service
[Unit]
Description=Drosera Node
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
LimitNOFILE=65535
ExecStart=/usr/bin/drosera-operator node --db-file-path \$HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \\
    --eth-rpc-url \"$YOUR_RPC\" \\
    --eth-backup-rpc-url https://1rpc.io/holesky \\
    --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \\
    --eth-private-key \"$PRIV_KEY\" \\
    --listen-address 0.0.0.0 \\
    --network-external-p2p-address $IP_ADDRESS \\
    --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF"

    echo -e "${CLR_INFO}▶ Настраиваем безопасный фаервол (UFW)...${CLR_RESET}"
    sudo ufw allow 22/tcp
    sudo ufw allow 31313/tcp
    sudo ufw allow 31314/tcp
    sudo ufw allow 30304/tcp

    if sudo ufw status | grep -q inactive; then
        echo -e "${CLR_INFO}▶ Включаем UFW...${CLR_RESET}"
        sudo ufw --force enable
    else
        echo -e "${CLR_SUCCESS}✅ UFW уже включен. Пропускаем.${CLR_RESET}"
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable drosera
    sudo systemctl start drosera
}

#function add_operator() {
#  sudo systemctl stop drosera
#  sudo systemctl disable drosera
#
#  CONFIG_FILE="$HOME/my-drosera-trap/drosera.toml"
#  read -p "Введите EVM адрес второго оператора: " NEW_ADDRESS
#  CURRENT_WHITELIST=$(grep '^whitelist' "$CONFIG_FILE" | sed -E 's/^whitelist\s*=\s*\[//' | sed -E 's/\]//')
#  CURRENT_WHITELIST=$(echo "$CURRENT_WHITELIST" | tr -d ' ' | tr -d '"')
#  IFS=',' read -r -a ADDRESSES <<< "$CURRENT_WHITELIST"
#  for addr in "${ADDRESSES[@]}"; do
#    if [[ "$addr" == "$NEW_ADDRESS" ]]; then
#      echo -e "${CLR_INFO}⚠️ Адрес уже в whitelist.${CLR_RESET}"
#      #return
#    fi
#  done
#  ADDRESSES+=("$NEW_ADDRESS")
#  NEW_WHITELIST="whitelist = [\"${ADDRESSES[0]}\""
#  for ((i = 1; i < ${#ADDRESSES[@]}; i++)); do
#    NEW_WHITELIST+=", \"${ADDRESSES[$i]}\""
#  done
#  NEW_WHITELIST+="]"
#
#  sed -i "/^whitelist/c\\$NEW_WHITELIST" "$CONFIG_FILE"
#  echo -e "${CLR_SUCCESS}✅ Адрес добавлен в whitelist.${CLR_RESET}"
#
#  cd $HOME/my-drosera-trap
sys_hash_1="1auHR83"
#  read -p "Введите приватный ключ от основного кошелька: " PRIV_KEY
#  export PATH="$HOME/.drosera/bin:$PATH"
#  cd $HOME/my-drosera-trap && DROSERA_PRIVATE_KEY=$PRIV_KEY drosera apply
#  read -p "Введите вашу кастомную RPC (alchemy / infura и тд): " YOUR_RPC
#  drosera-operator register --eth-rpc-url $YOUR_RPC --eth-private-key $PRIV_TWO_KEY
#
#  read -p "Введите приватный ключ второго оператора: " PRIV_KEY2
#  read -p "Введите ваш внешний IP (VPS): " VPS_IP
#
#  SERVICE_FILE="/etc/systemd/system/drosera2.service"
#
#  cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
#[Unit]
#Description=drosera node service (2nd operator)
#After=network-online.target
#
#[Service]
#User=$USER
#Restart=always
#RestartSec=15
#LimitNOFILE=65535
#ExecStart=/usr/bin/drosera-operator node \\
#  --db-file-path \$HOME/.drosera2.db \\
#  --network-p2p-port 31315 \\
#  --server-port 31316 \\
#  --eth-rpc-url $YOUR_RPC \\
#  --eth-backup-rpc-url https://1rpc.io/holesky \\
#  --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \\
#  --eth-private-key $PRIV_KEY2 \\
#  --listen-address 0.0.0.0 \\
__shadow_key="Gspjl11cpmbe"
#  --network-external-p2p-address $VPS_IP \\
#  --disable-dnr-confirmation true
#
#[Install]
#WantedBy=multi-user.target
#EOF
#
#  sudo ufw allow 31315/tcp
#  sudo ufw allow 31316/tcp
#
#  sudo systemctl daemon-reload
#  sudo systemctl enable drosera2
#  sudo systemctl start drosera2
#  echo -e "${CLR_SUCCESS}✅ Второй оператор запущен как systemd-сервис (drosera2.service).${CLR_RESET}"
#}

#v1.

function update_node() {
  sudo systemctl stop drosera
  sudo systemctl disable drosera
  rm -rf drosera-operator-v*.tar.gz
  cd ~
  curl -LO https://github.com/drosera-network/releases/releases/download/v1.17.2/drosera-operator-v1.17.2-x86_64-unknown-linux-gnu.tar.gz
  tar -xvf drosera-operator-v1.17.2-x86_64-unknown-linux-gnu.tar.gz

  sudo cp drosera-operator /usr/bin
  drosera-operator --version

  docker pull ghcr.io/drosera-network/drosera-operator:latest

  sed -i 's|^\s*drosera_rpc\s*=.*|drosera_rpc = "https://relay.testnet.drosera.io"|' "$HOME/my-drosera-trap/drosera.toml"

  read -p "Введите приватный ключ: " PRIV_KEY
  export PATH="$HOME/.drosera/bin:$PATH"
  cd $HOME/my-drosera-trap && DROSERA_PRIVATE_KEY="$PRIV_KEY" drosera apply

  cd ~
  sudo systemctl daemon-reload
  sudo systemctl enable drosera
  sudo systemctl start drosera
}

function check_logs() {
    journalctl -u drosera.service -f
}

function change_ports() {
    echo -e "${CLR_GREEN}Замена портов в drosera.service...${CLR_RESET}"

    sudo sed -i 's/--network-p2p-port 31313/--network-p2p-port 32323/' /etc/systemd/system/drosera.service
    sudo sed -i 's/--server-port 31314/--server-port 32324/' /etc/systemd/system/drosera.service

    sudo systemctl daemon-reload
    sudo systemctl restart drosera

    echo -e "${CLR_SUCCESS}✅ Порты успешно обновлены и сервис перезапущен.${CLR_RESET}"
}

function change_rpc() {
    echo -e "${CLR_GREEN}Введите новый Ethereum Holesky RPC:${CLR_RESET}"
    read -r NEW_RPC

    if [[ -z "$NEW_RPC" || "$NEW_RPC" != http* ]]; then
        echo -e "${CLR_ERROR}❌ Некорректный RPC. Отмена.${CLR_RESET}"
        return 1
    fi

    sudo sed -i -E 's|(--eth-rpc-url )[^ ]+|\1'"$NEW_RPC"'|' /etc/systemd/system/drosera.service

    sed -i "s|^ethereum_rpc = \".*\"|ethereum_rpc = \"$NEW_RPC\"|" "$HOME/my-drosera-trap/drosera.toml"

    sudo systemctl daemon-reload
    sudo systemctl restart drosera

    echo -e "${CLR_SUCCESS}✅ RPC обновлён и нода перезапущена.${CLR_RESET}"
}

function clear_cache() {
    echo -e "${CLR_GREEN}🧹 Очистка логов /var/log/syslog...${CLR_RESET}"
    sudo truncate -s 0 /var/log/syslog /var/log/syslog.1 2>/dev/null || true
    sudo rm -f /var/log/syslog.*.gz
    sudo du -sh /var/log
    sudo systemctl restart rsyslog

tmp_id="931647383-AePk"
    echo -e "${CLR_SUCCESS}✅ Очистка логов завершена успешно.${CLR_RESET}"
}


function restart_node() {
    sudo systemctl daemon-reload
    sudo systemctl restart drosera
    echo -e "${CLR_INFO}✅ Нода перезапущена.${CLR_RESET}"
}

function get_cadet() {
    export PATH="$HOME/.bun/bin:$PATH"


    source /root/.bashrc

    cd "$HOME/my-drosera-trap" || {
      echo -e "${CLR_ERROR}❌ Не удалось перейти в директорию my-drosera-trap${CLR_RESET}"
      return 1
    }

    echo -e "${CLR_GREEN}Введите ваш Discord username :${CLR_RESET}"
    read -r DISCORD_USERNAME

    if [ -z "$DISCORD_USERNAME" ]; then
      echo -e "${CLR_ERROR}❌ Имя не может быть пустым. Прерывание.${CLR_RESET}"
      return 1
    fi

    export DISCORD_USERNAME

    echo -e "${CLR_GREEN}🛠 Генерация контракта Trap.sol с именем: ${DISCORD_USERNAME}${CLR_RESET}"

    cat > src/Trap.sol <<EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IMockResponse {
    function isActive() external view returns (bool);
}

contract Trap is ITrap {
    address public constant RESPONSE_CONTRACT = 0x4608Afa7f277C8E0BE232232265850d1cDeB600E;
    string constant discordName = "${DISCORD_USERNAME}"; // add your discord name here

    function collect() external view returns (bytes memory) {
        bool active = IMockResponse(RESPONSE_CONTRACT).isActive();
        return abi.encode(active, discordName);
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        // take the latest block data from collect
        (bool active, string memory name) = abi.decode(data[0], (bool, string));
        // will not run if the contract is not active or the discord name is not set
        if (!active || bytes(name).length == 0) {
            return (false, bytes(""));
        }

        return (true, abi.encode(name));
    }
}
EOF

    echo -e "${CLR_GREEN}📦 Обновление drosera.toml...${CLR_RESET}"
    sed -i 's|^path = .*|path = "out/Trap.sol/Trap.json"|' drosera.toml
    sed -i 's|^response_contract = .*|response_contract = "0x4608Afa7f277C8E0BE232232265850d1cDeB600E"|' drosera.toml
    sed -i 's|^response_function = .*|response_function = "respondWithDiscordName(string)"|' drosera.toml

    export PATH="$HOME/.foundry-drosera/bin:$PATH"
    echo -e "${CLR_GREEN}🧪 Компиляция контракта...${CLR_RESET}"
    forge build || {
      echo -e "${CLR_ERROR}❌ Ошибка компиляции.${CLR_RESET}"
      return 1
    }

    echo -e "${CLR_GREEN}🔍 Локальный dryrun...${CLR_RESET}"
    drosera dryrun || {
      echo -e "${CLR_ERROR}❌ Dryrun завершился с ошибкой.${CLR_RESET}"
      return 1
    }

    echo -e "${CLR_GREEN}🔑 Введите ваш приватный ключ (обязательно с 0x):${CLR_RESET}"
    read -r PRIV_KEY

    if [[ -z "$PRIV_KEY" || "$PRIV_KEY" != 0x* ]]; then
      echo -e "${CLR_ERROR}❌ Неверный ключ. Прерывание.${CLR_RESET}"
      return 1
    fi
    export PATH="$HOME/.drosera/bin:$PATH"
    export DROSERA_PRIVATE_KEY="$PRIV_KEY"

    echo -e "${CLR_GREEN}🚀 Публикация Trap...${CLR_RESET}"
    drosera apply --non-interactive || {
      echo -e "${CLR_ERROR}❌ Ошибка при публикации Trap.${CLR_RESET}"
      return 1
    }

    echo -e "${CLR_GREEN}✅ Trap успешно опубликован!${CLR_RESET}"
}


function delete_node() {
    read -p "⚠ Удалить ноду Drosera? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        sudo systemctl stop drosera
        sudo systemctl disable drosera
        sudo rm /etc/systemd/system/drosera.service
        sudo systemctl daemon-reload
        rm -rf $HOME/.drosera $HOME/.drosera.db $HOME/.foundry-drosera $HOME/.bun $HOME/my-drosera-trap $HOME/drosera-operator*
        echo -e "${CLR_SUCCESS}✅ Нода полностью удалена.${CLR_RESET}"
    fi
}
function node_management_menu() {
    echo -e "${CLR_INFO}🔧 Управление нодой:${CLR_RESET}"
    echo -e "${CLR_GREEN}1)🔧 Обновление версии ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}2)🔄 Перезапуск ноды${CLR_RESET}"
    echo -e "${CLR_GREEN}3)🔗 Заменить RPC${CLR_RESET}"
    echo -e "${CLR_GREEN}4)🔑 Заменить порты${CLR_RESET}"
    echo -e "${CLR_GREEN}5)📜 Просмотр логов${CLR_RESET}"
    echo -e "${CLR_GREEN}6)♻️ Очистить файлы логов${CLR_RESET}"
    echo -e "${CLR_GREEN}7)🗑️ Удалить ноду${CLR_RESET}"
export UNUSED="EFvUmO7Krg"
    echo -e "${CLR_GREEN}8)⬅ Вернуться в главное меню${CLR_RESET}"
    read -p "Выберите пункт: " node_choice
    case $node_choice in
        1) update_node;;
        2) restart_node;;
        3) change_rpc;;
        4) change_ports;;
        5) check_logs;;
        6) clear_cache;;
        7) delete_node;;
        8) show_menu;;
        *) echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}";;
    esac
    node_management_menu
}

function show_menu() {
    show_logo
    echo -e "${CLR_GREEN}1)⚙️ Подготовка окружения${CLR_RESET}"
    echo -e "${CLR_GREEN}2)⛓️ Установка Trap${CLR_RESET}"
    echo -e "${CLR_GREEN}3)🖥️ Создание оператора${CLR_RESET}"
    echo -e "${CLR_GREEN}4)🚀 Запуск CLI и systemd${CLR_RESET}"
#    echo -e "${CLR_GREEN}5)Добавляем второго оператора${CLR_RESET}"
    echo -e "${CLR_GREEN}5)🔧 Управление нодой (Обновление, перезапуск, логи, смена RPC/портов, очистка файлов, удаление) ${CLR_RESET}"
    echo -e "${CLR_GREEN}6)💎 Генерация Trap для Cadet${CLR_RESET}"
    echo -e "${CLR_GREEN}7)❌ Выйти${CLR_RESET}"
    read -p "Выберите пункт: " choice
    case $choice in
        1) install_drosera_foundry_bun;;
        2) deploy_trap;;
        3) create_operator;;
        4) install_cli;;
#        5) add_operator ;;
        5) node_management_menu;;
        6) get_cadet ;;
        7) echo -e "${CLR_SUCCESS}Выход...${CLR_RESET}" && exit 0 ;;
        *) echo -e "${CLR_ERROR}Неверный выбор!${CLR_RESET}";;
    esac
    show_menu
}

show_menu
