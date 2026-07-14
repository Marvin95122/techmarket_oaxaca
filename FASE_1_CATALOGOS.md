# Fase 1: catálogos, promociones, reportes e historial de IA

Esta versión agrega:

- Categorías normalizadas para artículos.
- Promociones y relación muchos-a-muchos con artículos.
- Reporte de ventas calculado desde compras y compra_items.
- Tabla de historial para futuras consultas de inteligencia artificial.
- APIs REST para categorías y promociones.
- Filtros de artículos por categoría, búsqueda y existencia.

## Ejecutar

```bash
bundle install
rails db:migrate
rails db:seed
rails routes
rails server -b 0.0.0.0 -p 3000
```
