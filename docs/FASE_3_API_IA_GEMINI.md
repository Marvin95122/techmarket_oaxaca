# Fase 3: integración de Google Gemini

## Objetivo

Integrar una API externa de inteligencia artificial en el backend Ruby on Rails sin exponer la clave privada en el frontend.

## Arquitectura

```text
Postman / React / aplicación móvil
              |
              v
       API Rails con JWT
              |
              v
     Gemini Interactions API
              |
              v
Historial local en consultas_ia
```

## Endpoints agregados

### Estado de la integración

```http
GET /ia/estado
Authorization: Bearer TOKEN_ADMIN
```

### Chat sobre el catálogo

```http
POST /ia/chat
Authorization: Bearer TOKEN_USUARIO_O_ADMIN
Content-Type: application/json
```

```json
{
  "pregunta": "¿Qué productos con promoción tienen disponibles?"
}
```

### Recomendaciones personalizadas

```http
POST /ia/recomendaciones
Authorization: Bearer TOKEN_USUARIO_O_ADMIN
Content-Type: application/json
```

```json
{
  "presupuesto": 15000,
  "uso": "programación y universidad",
  "categoria_id": 1,
  "marca_id": 1
}
```

`categoria_id` y `marca_id` son opcionales.

## Variables de entorno

### PowerShell, sesión actual

```powershell
$env:GEMINI_API_KEY="TU_CLAVE_PRIVADA"
$env:GEMINI_MODEL="gemini-2.5-flash"
```

### Ubuntu, sesión actual

```bash
export GEMINI_API_KEY="TU_CLAVE_PRIVADA"
export GEMINI_MODEL="gemini-2.5-flash"
```

La clave nunca debe guardarse en GitHub, React, React Native o Flutter.

## Privacidad

Las solicitudes hacia Gemini incluyen `store: false`. El proyecto conserva su propio historial en PostgreSQL mediante la tabla `consultas_ia`.

## Prueba directa del proveedor en Postman

```http
POST https://generativelanguage.googleapis.com/v1/interactions
```

Headers:

```text
Content-Type: application/json
x-goog-api-key: {{gemini_api_key}}
```

Body:

```json
{
  "model": "gemini-2.5-flash",
  "input": "Responde en español: ¿qué es una API REST?",
  "store": false
}
```

## Seguridad

- La clave se lee mediante `ENV["GEMINI_API_KEY"]`.
- `/ia/chat` y `/ia/recomendaciones` exigen JWT de usuario o administrador.
- `/ia/estado` exige rol administrador.
- El backend filtra los productos reales antes de consultar Gemini.
- Las recomendaciones devuelven productos existentes y disponibles en PostgreSQL.
