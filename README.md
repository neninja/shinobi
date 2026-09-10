# Shinobi

## Como instalar

### 1) Crie o script de update

```sh
set -eu

repo="neninja/shinobi"
shinobi_home="${SHINOBI_HOME:-${HOME}/shinobi}"
app_dir="${shinobi_home}/app"
app_next="${shinobi_home}/app.next"
app_previous="${shinobi_home}/app.previous"
download_dir="${shinobi_home}/downloads"
arch="${SHINOBI_ARCH:-$(uname -m)}"

if [ -n "${SHINOBI_PLATFORM:-}" ]; then
  platform="${SHINOBI_PLATFORM}"
else
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  platform="${os}-${arch}"
fi

fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
  else
    echo "Instale curl ou wget para baixar a release." >&2
    exit 1
  fi
}

download() {
  if command -v curl >/dev/null 2>&1; then
    curl -fL -o "$2" "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$2" "$1"
  else
    echo "Instale curl ou wget para baixar a release." >&2
    exit 1
  fi
}

check_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$1"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "$1"
  else
    echo "Instale sha256sum ou shasum para validar o artefato." >&2
    exit 1
  fi
}

mkdir -p "${shinobi_home}" "${download_dir}"
cd "${download_dir}"

release_json="$(fetch "https://api.github.com/repos/${repo}/releases/latest")"

artifact="$(
  printf '%s\n' "${release_json}" |
    sed -nE "s/.*\"name\": \"(shinobi-[^\"]+-${platform}\.tar\.gz)\".*/\1/p" |
    head -n 1
)"

if [ -z "${artifact}" ]; then
  echo "Artefato ${platform} não encontrado na última release de ${repo}." >&2
  echo "Artefatos .tar.gz disponíveis:" >&2
  printf '%s\n' "${release_json}" |
    sed -nE 's/.*"name": "([^"]+\.tar\.gz)".*/- \1/p' >&2
  exit 1
fi

download "https://github.com/${repo}/releases/latest/download/${artifact}" "${artifact}"
download "https://github.com/${repo}/releases/latest/download/${artifact}.sha256" "${artifact}.sha256"
check_sha256 "${artifact}.sha256"

rm -rf "${app_next}"
mkdir -p "${app_next}"
tar -xzf "${artifact}" -C "${app_next}" --strip-components=1

rm -rf "${app_previous}"

if [ -d "${app_dir}" ]; then
  mv "${app_dir}" "${app_previous}"
fi

if ! mv "${app_next}" "${app_dir}"; then
  if [ -d "${app_previous}" ]; then
    mv "${app_previous}" "${app_dir}"
  fi

  echo "Falha ao trocar a release. A versão anterior foi restaurada." >&2
  exit 1
fi

echo "Release atualizada em ${app_dir}"
```

### 2) Crie o .env

Configure um banco, no exemplo abaixo é com o container de [CONTRIBUTING](./CONTRIBUTING.md)

```sh
SHINOBI_HOME="${SHINOBI_HOME:-${HOME}/shinobi}"
SECRET_KEY_BASE_GEN=$(openssl rand -hex 64)

cat > "${SHINOBI_HOME}/.env" <<EOF
MIX_ENV=prod
PHX_HOST=shinobi.selo.fyi
PHX_SCHEME=http
PHX_URL_PORT=8080
PORT=4000
DATABASE_URL=ecto://postgres:postgres@127.0.0.1:5432/shinobi_dev
POOL_SIZE=5
LANG=C.UTF-8
LC_ALL=C.UTF-8
ELIXIR_ERL_OPTIONS=+fnu
SECRET_KEY_BASE=${SECRET_KEY_BASE_GEN}
EOF
```

### 3) Execute as migrations

```sh
set -a
. "${HOME}/shinobi/.env"
set +a

"${HOME}/shinobi/app/bin/migrate"
```

### 4) Inicie a aplicação

```sh
set -a
. "${HOME}/shinobi/.env"
set +a

"${HOME}/shinobi/app/bin/server"
```

---

## Como transformo um usuário em admin?

```sh
iex -S mix

alias Shinobi.{Accounts, Repo}

Accounts.get_user_by_email("seu-email@example.com")

user
|> Ecto.Changeset.change(admin: true)
|> Repo.update!()
```
