
# 🌐 Infraestructura TFG en Azure con Terraform

Este repositorio contiene la infraestructura del proyecto **TFG** desplegada en **Microsoft Azure** mediante **Terraform**. Se estructura en dos módulos principales:

- `RG-DNSZones/` – Crea el **Resource Group** principal y una **zona DNS pública**.
- `Infra/` – Contiene el resto de la infraestructura: redes, balanceador, máquinas virtuales, VMSS, reglas DNS y escalado automático.

---

# Estructura del Proyecto `TF-INFRA-AZURE`

```plaintext

TF-INFRA-AZURE/
├── .terraform/
├── Infra/
│   ├── .terraform/
│   ├── .terraform.lock.hcl
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   ├── terraform.tfvars
│   ├── user_data.sh
│   └── variables.tf
├── RG-DNSZones/
├── .gitignore
└── README.md

````

---

## 1. Módulo: `RG-DNSZones`

Este módulo despliega:
- Un **Resource Group** (`TFG-Infra`) con `prevent_destroy` activado.
- Una **zona DNS pública** (`tfg-joqr.es`) protegida contra eliminación accidental.

```hcl
resource "azurerm_resource_group" "main" { ... }
resource "azurerm_dns_zone" "tfg_zone" { ... }
````

✅ **Ejecutar primero**, ya que los demás módulos dependen de esta zona.

---

## 2. Módulo: `Infra`

Este módulo contiene la infraestructura principal del proyecto. Incluye:

### Redes y NAT

* Red virtual principal (`tfg-vnet`)
* Subred pública (`public-subnet-1`) y privada (`private-subnet-1`)
* NAT Gateway para salida a Internet desde la subred privada

### Load Balancer

* IP pública para LB
* Load Balancer Azure con sonda HTTP y regla para tráfico TCP/80
* Backend Pool conectado al VMSS

### Seguridad

* NSG (`web_nsg`) para tráfico HTTP/SSH
* Asociaciones de NSG a interfaces de red

### Escalado (VMSS)

* VMSS con NGINX desplegado en subred privada
* Autoscaling según uso de CPU

### Jumpbox VM

* VM pública con acceso SSH (con IP estática)
* Accede a las VMs privadas (VMSS o base de datos)

### Registros DNS

* Registro A: `@` → IP pública del LB
* Registro CNAME: `www.tfg-joqr.es` → dominio raíz

---

## Despliegue

### 1. Inicializa Terraform

```bash
cd RG-DNSZones/
terraform init
terraform apply

cd ../Infra/
terraform init
terraform apply
```

### 2. Variables requeridas

Define las variables en un archivo `terraform.tfvars` como:

```hcl
resource_group_name     = "TFG-Infra"
location                = "westus2"
vm_size                 = "Standard_B1s"
availability_zone_1     = "1"
jumpusername            = "azureuser"
jumpuserpassword        = "TuPassword123!"
vm_username             = "adminuser"
vm_password             = "Admin123!"
vnet_address_space      = ["10.0.0.0/16"]
public_subnet_cidr_1    = "10.0.1.0/24"
private_subnet_cidr_1   = "10.0.2.0/24"
image_reference = {
  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = "18.04-LTS"
  version   = "latest"
}
```

---

## Protecciones

* `prevent_destroy` en RG y zona DNS para evitar eliminación accidental.
* Seguridad controlada por NSGs en cada componente crítico.

---

##  Autor

**Jesús Quimbay Rojas**
Trabajo Final de Grado — ASIR
\[DigitechFP]



