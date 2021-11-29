#  Terrafom mini-projet

## 1- Architecture
Contenu du répertoire de travail : <br>
\+ **Mini-projet**/ <br>
&emsp;&emsp;\+ **david-kp.pem** &emsp;# Clé privée à générer sur AWS<br> 
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

&emsp;&emsp;\+ **secret.ini** &emsp;# Clé d'accès AWS et mot de passe liés au compte utilisateur<br>
```
[default]
aws_access_key_id="Remplacer par votre access_key_id. Voir IAM"
aws_secret_access_key="Remplacer par votre secret_access_key". voir IAM.
```
&emsp;&emsp;\+ **app**/ &emsp; # Répertoire de l'application principale <br> 
&emsp;&emsp;&emsp;\+ **main.tf** &emsp; # Fichier principal utilisé pour le lancement des différents modules AWS <br>
```
# Utilisation du module EC2
module "ec2" {
  source              = "../Modules/EC2"        # Lien vers le répertoire du module
  author_name         = var.author_name         # Auteur du projet
  instance_type       = var.instance_type       # Type d'instance EC2 (t2.micro,t2.nano...)
  private_key_path    = var.private_key_path    # Clé privée généré sur AWS
  availability_zone   = var.ec2_avail_zone      # Zone de disponibilité de l'EC2. Cette variable est également utilisée par le module EBS car l'EBS doit être dans la même zone que l'EC2
  sg_name             = module.sg.out-sg-name   # Association de l'instance EC2 au module SG
  public_ip           = module.eip.out_eip_ip   # Address IP publique utilisé pour consommer le service
}

# Utilisation du module SG
module "sg" {
  source   = "../Modules/SG"    # Lien vers le répertoire du module
  tag_name = var.author_name    # Nom du tag
}

# Utilisation du module EIP
module "eip" {
  source      = "../Modules/EIP"    # Lien vers le répertoire du module   
  author_name = var.author_name     # Nom du tag
}

# Utilisation du module EBS
module "ebs" {
  source         = "../Modules/EBS"     # Lien vers le répertoire du module
  author_name    = var.author_name      # Nom du tag
  ebs_avail_zone = var.ec2_avail_zone   # Zone de disponibilité du module de stockage persistant
  ebs_size_gio   = var.ebs_size_gio     # Taile de stockage
}

# Cette ressource permet attribuer l'adresse IP publique créée à notre instance ec2
resource "aws_eip_association" "eip_association" {
  allocation_id = module.eip.out_eip_id     # Adresse IP publique issue du module EIP
  instance_id   = module.ec2.out-ec2-id     # Id de l'instance issue du module EC2
}

# Cette ressource permet de rattacher le volume de stockage persistant à notre instance EC2
resource "aws_volume_attachment" "ebs_attach" {     
  device_name = "/dev/sdf"      # Nom qu'aura le périphérique une fois monté sur l'instance EC2
  instance_id = module.ec2.out-ec2-id       # Id de l'instance issue du module EC2
  volume_id   = module.ebs.out_ebs_id       # Id du volume issue du module EBS
}
```
&emsp;&emsp;&emsp;\+ **provider.tf** &emsp; # Fichier de déclaration du provider permettant d'intéragir avec les fonctionnalité d'AWS <br>
```
# Permet de déclarer un plugin, ici AWS, afin de pouvoir utiliser ses fonctionnalités
provider "aws" { 
  region                  = var.region      # nom de la région souhaitée. Cette région définie l'emplacement géographique du datacenter souhaité.
  shared_credentials_file = var.secret_path     # Clé secrète renseignée dans le fichier secret.ini. Elle est nécessaire pour permettre à terraform d'interagir avec votre compte AWS.
}
```
&emsp;&emsp;&emsp;\+ **variables.tf** &emsp; # Fichier contenant les variables utilisés dans les modules et le fichier /app/main.tf <br>
```
variable "secret_path" { 
  type    = string
  default = "<paste your secret path>"
}

variable "region" {
  type    = string
  default = "<paste your required region>"
}

variable "author_name" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ec2_avail_zone" {
  type = string
}

variable "ebs_size_gio" {
  type = number
}

```
&emsp;&emsp;&emsp;\+ **terraform.tfvars** &emsp; # Fichier permettant de surcharger les variables définies dans variables.tf <br>
```
secret_path         = "<Chemin d'accès du fichier contenant vos accès et mot de passe AWS voir IAM>"
region              = "us-east-1" # région souhaitée
private_key_path    = "<Chemin d'accès du fichier contenant votre clé privé>"
ec2_avail_zone      = "us-east-1a" # zone de disponibilité au sein de la région
ebs_size_gio        = 2 # Taille du volume de stockage
author_name         = "david" # nom de l'auteur du projet

```
&emsp;&emsp;\+ **Modules**/ &emsp; # Répertoire dans lequel se trouve les modules <br>
&emsp;&emsp;&emsp;\+ **EBS** &emsp; # Répertoire du module EBS. Ce module permet de créer un volume de stockage de block persistant utilisable avec une instance EC2. <br>
&emsp;&emsp;&emsp;&emsp;\+ **main.tf** &emsp; # fichier principal du module EBS.<br>
```
# Création d'un volume de stockage
resource "aws_ebs_volume" "ebs" { 
  availability_zone = var.ebs_avail_zone
  size              = var.ebs_size_gio
  tags = {
    Name = "${var.author_name}-ebs"
  }
}

```
&emsp;&emsp;&emsp;&emsp;\+ **output.tf** &emsp; # fichier contenant les variables en sortie du module EBS. Ces variables peuvent être utilisées lors de la déclaration d'un module dans le fichier /app/main.tf <br>
```
# Définition de la valeur de sortie. Ici l'id de volume de stockage
output "out_ebs_id" { 
  value = aws_ebs_volume.ebs.id     
}
```
&emsp;&emsp;&emsp;&emsp;\+ **variables.tf** &emsp; Fichier contenant les variables utilisés uniquement dans le module EBS.<br>
```
variable "ebs_size_gio" {
  type = number
}

variable "ebs_avail_zone" {
  type = string
}

variable "author_name" {
  type = string
}

```
&emsp;&emsp;&emsp;\+ **EC2** &emsp; # Répertoire du module EC2. Ce module permet de créer une instance de type Elastic Compute, c'est-à-dire, une marchine virtuelle. <br>
&emsp;&emsp;&emsp;&emsp;\+ **main.tf** &emsp; # fichier principal du module EC2.<br>
```
# Création d'une instance EC2
resource "aws_instance" "ec2" { 
  ami                    = data.aws_ami.ami-ubuntu-bionic.id # Utilisation de l'AMI crée si dessous
  instance_type          = var.instance_type
  security_groups        = ["${var.sg_name}"]       # Association du groupe de sécurité SG à l'instance EC2
  availability_zone      = var.availability_zone
  key_name               = "${var.author_name}-kp"

  tags = {
    Name : "ec2-${var.author_name}"
  }

  # Lancement de code personnalisé en local machine. Ici var.public_ip désigne l'addresse ip publique crée et associé à l'instance EC2
  provisioner "local-exec" { 
    command = "echo IP : ${var.public_ip}, ID: ${aws_instance.ec2.id}, Zone: ${aws_instance.ec2.availability_zone} >> private_data.txt"
  }

  # Lancement de code personnalisé sur cible  
  provisioner "remote-exec" {
    connection { # Paramètres de la connection SSHll
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip #  adresse IP de la machine virtuelle inaccessible depuis l'extérieur
    }

    # Installation du paquet nginx et activation et démarrage de ce dernier
    inline = [  
      "sudo apt update -y",
      "sudo apt install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }
}

# Utilisation d'une AMI, un instantanné d'une machine virtuelle pré configurée avec un OS.
data "aws_ami" "ami-ubuntu-bionic" { 
  most_recent = true # Utiliser l'image la plus récente
  owners      = ["099720109477"] # Propriétaire de l'image (ubuntu)
  tags = {
    Name = "${var.author_name}-ec2-ami-t2-ubuntu-bionic"
  }

  # Filtre permettant de rechercher une instance précise
  filter { 
    name   = "name" # Filtrage par le nom 
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server*"]
  }
}
```
&emsp;&emsp;&emsp;&emsp;\+ **output.tf** &emsp; # fichier contenant les variables en sortie du module EC2. Ces variables peuvent être utilisées lors de la déclaration d'un module dans le fichier /app/main.tf <br>
```
# Définition de la valeur de sortie. Ici l'id de l'instance EC2
output "out-ec2-id" { 
  value = aws_instance.ec2.id
}

```
&emsp;&emsp;&emsp;&emsp;\+ **variables.tf** &emsp; Fichier contenant les variables utilisées uniquement dans le module EC2.<br>
```
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "author_name" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "sg_name" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "public_ip" {
  type = string
}

```
&emsp;&emsp;&emsp;\+ **EIP** &emsp; #  Répertoire du module EIP. Ce module permet de créer une adresse publique statique temporaire. <br> <br>
&emsp;&emsp;&emsp;&emsp;\+ **main.tf** &emsp; # fichier principal du module EIP.<br>
```
#  Création d'une adresse IP publique
resource "aws_eip" "eip" { 
  vpc = true #  cette adresse IP se trouve dans le VPC principale 
  tags = {
    Name = "${var.author_name}-eip"
  }
}

```
&emsp;&emsp;&emsp;&emsp;\+ **output.tf** &emsp; # fichier contenant les variables en sortie du module EIP. Ces variables peuvent être utilisées lors de la déclaration d'un module dans le fichier /app/main.tf <br>
```
 # Définition de la valeur de sortie. Ici l'adresse ip publique 
output "out_eip_ip" { 
  value = aws_eip.eip.public_ip
}

# Définition de la valeur de sortie. Ici l'id de l'EIP
output "out_eip_id" {  
  value = aws_eip.eip.id
}

```
&emsp;&emsp;&emsp;&emsp;\+ **variables.tf** &emsp; Fichier contenant les variables utilisées uniquement dans le module EIP.<br>
```
variable "author_name" {
  type = string
}

```
&emsp;&emsp;&emsp;\+ **SG** &emsp; # Répertoire du module SG.  Ce module permet de créer un groupe de sécurité permettant la configuration des ports et adresse ip d'un réseau. <br>
&emsp;&emsp;&emsp;&emsp;\+ **main.tf** &emsp; # fichier principal du module SG.<br>
```
# Création d'un groupe de sécurité
resource "aws_security_group" "sg" { 
  name        = "${var.tag_name}-sg"
  description = "Allow SSH, HTTP and HTTPS inbound traffic"

  ingress { # Autoriser les flux entrant sur le port 80, c'est-à-dire HTTP.
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress { # Autoriser les flux entrant sur le port 22, c'est-à-dire les connexions en SSH.
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress { # Autoriser les flux entrant sur le port 443, c'est-à-dire HTTPS.
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress { # Autoriser les flux sortant sur tous les ports. 
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.tag_name}-sg"
  }
}

```
&emsp;&emsp;&emsp;&emsp;\+ **output.tf** &emsp; # fichier contenant les variables en sortie du module SG. Ces variables peuvent être utilisées lors de la déclaration d'un module dans le fichier /app/main.tf <br>
```
# Définition de la valeur de sortie. Ici le nom du groupe de sécurité 
output "out-sg-name" { 
  value = aws_security_group.sg.name
}

```
&emsp;&emsp;&emsp;&emsp;\+ **variables.tf** &emsp; # Fichier contenant les variables utilisées uniquement dans le modules SG.<br>
```
variable "tag_name" {
  type = string
}

```

