# Desafio: Jogo de Adivinhação com Kubernetes

Este projeto consiste na reimplementação da aplicação de jogo de adivinhação, anteriormente orquestrada com Docker Compose, utilizando os conceitos e recursos do Kubernetes. O objetivo é demonstrar a capacidade de deploy, orquestração, persistência de dados, exposição de serviços e autoescalonamento em um ambiente Kubernetes.

A aplicação é composta por três serviços principais:
**Backend:** Aplicação Python (Flask) com a lógica de negócio do jogo.
**Banco de Dados:** PostgreSQL para persistência dos dados do jogo.
**Frontend:** Aplicação React servida por um container NGINX.

## Estrutura do Projeto

A organização dos manifestos Kubernetes e do código-fonte da aplicação segue a seguinte estrutura de diretórios:

```

desafio-guess-game-docker/
├── backend/                  # Contém o código-fonte do backend Flask, seu Dockerfile e o entrypoint.sh
│   ├── Dockerfile
│   └── entrypoint.sh
├── frontend/                 # Contém o código-fonte do frontend React, seu Dockerfile e a configuração do NGINX
│   ├── Dockerfile
│   └── default.conf
├── kubernetes/               # Contém todos os manifestos Kubernetes (.yaml)
│   ├── db/
│   │   └── postgres-manifests.yaml   # Manifestos para PVC, Deployment e Service do PostgreSQL
│   ├── backend/
│   │   ├── flask-manifests.yaml      # Manifestos para Deployment e Service do Backend Flask
│   │   └── hpa-manifests.yaml        # Manifesto para o Horizontal Pod Autoscaler (HPA) do Backend
│   └── frontend/
│       └── react-nginx-manifests.yaml # Manifestos para Deployment e Service do Frontend React/NGINX
└── README.md                 # Este documento

````

## Opções de Design Adotadas no Kubernetes

### Imagens Docker
As imagens Docker para os serviços de Backend e Frontend foram construídas localmente e publicadas no Docker Hub, garantindo que o Kubernetes possa puxá-las de um registro público. As imagens utilizadas são:
* Backend: `willdias/guess-game-backend:1.0.0`
* Frontend: `willdias/guess-game-frontend:1.0.0`

### Banco de Dados (PostgreSQL)
* **PersistentVolumeClaim (PVC)**: Um PVC (`postgres-pvc`) de 250Mi foi configurado para solicitar armazenamento persistente, garantindo que os dados do PostgreSQL não sejam perdidos em caso de reinício ou recriação do Pod.
* **Deployment**: Um `Deployment` (`postgres-deployment`) gerencia o Pod do PostgreSQL, garantindo que uma réplica esteja sempre em execução.
* **Service**: Um `Service` do tipo `ClusterIP` (`postgres-service`) expõe o PostgreSQL internamente no cluster, permitindo que o Backend se conecte a ele usando o nome do serviço (`postgres-service:5432`).
* **Probes de Saúde**: `livenessProbe` e `readinessProbe` são usados para monitorar a saúde do Pod do PostgreSQL, garantindo sua disponibilidade.

### Backend (Flask)
* **Deployment**: Um `Deployment` (`backend-deployment`) gerencia o Pod do Backend Flask. Ele é configurado com requisições e limites de CPU (`100m` requests, `500m` limits) e memória (`128Mi` requests, `256Mi` limits), essenciais para o autoescalonamento.
* **Service**: Um `Service` do tipo `ClusterIP` (`backend-service`) expõe o Backend internamente no cluster, permitindo que o Frontend (via NGINX) se conecte a ele.
* **Variáveis de Ambiente**: As credenciais do banco de dados (`DB_TYPE`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`) são passadas como variáveis de ambiente para o Pod do Backend. O `DB_HOST` aponta para `postgres-service`.
* **Entrypoint Script**: Um `entrypoint.sh` personalizado foi implementado no Dockerfile do Backend para garantir que a aplicação Flask só inicie após o banco de dados PostgreSQL estar totalmente disponível e aceitando conexões, evitando erros de "Connection refused" por timing.
* **Probes de Saúde**: `livenessProbe` e `readinessProbe` baseados na rota `/health` da aplicação Flask garantem que o Kubernetes saiba o status do Backend.

