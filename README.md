# Apresentação

A presente é uma aplicação Laravel em branco, configurada para operar em um servidor Nginx. Serão delineadas as etapas para configurar esta aplicação em um contêiner, além de estabelecer a conexão com um contêiner em execução contendo o MySQL.

## Construção do Projeto

### Com DockerFile

O Dockerfile está designado para construir um contêiner configurado com Nginx e Laravel. O banco de dados será provisionado utilizando a imagem atual do MySQL. Antes de proceder à criação dos contêineres, é necessário estabelecer uma rede que permita a comunicação entre os dois contêineres, além de criar um volume gerenciado pelo Docker para armazenar os dados do MySQL, garantindo acesso contínuo às informações mesmo após o encerramento dos contêineres.

1. Criando uma rede no docker

```
docker network create net-lara-mysql
```

2. Criando um volume gerenciado pelo docker

```
docker volume create vdados
```

3. Criado a rede e volume, primeiro vamos criar o container para o mysql:

```
docker run --name dbmysql --network net-lara-mysql \
  -e MYSQL_ROOT_PASSWORD=12345678 \
  -e MYSQL_DATABASE=appdados \
  -e MYSQL_USER=appdados \
  -e MYSQL_PASSWORD=12345678 \
  -v vdados:/var/lib/mysql \
  -p 3307:3306 \
  -d mysql:latest
```

4. No contêiner que será criado, iremos mapear o volume da aplicação para dentro do contêiner, permitindo a alteração do código enquanto o contêiner está em execução. No entanto, isso pode ocasionar um problema quando o contêiner precisar modificar as informações de cache nos diretórios 'storage' e 'bootstrap'. Isso ocorrerá porque o contêiner tentará manipular os diretórios com o usuário 'www-data', enquanto em nossa máquina apenas nosso usuário terá permissão para alterá-los. Para resolver esse problema, existem possíveis soluções:

  - Transferir o controle desses diretórios para o usuário 'www-data':

  ```
    sudo chown -R www-data:www-data storage
    sudo chown -R www-data:www-data bootstrap
  ```

  - Atribuir permissões para que todos os usuários possam ler, escrever e executar neste diretório (embora não recomendado). Em um ambiente local de desenvolvimento, isso não causará problemas.

  ```
    sudo chmod -R 777 /var/www/storage /var/www/bootstrap

  ```

5. Já que criamos o contêiner para o MySQL antes de criar o contêiner da aplicação, vamos configurar o acesso ao banco de dados com as informações utilizadas no contêiner do banco de dados. Essa configuração é definida no arquivo '.env'.:

```
DB_CONNECTION=mysql
DB_HOST=dbmysql
DB_PORT=3306
DB_DATABASE=appdados
DB_USERNAME=appdados
DB_PASSWORD=12345678

```

6. Agora vamos criar a imagem do contêiner e o contêiner da aplicação:

```
docker build -t image-laravel .
```

```
docker run -p 8080:80 -v $(pwd):/var/www  --network net-lara-mysql --name applaravel image-laravel
```

Neste ponto, a aplicação já pode ser acessada no navegador através da porta 8080. Para que a aplicação funcione, será necessário instalar as dependências do Laravel usando o comando:

```
  docker exec applaravel composer install
```

Para garantair que o contêiner se conectou ao banco, vamos executar a migrate de criação de usuário do laravel:

```
  docker exec applaravel php artisan migrate
```

Se tudo ocorreu bem, no terminal serão apresentadas as tabelas criadas pela aplicação.

### Com Docker Composer

O arquivo Docker Compose presente no diretório já mapeia os diretórios da aplicação, além de configurar um volume gerenciado pelo Docker e colocar os contêineres na mesma rede. Portanto, a única ação necessária é executar os comandos na raiz do projeto que criam as imagens locais e os contêineres."

```
docker compose up -d
```

Em ambos os exemplos, o banco de dados pode ser acessado por um Sistema de Gerenciamento de Banco de Dados (SGBD) através da porta mapeada para a rede externa 3307.
  