## 2- Utilisation
1. Créer un fichier terraform.tfvars dans le répertoire app
2. Créer une clé privé sur AWS et la copier dans un fichier 
3. Dans votre fichier terraform.tfvars, renseigner le chemin de ce fichier dans la variable **private_key_path**
> Exemple: private_key_path = /fome/foo/secrets/foo-kp.pem
4. Créer votre fichier secret.ini comme ci-dessus et renseigner le chemin de ce fichier dans la variable **secret_path**
> Exemple: secret_path = /fome/foo/secrets/mini-projet.ini   
5. Dans votre fichier terraform.tfvars, renseigner la région où vous souhaite que votre instance EC2 soit déployée dans la variable **region**
> Exemple: region = "us-east-1"
6. Dans votre fichier terraform.tfvars, renseigner la zone de disponibilité souhaitée dans la varibale **ec2_avail_zone**
> Exemple: ec2_avail_zone = "us-east-1a"
7. Dans votre fichier terraform.tfvars, renseigner la taille du volume de stockage souhaitée dans la variable **ebs_size_gio**
> Exemple: ebs_size_gio = 1
8. Dans votre fichier terraform.tfvars, renseigner le nom de l'auteur dans la variable **author_name**
> Exemple: author_name = foo
9. Lancer la commande 
> terrform init 
> terraform plan 
> terraform apply
