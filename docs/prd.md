# PRD - Shinobi Training Log

## Objetivo

O Shinobi Training Log permite que usuarios cadastrem atividades de treino e registrem historico de resultados pessoais, chamados de PRs. O sistema e pensado para uso mobile first durante o treino.

## Usuarios

- Usuario autenticado que registra seus proprios PRs.
- Todos os usuarios acessam atividades globais criadas pelo seed inicial.
- Cada usuario pode criar atividades privadas, visiveis apenas para si.

## Funcionalidades

- Listar atividades globais e proprias.
- Criar, editar e remover atividades proprias.
- Visualizar atividades globais sem permitir edicao por usuarios comuns.
- Registrar PRs vinculados a uma atividade disponivel para o usuario.
- Listar PRs dentro da atividade correspondente, visualizar, editar e remover apenas os PRs do usuario autenticado.
- Adaptar o formulario de PR ao tipo de medida da atividade.

## Tipos de medida

- Tempo.
- Tempo + peso.
- Voltas.
- Voltas + peso.
- Repeticoes.
- Repeticoes + peso.

## Seed inicial

O seed cria atividades globais sem usuario definido, como Cindy, Karen, Bar Muscle Up, Bench Press, 5K Run e Annie. Essas atividades ficam disponiveis para todos os usuarios.

## Regras de acesso

- `activities.user_id = NULL`: atividade global, acessivel a todos.
- `activities.user_id = usuario`: atividade privada do usuario.
- `personal_records.user_id = usuario`: PR privado do usuario.
- Usuarios nao podem editar atividades globais nem acessar PRs de outro usuario.

## Experiencia mobile

- Navegacao centrada em Atividades, com os registros de cada atividade no detalhe dela.
- Cards grandes para leitura rapida no celular.
- Acoes principais com botoes destacados.
- Formularios curtos, com campos exibidos somente quando fazem sentido para a medida escolhida.
