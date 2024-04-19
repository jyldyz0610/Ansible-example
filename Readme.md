1. login zu AWS Console in Terminal

# AWS-Konfiguration und EC2-Bereitstellung

## AWS-Konfiguration

Bevor Sie fortfahren, stellen Sie sicher, dass Sie Ihre AWS-Zugangsdaten und -Berechtigungen haben.

1. AWS CLI konfigurieren:
   
   Führen Sie den Befehl `aws configure` aus und geben Sie Ihre AWS-Zugangsdaten ein, einschließlich Access Key ID, Secret Access Key, und Region.

2. AWS Single Sign-On (SSO) verwenden (falls erforderlich):
   
   Wenn Sie AWS Single Sign-On (SSO) verwenden, führen Sie den Befehl `aws sso login` aus, um sich anzumelden und temporäre Zugangsdaten zu erhalten.

## EC2-Instanz erstellen mit Terraform

1. Navigieren Sie zum Verzeichnis mit den Terraform-Dateien:

   ```sh
   cd tf-ec2



2. Führen Sie Terraform aus, um die EC2-Instanz zu erstellen:
terraform init
terraform plan
terraform apply


Ansible-Playbook ausführen:

Note: Dont forget to update inventory.ini with new IP address

ansible-playbook -i inventory.ini test-playbook.yaml -u ec2-user -b
