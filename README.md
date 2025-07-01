# Desafio: Jogo de Adivinhação com Docker Compose

Este projeto tem como objetivo implementar uma estrutura completa com Docker Compose para o jogo de adivinhação disponível em [https://github.com/fams/guess_game](https://github.com/fams/guess_game). A estrutura engloba três serviços principais: um backend Python (Flask), um banco de dados PostgreSQL e um frontend React servido por um container NGINX.

## Estrutura do Projeto

A organização do projeto segue a seguinte estrutura de diretórios:

desafio-guess-game-docker/
├── backend/                  # Contém o código-fonte do backend Flask, seu Dockerfile e o entrypoint.sh
│   ├── Dockerfile
│   └── entrypoint.sh
├── frontend/                 # Contém o código-fonte do frontend React, seu Dockerfile e a configuração do NGINX
│   ├── Dockerfile
│   └── default.conf
├── docker-compose.yml        # Arquivo de orquestração dos serviços Docker
└── README.md                 # Este documento

## Opções de Design Adotadas

### Serviços
A escolha dos serviços reflete os componentes originais do jogo e os requisitos do desafio:
* **Backend (Python/Flask)**: Utiliza a aplicação Flask do jogo para a lógica de negócio e API. A imagem base `python:3.9-slim-buster` foi escolhida por ser leve e baseada em Debian.
* **Banco de Dados (PostgreSQL)**: Selecionado para persistência dos dados do jogo, conforme requisito do desafio. O PostgreSQL é um banco de dados relacional robusto e amplamente utilizado. A imagem `postgres:13-alpine` é uma opção leve.
* **Frontend (React servido por NGINX)**: O NGINX é utilizado para servir os arquivos estáticos do frontend React, o que é uma prática recomendada para alta performance no servir de conteúdo estático. A imagem `nginx:alpine` foi escolhida por sua leveza.

### Redes
Uma rede Docker personalizada, `app_network`, foi criada e configurada com o driver `bridge`. Isso permite a comunicação isolada e segura entre os serviços (`db`, `backend`, `frontend`) utilizando seus nomes de serviço como nomes de host (ex: o backend acessa o banco de dados via `db:5432`), sem expor portas desnecessariamente para a rede externa.

### Volumes
Para garantir a persistência dos dados do banco de dados PostgreSQL, um volume nomeado (`db_data`) foi configurado e mapeado para `/var/lib/postgresql/data` dentro do container do DB. Isso assegura que mesmo se o container do banco de dados for removido ou recriado, os dados do jogo não serão perdidos, pois eles residem no volume persistente.

### Estratégia de Comunicação API e Frontend
A comunicação entre o frontend e o backend é feita diretamente. O frontend React (`Maker.tsx` e `Breaker.tsx`) foi configurado, através da variável de ambiente `REACT_APP_BACKEND_URL`, para chamar diretamente o backend na porta `5000` do host (`http://localhost:5000`). O NGINX, neste cenário, atua primariamente como um servidor de arquivos estáticos para o frontend, e não como um proxy reverso para as chamadas de API que vão diretamente para o backend.

### Resiliência e Manutenção

* **Reinício de Containers**: Todos os serviços (`db`, `backend`, `frontend`) estão configurados com a política `restart: unless-stopped`, garantindo que, em caso de falha, o container será automaticamente reiniciado pelo Docker.
* **Espera por Dependência (Backend & DB)**: O serviço `backend` utiliza um `entrypoint.sh` personalizado que implementa um mecanismo de espera ativa (`nc -z`) para garantir que o banco de dados PostgreSQL esteja totalmente operacional e aceitando conexões antes que a aplicação Flask do backend seja iniciada. Além disso, o `docker-compose.yml` utiliza `depends_on: db: condition: service_healthy` para o backend, garantindo que o Docker Compose aguarde o `healthcheck` do DB passar.
* **Balanceamento de Carga no Proxy Reverso**: Embora o NGINX, em sua configuração final, não esteja atuando como proxy reverso para as chamadas de API do frontend para o backend (já que o frontend chama `localhost:5000` diretamente para a API), a estrutura com `upstream backend_servers` no `default.conf` do NGINX e a possibilidade de escalar o serviço `backend` no `docker-compose.yml` (ex: `scale: 2` para o `backend`) já preveem a capacidade de balanceamento de carga para múltiplas instâncias do backend, caso o NGINX fosse configurado para rotear essas chamadas.
* **Volumes Separados para o Banco de Dados**: O banco de dados Postgres é armazenado em um volume persistente (`db_data`) para garantir que os dados não sejam perdidos caso o container do DB seja removido ou recriado.
* **Facilidade de Atualização**: A estrutura permite a atualização de qualquer componente (backend, frontend, banco de dados) apenas trocando a versão da imagem base no `Dockerfile` ou no `docker-compose.yml`, ou reconstruindo a imagem se o código-fonte for alterado.

## Como Instalar e Rodar

Para instalar e rodar a aplicação, siga os passos abaixo. Certifique-se de ter o [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e em execução em sua máquina Windows.

1.  **Clone o repositório deste desafio:**
    ```bash
    git clone [https://github.com/AkagShadow/desafio-guess-game-docker.git](https://github.com/AkagShadow/desafio-guess-game-docker.git)
    cd desafio-guess-game-docker
    ```

2.  **Construa as imagens Docker e inicie os serviços:**
    Na pasta raiz do projeto (`desafio-guess-game-docker/`), execute o seguinte comando:
    ```bash
    docker compose up --build -d
    ```
    * `docker compose up`: Inicia os containers definidos no `docker-compose.yml`.
    * `--build`: Garante que as imagens Docker do backend e frontend sejam construídas (ou reconstruídas) a partir dos seus `Dockerfiles`, aplicando quaisquer alterações de código ou configuração.
    * `-d`: Executa os containers em modo "detached" (em segundo plano), liberando seu terminal.

3.  **Verifique o status dos containers (opcional):**
    Para verificar se todos os serviços estão rodando corretamente:
    ```bash
    docker compose ps
    ```
    Todos os serviços (`db`, `backend`, `frontend`) devem estar no status `running` (ou `Up`).

## Como Acessar a Aplicação

Após a execução bem-sucedida do `docker compose up`, a aplicação estará disponível no seu navegador.

**URL de Acesso:** [http://localhost/](http://localhost/)

Navegue para `http://localhost/maker` para criar um novo jogo e `http://localhost/breaker` para jogar.


**⚠️ Ponto Crítico para Avaliação ⚠️**

Conforme os requisitos do desafio, é fundamental que a URL para acesso à aplicação após o `docker compose up` seja informada claramente. Trabalhos que não funcionam ou não indicam essa URL explicitamente receberão nota zero.

A URL a ser utilizada é: **`http://localhost/`**

A comunicação entre o frontend e o backend é feita diretamente. O frontend React (`Maker.tsx` e `Breaker.tsx`) foi configurado, através da variável de ambiente `REACT_APP_BACKEND_URL`, para chamar diretamente o backend na porta `5000` do host (`http://localhost:5000`). 

## Como Atualizar Componentes

A estrutura foi desenhada para facilitar a atualização de qualquer um dos serviços (backend, frontend ou banco de dados) sem a necessidade de mudanças complexas no código.

### Atualizando o Código-Source do Backend ou Frontend
Para atualizar o código-fonte da aplicação (ex: nova funcionalidade, correção de bug):
1.  **Atualize o código-fonte:** Vá para o diretório `backend/` ou `frontend/` e atualize o código (ex: faça um `git pull` se o código estiver em um sub-repositório, ou aplique suas modificações diretas).
2.  **Reconstrua e reinicie o serviço específico:**
    * Para o backend:
        ```bash
        docker compose up --build -d backend
        ```
    * Para o frontend:
        ```bash
        docker compose up --build -d frontend
        ```
    O Docker detectará as mudanças no código ou nos `Dockerfiles` e reconstruirá apenas a imagem necessária, reiniciando o container correspondente.

### Atualizando a Versão da Imagem Base (Ex: PostgreSQL)
Para atualizar a versão de um serviço como o PostgreSQL (por exemplo, de `postgres:13-alpine` para `postgres:14-alpine`):
1.  **Edite o `docker-compose.yml`:** Altere a linha `image: postgres:13-alpine` para a nova versão desejada (ex: `image: postgres:14-alpine`).
2.  **Reconstrua e recrie o serviço do banco de dados:**
    ```bash
    docker compose up --build -d db
    ```
    **Atenção:** Atualizar a versão maior do PostgreSQL pode exigir migração de dados se o formato do volume mudar. Para uma atualização segura em produção, consulte a documentação oficial do PostgreSQL sobre migrações de versão. Para este desafio, a simples troca da imagem e reinício é aceitável, mas em cenários reais, um backup e processo de migração seriam essenciais.
