#!/bin/bash
DOMAIN_NAME="${DOMAIN_NAME}"
DEMO_USERNAME="${DEMO_USERNAME}"
DEMO_PASSWORD="${DEMO_PASSWORD}"
DEMO_EMAIL="${DEMO_EMAIL}"
mkdir -p /var/www/html/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.${region}.amazonaws.com:/ /var/www/html/
yum install -y amazon-efs-utils
echo '${efs_id}.efs.${region}.amazonaws.com:/ /var/www/html/ efs defaults,_netdev 0 0' >> /etc/fstab
yum install -y httpd
systemctl start httpd
systemctl enable httpd
yum clean metadata
yum install -y php php-cli php-pdo php-fpm php-json php-mysqlnd php-dom
if [ ! -f /var/www/html/wp-config.php ]; then
  wget -O wordpress.tar.gz https://wordpress.org/wordpress-6.2.2.tar.gz
  tar -xzf wordpress.tar.gz
  cd wordpress
  cp wp-config-sample.php wp-config.php
  sed -i "s/database_name_here/${db_name}/g" wp-config.php
  sed -i "s/username_here/${db_username}/g" wp-config.php
  sed -i "s/password_here/${db_password}/g" wp-config.php
  sed -i "s/localhost/${db_host}/g" wp-config.php
  SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
  STRING='soyuncopodenieveunico'
  printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s wp-config.php

  cd ..
  cp -r wordpress/* /var/www/html/

  # WP CLI Install
  wget -O wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar
  php wp-cli.phar --info
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp

  # Setup WordPress
  wp --path=/var/www/html core install --allow-root \
  --url="https://${DOMAIN_NAME}" \
  --title="Terraform en AWS" \
  --admin_user="${DEMO_USERNAME}" \
  --admin_password="${DEMO_PASSWORD}" \
  --admin_email="${DEMO_EMAIL}"
fi
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id -s)

AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone -s)

PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4 -s)

HOSTNAME=$(hostname)

cat > /var/www/html/index2.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>EC2 Info</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
        }
        .info {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 8px;
        }
    </style>
</head>
<body>
    <h1>Servidor EC2</h1>
    <div class="info">
        <p><strong>Hostname :</strong> $(hostname)</p>
        <p><strong>Instance ID :</strong> $(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-to ken-ttl-seconds: 21600" -s) </p>
        <p><strong>Availability Zone :</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone -s)</p>
        <p><strong>IP privada :</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4 -s)</p>
    </div>
</body>
</html>
EOF
chown -R apache:apache /var/www/
systemctl restart httpd