### Frontend (React / NGINX)
* **Deployment**: Um `Deployment` (`frontend-deployment`) gerencia o Pod do Frontend, que consiste em um container NGINX servindo a aplicação React.
* **Service**: Um `Service` do tipo `NodePort` (`frontend-service`) expõe o Frontend para acesso externo ao cluster. Uma porta alta será alocada pelo Kubernetes no nó (ex: `30000-32767`), permitindo acesso via `http://localhost:<NodePort>`.
* **NGINX como Servidor Estático e Proxy Reverso**: O `default.conf` do NGINX está configurado para:
    * Servir os arquivos estáticos do frontend React.
    * Atuar como **proxy reverso para as chamadas de API** do frontend para o backend. O NGINX encaminha requisições do tipo `/api/<caminho>` para o `backend-service:5000/<caminho>`. **Importante: Diferentemente da implementação Docker Compose anterior, o NGINX agora gerencia ativamente o roteamento das chamadas de API para o backend, garantindo seu papel como fachada e permitindo balanceamento de carga entre múltiplas instâncias do backend.**
* **Comunicação Frontend-Backend**: A aplicação React no frontend é configurada (via `REACT_APP_BACKEND_URL=/api` durante o build da imagem Docker) para enviar suas requisições de API para o caminho `/api` relativo, que é interceptado e roteado pelo NGINX no mesmo Pod para o `backend-service` interno do cluster.

### Horizontal Pod Autoscaler (HPA)
* Um `HorizontalPodAutoscaler` (`backend-hpa`) é configurado para escalar automaticamente o `backend-deployment`.
* Ele monitora a utilização média de CPU, com um alvo de `50%` do CPU requisitado (`100m`).
* O número de réplicas do backend escalará entre `1` (mínimo) e `5` (máximo) Pods, garantindo resiliência e capacidade de lidar com picos de carga.
* O HPA depende do Metrics Server, que é um componente padrão em clusters como o Docker Desktop Kubernetes.

### Resiliência e Manutenção
A arquitetura com Kubernetes oferece alta resiliência e facilidade de manutenção:
* **Reinício Automático**: `Deployments` garantem que os Pods sejam automaticamente reiniciados ou recriados em caso de falha.
* **Persistência de Dados**: O `PVC` garante que os dados do banco de dados não sejam perdidos.
* **Autoescalonamento**: O `HPA` adapta a capacidade do backend à demanda, aumentando a resiliência a picos de tráfego.
* **Gerenciamento de Dependências**: O `entrypoint.sh` e os `probes` garantem que os serviços dependentes estejam prontos antes da inicialização.
* **Facilidade de Atualização**: A atualização de componentes é feita simplesmente alterando a tag da imagem nos manifestos YAML e reaplicando-os (`kubectl apply`), ou usando comandos de rollout.

## Como Instalar e Rodar

Para instalar e rodar a aplicação no seu ambiente Kubernetes (Minikube, K3s ou Docker Desktop Kubernetes), siga os passos abaixo. Certifique-se de que seu cluster Kubernetes esteja ativo.
*Para construção deste projeto foi utilizado o Docker Desktop.

1.  **Obtenha os arquivos do projeto:**
    Para ter acesso aos manifestos Kubernetes e à documentação, clone o repositório deste desafio:
    ```bash
    git clone https://github.com/AkagShadow/desafio-guess-game-docker.git
    cd desafio-guess-game-docker
    ```

2.  **Imagens Docker (Disponíveis no Docker Hub):**
    As imagens Docker necessárias para os serviços de Backend e Frontend já estão pré-construídas e disponíveis em meu repositório no Docker Hub:
    * Backend: `willdias/guess-game-backend:1.0.0`
    * Frontend: `willdias/guess-game-frontend:1.0.0`

    *(Opcional, apenas se precisar reconstruir/enviar novamente para o Docker Hub):*
    Caso necessite reconstruir e/ou enviar as imagens novamente para o Docker Hub, execute:
    ```bash
    docker compose build backend frontend # Constrói as imagens localmente
    docker tag desafio-guess-game-docker-backend:latest willdias/guess-game-backend:1.0.0
    docker tag desafio-guess-game-docker-frontend:latest willdias/guess-game-frontend:1.0.0
    docker push willdias/guess-game-backend:1.0.0
    docker push willdias/guess-game-frontend:1.0.0
    ```

3.  **Verifique ou Instale o Metrics Server (essencial para HPA):**
    O HPA depende do Metrics Server. Verifique seu status:
    ```bash
    kubectl get apiservice v1beta1.metrics.k8s.io
    kubectl get pods -n kube-system -l k8s-app=metrics-server
    ```
    Se o Metrics Server não estiver `True` ou `Running` (indicando que não está ativo ou não foi instalado com as configurações corretas para ambientes locais como o Docker Desktop), será necessário aplicá-lo com a opção de ignorar a validação TLS.

    **O arquivo `components.yaml` necessário para a instalação do Metrics Server já está disponível no diretório `kubernetes/backend/`.** Ele já foi pré-configurado com a opção `--kubelet-insecure-tls` para facilitar a instalação em ambientes locais.

    Para aplicá-lo (caso o Metrics Server não esteja funcional), navegue até o diretório `kubernetes/backend/` e execute:
    ```bash
    cd kubernetes/backend/ # Se você não estiver já neste diretório
    kubectl apply -f components.yaml
    ```
    Aguarde alguns minutos até que o Metrics Server esteja `1/1 Running` e `Available`. Você pode verificar com os comandos `kubectl get apiservice` e `kubectl get pods` novamente.

