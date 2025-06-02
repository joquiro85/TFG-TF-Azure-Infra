
# 🌐 Infraestructura TFG en Azure con Terraform

Este repositorio contiene toda la infraestructura necesaria para el proyecto **TFG** desplegada en **Microsoft Azure** mediante **Terraform**, junto con scripts auxiliares para el aprovisionamiento y la operación diaria.

Se compone de **dos módulos Terraform** y **dos scripts** principales:

* **`RG-DNSZones/`** – Crea el *Resource Group* raíz y la **zona DNS** pública.
* **`Infra/`** – Despliega redes, balanceador, VMSS, Jump‑box, reglas DNS y políticas de escalado.
* **`user_data.sh`** – *cloud‑init* que configura automáticamente cada instancia de la VMSS.
* **`JumpboxRule.ps1`** – Script PowerShell que actualiza dinámicamente la regla de acceso SSH a la Jump‑box para tu IP pública.

---

# Estructura del Proyecto `TF-INFRA-AZURE`

```plaintext

TF-INFRA-AZURE/
├── .terraform/
├── Infra/
│   ├── .terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars
│   ├── user_data.sh
│   └── variables.tf
├── RG-DNSZones/
│   ├── .terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars
│   └── variables.tf
├── jumpboxRule.ps1
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
> Ejecutar **primero**, ya que el resto de módulos dependen de la zona.

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

* **NSG** `web_nsg` (HTTP / SSH interno)
* **NSG** `jumpbox_nsg` (SSH – placeholder)

> La regla `Allow-SSH-Jumpbox` se crea con origen `0.0.0.0/32`, es decir **cerrada por defecto**

### VMSS + Auto‑scaling

* VMSS Ubuntu con NGINX desplegado en la subred privada
* Escalado de 2→4 instancias según **CPU > 70 %**
* *cloud‑init* `user_data.sh` para instalar NGINX, clonar la web y mostrar el `vmId`

### Jumpbox VM

* VM pública con acceso SSH (con IP estática)
* Sirve de punto bastión a la red privada

### Registros DNS

* Registro A: `@` → IP pública del LB
* Registro CNAME: `www.tfg-joqr.es` → dominio raíz

---

## 3.  Script utilitario `JumpboxRule.ps1`

Terraform deja la regla **SSH** del *Network Security Group* **cerrada** a todo el mundo para evitar exposiciones accidentales.
`JumpboxRule.ps1` es un pequeño **helper** en PowerShell que sustituye dinámicamente el valor `0.0.0.0/32` por **tu IP pública actual** y deja listo el acceso.

### ¿Qué hace exactamente?

1. Detecta la IP pública del equipo (servicio `https://ifconfig.co` o similar).
2. Se conecta a Azure con el *Az Module* y localiza el NSG, regla y RG indicados.
3. Actualiza `sourceAddressPrefix` y aplica los cambios con <code>Set‑AzNetworkSecurityGroup</code>.
4. Muestra por pantalla la dirección SSH de la Jump‑box.

### Requisitos

* PowerShell 7.x
* Módulos **Az.Accounts** y **Az.Network** (`Install-Module Az -Scope CurrentUser`)


### Uso rápido

```powershell
# Inicia sesión o refresca el contexto
Connect-AzAccount

# Concede acceso SSH a tu IP durante la sesión
./JumpboxRule.ps1 -ResourceGroupName "TFG-Infra" -NSGName "nsg jumpbox" -RuleName "Allow-SSH-Jumpbox"
```

Parámetros opcionales:

| Parámetro         | Descripción                               |
| ----------------- | ----------------------------------------- |
| `-IPAddress <ip>` | Forzar una IP distinta a la autodetectada |
| `-Remove`         | Revierte la regla al estado **cerrado**   |
| `-Verbose`        | Muestra detalles de depuración            |

---

## 4. Script `user_data.sh`

Se inyecta como *custom data* en el VMSS y realiza:

1. Actualiza paquetes e instala **nginx**, **git**, **stress** y **netcat**.
2. Clona `tfg-html-azure` y lo copia a `/var/www/html`.
3. Sustituye la marca `$INSTANCE_ID` del `index.html` por el identificador real de la VM (metadata IMDS).
4. Arranca y habilita NGINX.

De esta forma cada instancia muestra su propio **VM ID** en la página de estado

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
jumpuserpassword        = "jumpPassword123!"
vm_username             = "adminuser"
vm_password             = "wmpassword!"
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

## Buenas prácticas y protecciones

* `prevent_destroy` en el RG y la zona DNS.
* NSGs dedicados a **web** y **jump‑box**.
* Regla SSH cerrada hasta que `JumpboxRule.ps1` la abre explícitamente.
* Autoscaling según métricas de Azure Monitor.

---

##  Autor

**Jesús Quimbay Rojas**
Trabajo Final de Grado — ASIR



