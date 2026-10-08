#!/bin/sh
# Entrypoint de desenvolvimento.
#
# Existe por causa do volume nomeado em /usr/local/bundle: quando o Gemfile muda,
# a imagem fica com o bundle velho e o volume esconde o novo. bundle check
# detecta e reinstala, o que faz o primeiro boot demorar um pouco so depois de
# mexer no Gemfile.
#
# No primeiro boot do banco, roda db:prepare e db:seed. Os seeds sao
# idempotentes, entao isso e seguro em toda subida.
set -e

cd /rails

bundle check >/dev/null 2>&1 || bundle install

if [ "${RUN_MIGRATIONS:-1}" = "1" ]; then
  echo "==> db:prepare"
  bundle exec rails db:prepare
  echo "==> db:seed"
  bundle exec rails db:seed || echo "seed falhou; seguindo assim mesmo"
fi

exec "$@"