# Desafio: Jogo de Adivinhação com Docker Compose

Este projeto tem como objetivo implementar uma estrutura completa com Docker Compose para o jogo de adivinhação disponível em [https://github.com/fams/guess_game](https://github.com/fams/guess_game). A estrutura engloba três serviços principais: um backend Python (Flask), um banco de dados PostgreSQL e um frontend React servido por um container NGINX, que também atua como proxy reverso e balanceador de carga.

## Estrutura do Projeto

A organização do projeto segue a seguinte estrutura de diretórios:

desafio-guess-game-docker/
├── backend/                  # Contém o código-fonte do backend Flask e seu Dockerfile
│   └── Dockerfile
├── frontend/                 # Contém o código-fonte do frontend React, seu Dockerfile e a configuração do NGINX
│   ├── Dockerfile
│   └── default.conf
├── docker-compose.yml        # Arquivo de orquestração dos serviços Docker
└── README.md                 # Este documento



###############################################


## Opções de Design Adotadas

### Serviços
A escolha dos serviços reflete os componentes originais do jogo e os requisitos do desafio:
* **Backend (Python/Flask)**: Utiliza a aplicação Flask do jogo para a lógica de negócio e API.
* [cite_start]**Banco de Dados (PostgreSQL)**: Selecionado para persistência dos dados do jogo, conforme requisito do desafio[cite: 5]. O PostgreSQL é um banco de dados relacional robusto e amplamente utilizado em ambientes de produção.
* **Frontend (React servido por NGINX)**: O NGINX é usado para servir os arquivos estáticos do frontend React. Essa é uma prática recomendada para aplicações web, pois o NGINX é otimizado para servir conteúdo estático de forma eficiente.

### Redes
Uma rede Docker personalizada (`app_network`) foi criada para permitir a comunicação isolada e segura entre os serviços (`db`, `backend`, `frontend`). Isso garante que os serviços possam se comunicar entre si utilizando seus nomes de serviço (ex: `backend` e `db`) sem expor portas desnecessariamente para o host.

### Volumes
[cite_start]Para garantir a persistência dos dados do banco de dados PostgreSQL[cite: 6], um volume nomeado (`db_data`) foi configurado. Isso significa que mesmo se o container do banco de dados for removido ou recriado, os dados do jogo não serão perdidos, pois eles residem no volume persistente.

### Estratégia de Balanceamento de Carga
[cite_start]O serviço `frontend` (NGINX) atua como um proxy reverso e é configurado para balancear a carga entre múltiplas instâncias do serviço `backend`. [cite: 8] A configuração do `upstream` no `frontend/default.conf` (`backend_servers`) permite que, no futuro, novas instâncias do `backend` possam ser adicionadas ao `docker-compose.yml` (e o NGINX as detectará), distribuindo as requisições de API de forma equitativa. Atualmente, o `docker-compose.yml` está configurado para uma única instância do backend, mas a escalabilidade é prevista.

## Como Instalar e Rodar

Para instalar e rodar a aplicação, siga os passos abaixo. Certifique-se de ter o [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e em execução em sua máquina Windows.

1.  **Clone o repositório deste desafio (ou descompacte a estrutura se você a criou manualmente):**
    ```bash
    git clone [https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git](https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git) # Substitua pelo link do seu repositório
    cd SEU_REPOSITORIO # Navegue até a pasta raiz do projeto
    ```
    *Se você montou a estrutura manualmente, navegue até a pasta `desafio-guess-game-docker`.*

2.  **Construa as imagens Docker e inicie os serviços:**
    Na pasta raiz do projeto (`desafio-guess-game-docker/`), execute o seguinte comando:
    ```bash
    docker compose up --build -d
    ```
    * `docker compose up`: Inicia os containers definidos no `docker-compose.yml`.
    * `--build`: Garante que as imagens Docker do backend e frontend sejam construídas (ou reconstruídas) a partir dos seus `Dockerfiles`.
    * `-d`: Executa os containers em modo "detached" (em segundo plano), liberando seu terminal.

3.  **Verifique o status dos containers (opcional):**
    Para verificar se todos os serviços estão rodando corretamente:
    ```bash
    docker compose ps
    ```
    Todos os serviços (`backend`, `db`, `frontend`) devem estar no status `running`.

## Como Acessar a Aplicação

Após a execução do `docker compose up`, a aplicação estará disponível no seu navegador.

[cite_start]**URL de Acesso:** [http://localhost/](http://localhost/) [cite: 19]

## Como Atualizar Componentes

[cite_start]A estrutura foi desenhada para facilitar a atualização de qualquer um dos serviços (backend, frontend ou banco de dados) sem a necessidade de grandes mudanças no código ou na orquestração. [cite: 10, 17]

### Atualizando o Backend ou Frontend
Para atualizar o código do backend ou frontend, siga estes passos:
1.  **Atualize o código-fonte:** Vá para o diretório `backend/` ou `frontend/` e atualize o código (ex: `git pull` se estiver usando Git para o código-fonte original, ou faça suas modificações diretas).
2.  **Reconstrua e reinicie o serviço específico:**
    * Para o backend:
        ```bash
        docker compose up --build -d backend
        ```
    * Para o frontend:
        ```bash
        docker compose up --build -d frontend
        ```
    O Docker detectará as mudanças no `Dockerfile` ou no contexto de construção e reconstruirá apenas a imagem necessária, reiniciando o container correspondente.

### Atualizando a Versão do Banco de Dados (PostgreSQL)
Para atualizar a versão do PostgreSQL (por exemplo, de `postgres:13-alpine` para `postgres:14-alpine`):
1.  **Edite o `docker-compose.yml`:** Altere a linha `image: postgres:13-alpine` para a nova versão desejada (ex: `image: postgres:14-alpine`).
2.  **Reconstrua e recrie o serviço do banco de dados:**
    ```bash
    docker compose up --build -d db
    ```
    **Atenção:** Atualizar a versão maior do PostgreSQL pode exigir migração de dados se o formato do volume mudar. Para uma atualização segura em produção, consulte a documentação oficial do PostgreSQL sobre migrações de versão. Para este desafio, a simples troca da imagem e reinício é aceitável, mas em cenários reais, um backup e processo de migração seriam essenciais.

## Resiliência e Manutenção

A estrutura incorpora mecanismos de resiliência e facilidade de manutenção:
* [cite_start]**Reinício de Containers**: Todos os serviços estão configurados com `restart: unless-stopped`, garantindo que, em caso de falha, o container será automaticamente reiniciado pelo Docker. [cite: 7]
* [cite_start]**Persistência de Dados**: O uso de volumes nomeados para o banco de dados assegura que os dados não sejam perdidos caso o container `db` seja recriado ou atualizado. [cite: 9]
* [cite_start]**Balanceamento de Carga**: O NGINX é configurado para balancear a carga entre múltiplas instâncias do backend, preparando a aplicação para lidar com maior tráfego e fornecer alta disponibilidade. [cite: 8]