# Estágio 1: Construção da aplicação React
# Usa uma imagem Node.js para instalar dependências e construir o projeto.
FROM node:18-alpine AS build

# Define um argumento de construção que será passado para o Dockerfile
# ARG REACT_APP_BACKEND_URL=/api
# Define o argumento de construção para a URL completa do backend
ARG REACT_APP_BACKEND_URL=http://localhost:5000

# Define o diretório de trabalho dentro do container para este estágio.
WORKDIR /app

# Copia os arquivos package.json e package-lock.json.
# Isso permite que o Docker use o cache de camadas eficientemente.
COPY package.json package-lock.json ./

# Instala as dependências do Node.js.
RUN npm install

# Copia todo o restante do código-fonte do frontend para o diretório de trabalho.
COPY . .

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL

# Constrói a aplicação React para produção.
# Isso irá gerar os arquivos estáticos (HTML, CSS, JS) na pasta 'build'.
RUN REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL npm run build


# Estágio 2: Servindo a aplicação com NGINX
# Usa uma imagem NGINX leve para servir os arquivos estáticos.
# alpine é uma versão bem pequena do Linux.
FROM nginx:alpine


# Remove a configuração padrão do NGINX.
RUN rm /etc/nginx/conf.d/default.conf

# Copia os arquivos estáticos da aplicação React do estágio de 'build'.
# A pasta 'build' é onde 'npm run build' coloca os arquivos compilados.
COPY --from=build /app/build /usr/share/nginx/html

# Copia o arquivo de configuração customizado do NGINX.
# Este arquivo será o default.conf que você já tem no diretório frontend.
COPY default.conf /etc/nginx/conf.d/

# Expõe a porta 80, que é a porta padrão do NGINX para tráfego HTTP.
EXPOSE 80

# Comando padrão para iniciar o NGINX em primeiro plano.
CMD ["nginx", "-g", "daemon off;"]