#!/bin/bash
# Este script garante que as variáveis de ambiente necessárias sejam configuradas
# antes de iniciar a aplicação Flask, e espera o DB.

# Exporta as variáveis que o Flask espera (DB_TYPE, DB_NAME, etc.)
# Isso é para garantir que mesmo se o Flask não as ler diretamente do ambiente,
# elas estejam disponíveis no script.
export FLASK_DB_TYPE=${DB_TYPE:-"dynamodb"}
export FLASK_DB_NAME=${DB_NAME:-"guessgame"}
export FLASK_DB_USER=${DB_USER:-"user"}
export FLASK_DB_PASSWORD=${DB_PASSWORD:-"password"}
export FLASK_DB_HOST=${DB_HOST:-"db"} # Garante que FLASK_DB_HOST seja 'db'

# echo "Aguardando o banco de dados em ${FLASK_DB_HOST}:${POSTGRES_PORT:-5432}..."

# Inicia um loop que continua até que a conexão com o banco de dados seja estabelecida.
# 'nc -z': usa o comando netcat para tentar uma conexão sem enviar dados.
#   '-z': modo zero-I/O (apenas verifica se a porta está aberta).
#   '-v': modo verboso (mostra mensagens de conexão).
#   '-w 1': timeout de 1 segundo para a tentativa de conexão.
# $FLASK_DB_HOST: O nome do host do banco de dados (que é 'db' dentro da rede Docker).
# ${POSTGRES_PORT:-5432}: A porta do PostgreSQL (padrão 5432 se não for definida).
# until nc -z -v -w 1 $FLASK_DB_HOST ${POSTGRES_PORT:-5432}; do
#   echo "Banco de dados indisponível, aguardando 1 segundo..."
#   sleep 1 # Pausa por 1 segundo antes de tentar novamente.
# done

# echo "Banco de dados disponível. Iniciando a aplicação Flask."

# 'exec "$@"' substitui o processo atual do shell pelo comando que veio do CMD do Dockerfile.
# Isso garante que os sinais (como SIGTERM para parada de container) sejam passados corretamente
# para a aplicação Flask, e que o Flask seja o processo principal do container.
exec "$@"