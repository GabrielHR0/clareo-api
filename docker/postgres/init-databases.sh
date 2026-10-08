# Cria os dois bancos que o projeto usa. O compose so define POSTGRES_DB para
# um deles, e o ambiente de teste precisa existir antes de qualquer spec.
#
# Scripts em /docker-entrypoint-initdb.d/ rodam uma vez, na primeira subida do
# volume. Se o volume ja existe, este script nao roda de novo: e por isso que o
# compose monta um volume nomeado e nao /tmp.
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<EOSQL
  CREATE DATABASE ${DEV_DB};
  CREATE DATABASE ${TEST_DB};
EOSQL

echo "bancos criados: ${DEV_DB}, ${TEST_DB}"