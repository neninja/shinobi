# Shinobi

## Configuração

- Inicie o PostgreSQL local

```sh
docker run -d \
    --name postgres \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=shinobi_dev \
    -p 5432:5432 \
    -v shinobi_postgres_data:/var/lib/postgresql/data \
    postgres:16-alpine
```

- Baixe as dependências, build, migrations e seed

```shell
mix setup
```

> Sugestão de dados iniciais com `mix example.setup` e resetar com `mix fresh`

## Execução

- Inicie o servidor

```shell
mix server
```
