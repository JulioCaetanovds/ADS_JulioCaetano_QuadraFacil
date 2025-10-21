# Dockerfile para a API Node.js/TypeScript Quadra Fácil

# ---- Estágio 1: Build ----
# Usamos uma imagem Node.js específica (versão 20 LTS - Alpine é uma versão leve) como base
FROM node:20-alpine AS builder

# Define o diretório de trabalho dentro do contêiner
WORKDIR /app

# Copia os arquivos de definição de dependências PRIMEIRO
# Isso aproveita o cache do Docker: se esses arquivos não mudarem, o 'npm install' não roda de novo
COPY package.json package-lock.json ./

# Instala SOMENTE as dependências de produção (ignora --save-dev)
RUN npm install --omit=dev

# Copia o restante do código da API para dentro do contêiner
COPY . .

# Compila o TypeScript para JavaScript
RUN npm run build

# ---- Estágio 2: Produção ----
# Usamos uma nova imagem base, ainda menor, apenas para rodar
FROM node:20-alpine

WORKDIR /app

# Copia as dependências de produção já instaladas do estágio 'builder'
COPY --from=builder /app/node_modules ./node_modules

# Copia o código JavaScript compilado do estágio 'builder'
COPY --from=builder /app/dist ./dist

# Copia o package.json (necessário para o comando 'start')
COPY package.json ./

# Expõe a porta 3000, que é a que nossa API usa
EXPOSE 3000

# O comando que será executado quando o contêiner iniciar
CMD ["npm", "start"]