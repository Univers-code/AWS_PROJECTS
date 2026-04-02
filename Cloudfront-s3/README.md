# yeniel-landing

Proyecto de aprendizaje de **Amazon S3 y CloudFront**, donde se implementa un sitio web estático utilizando AWS CLI y se configura una distribución CDN para servir contenido 
globalmente.

---

## 📌 Descripción

Este proyecto tiene como objetivo practicar la **infraestructura cloud básica** y aprender:

- Crear y gestionar buckets en **S3**.  
- Subir archivos estáticos (`HTML`, `CSS`, `JS`, imágenes) al bucket.  
- Configurar políticas de acceso seguras con **Bucket Policy**.  
- Servir contenido globalmente mediante **CloudFront**.  
- Usar la **CLI de AWS** para automatizar la subida de archivos y invalidar la cache de CloudFront.

---

## 🏗 Arquitectura

```text
Usuario
   ↓
CloudFront (CDN)
   ↓
S3 Bucket (archivos estáticos)
