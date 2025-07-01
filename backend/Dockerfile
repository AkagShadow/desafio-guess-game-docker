# Usa uma imagem base oficial do Python.
# python:3.9-slim-buster é uma boa escolha pois é leve e baseada em Debian.
FROM python:3.9-slim-buster

# Define o diretório de trabalho dentro do container.
# Todos os comandos subsequentes serão executados a partir deste diretório.
WORKDIR /app

# Copia o arquivo requirements.txt para o diretório de trabalho.
# Isso permite que o Docker use o cache de camadas de forma eficiente.
COPY requirements.txt .

# Instala as dependências Python especificadas no requirements.txt.
# --no-cache-dir garante que não haja cache de pacotes, economizando espaço.
# -r instala as dependências do arquivo.
RUN pip install --no-cache-dir -r requirements.txt

# Copia todo o restante do código-fonte do backend para o diretório de trabalho.
# O ponto final '.' no destino significa o WORKDIR (/app).
COPY . .

# Define variáveis de ambiente para o Flask.
# FLASK_APP aponta para o arquivo principal da aplicação (run.py neste caso, conforme a estrutura).
# FLASK_ENV define o ambiente para produção para melhor performance e segurança.
ENV FLASK_APP=run.py
ENV FLASK_ENV=production

# Expõe a porta em que a aplicação Flask irá rodar.
# Por padrão, Flask roda na porta 5000.
EXPOSE 5000

# Comando para iniciar a aplicação Flask.
# Usa um servidor de produção como Gunicorn para robustez e performance em ambiente real.
# Você precisará adicionar 'gunicorn' ao seu requirements.txt, ou instalá-lo aqui.
# Por simplicidade inicial, vamos usar o comando padrão do Flask para testes.
# Posteriormente, podemos mudar para Gunicorn no docker-compose.

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]