4.  **Aplique os Manifestos Kubernetes:**
    Navegue até o diretório `kubernetes/` e aplique todos os manifestos na ordem recomendada:
    ```bash
    cd kubernetes/

    # 1. Banco de Dados
    kubectl apply -f db/postgres-manifests.yaml

    # 2. Backend
    kubectl apply -f backend/flask-manifests.yaml
    kubectl apply -f backend/hpa-manifests.yaml

    # 3. Frontend
    kubectl apply -f frontend/react-nginx-manifests.yaml
    ```

5.  **Verifique o Status dos Componentes:**
    Aguarde alguns minutos para que todos os Pods estejam `Running` e `READY`.
    ```bash
    kubectl get pvc,deploy,svc,hpa -l app=guess-game # Visualiza todos os recursos da aplicação
    kubectl get pods -l app=guess-game # Visualiza todos os Pods
    kubectl get pods -n kube-system -l k8s-app=metrics-server # Status do Metrics Server
    kubectl logs -f <NOME_DO_POD_DO_BACKEND> # Verifique logs do backend para erros de DB
    ```

## Como Acessar a Aplicação e Ponto Crítico para Avaliação

Após a execução bem-sucedida do `kubectl apply`, a aplicação estará disponível no seu navegador.

1.  **Obtenha a Porta do NodePort:**
    ```bash
    kubectl get svc frontend-service
    ```
    Na saída, procure a porta mapeada na coluna `PORT(S)` (ex: `80:3XXXX/TCP`). O `3XXXX` é a porta NodePort alocada.

2.  **URL de Acesso:**
    * **Para Docker Desktop Kubernetes:** `http://localhost:<PORTA_NODEPORT>` (Ex: `http://localhost:31884`)
    * **Para Minikube:** `http://$(minikube ip):<PORTA_NODEPORT>`

**⚠️ Ponto Crítico para Avaliação:** É fundamental informar claramente essa URL, pois trabalhos que não funcionam ou não a indicam explicitamente receberão nota zero.
**URL Principal: http://localhost:31884/**


## Como Atualizar Componentes

A estrutura foi desenhada para facilitar a atualização de qualquer um dos serviços sem a necessidade de mudanças complexas no código.

### Atualizando o Código-fonte (Backend ou Frontend)
Para atualizar o código-fonte da aplicação (ex: nova funcionalidade, correção de bug):
1.  **Atualize o código-fonte** no seu diretório local (`backend/` ou `frontend/`).
2.  **Reconstrua a imagem Docker** correspondente e **envie-a para o Docker Hub** com uma nova tag (ou a mesma, se for sobrescrever).
    Ex: `docker compose build backend && docker tag desafio-guess-game-docker-backend:latest willdias/guess-game-backend:2.0.0 && docker push willdias/guess-game-backend:2.0.0`
3.  **Edite o manifesto de Deployment** correspondente (`flask-manifests.yaml` ou `react-nginx-manifests.yaml`) para usar a nova tag da imagem (ex: `image: willdias/guess-game-backend:2.0.0`).
4.  **Aplique o manifesto atualizado:**
    ```bash
    kubectl apply -f kubernetes/backend/flask-manifests.yaml # ou para o frontend
    ```
    O Kubernetes fará um rollout da nova versão do Deployment.

### Atualizando a Versão da Imagem Base (Ex: PostgreSQL)
Para atualizar a versão de um serviço como o PostgreSQL (por exemplo, de `postgres:13-alpine` para `postgres:14-alpine`):
1.  **Edite o `postgres-manifests.yaml`:** Altere a linha `image: postgres:13-alpine` para a nova versão desejada (ex: `image: postgres:14-alpine`).
2.  **Aplique o manifesto atualizado:**
    ```bash
    kubectl apply -f kubernetes/db/postgres-manifests.yaml
    ```
    **Atenção:** Atualizar a versão maior do PostgreSQL pode exigir migração de dados se o formato do volume mudar. Para uma atualização segura em produção, consulte a documentação oficial do PostgreSQL sobre migrações de versão. Para este desafio, a simples troca da imagem e reaplicação é aceitável.

## Funcionamento e Resiliência

Todos os containers se comunicam corretamente e o sistema funciona como esperado, com resiliência em caso de falhas. O backend se conecta ao PostgreSQL, e o frontend se comunica com o backend para criar e gerenciar jogos. O autoescalonamento do backend garante que a aplicação possa lidar com variações de carga de forma eficiente.
````