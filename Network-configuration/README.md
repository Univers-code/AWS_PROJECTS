# AWS Network Setup Script

Este proyecto contiene un script en **Bash** para crear automáticamente una infraestructura de red básica en **AWS**, incluyendo:

- **VPC** con un rango de IP privado
- **Subnets públicas y privadas**
- **Internet Gateway**
- **Route Table para subnets públicas**
- **Asignación automática de IP pública para subnets públicas**
- **Etiquetas (tags)** para identificar todos los recursos por proyecto

---

## Descripción

El script `setup-network.sh` permite:

1. Crear una **VPC** con un CIDR block definido (`10.0.0.0/16`).  
2. Crear dos **subnets**:
   - Subnet pública (`10.0.1.0/24`) en la AZ `us-east-1a`  
   - Subnet privada (`10.0.2.0/24`) en la AZ `us-east-1b`  
3. Crear un **Internet Gateway** y asociarlo a la VPC.  
4. Crear una **Route Table pública**, asociada a la subnet pública, con ruta a Internet Gateway.  
5. Activar **IP pública automática** en la subnet pública.  
6. Etiquetar todos los recursos con `Project=aws-network` para facilitar identificación y automatización.

> Este script es ideal para **entornos de desarrollo y pruebas**, y sirve como base para arquitecturas más complejas con NAT Gateways, subnets 
privadas y multi-AZ.

---

## Requisitos

- **AWS CLI** instalado y configurado con credenciales y región.
- Permisos de IAM para:
  - `ec2:CreateVpc`
  - `ec2:DescribeVpcs`
  - `ec2:CreateSubnet`
  - `ec2:ModifySubnetAttribute`
  - `ec2:CreateInternetGateway`
  - `ec2:AttachInternetGateway`
  - `ec2:CreateRouteTable`
  - `ec2:CreateRoute`
  - `ec2:AssociateRouteTable`
  - `ec2:CreateTags`

---

## Uso

1. Clona o descarga el script en tu máquina:

```bash
git clone <tu-repo>
cd <tu-repo>/scriptsAws
