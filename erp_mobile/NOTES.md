# Notas 

> Tomar en cuenta:
- Cargar modelo usando `file_picker`
- Usar CPU en lugar de GPU en Tecno Spark Go 1 

- Modelos como Phi-4 tardan 2 minutos en cargarse
- Modelos como Qwen2.5 tardan 2 minutos en cargarse

- Modelos como Phi-4 tardan 7 minutos en iniciar 
- Modelos como Qwen2.5 tardan 4 minutos en iniciar

- Modelos como Phi-4 tardan 2 minutos en contestar
- Modelos como Qwen2.5 tardan 1.5 minutos en contestar 

📦 GET {{base_url}}/inventory
> ¿Qué hace?
- Devuelve el estado actual del inventario de todos los productos (o filtrados por ubicación, si la API lo permite). Para cada producto en cada ubicación (ej. MAIN), obtienes:

> Campo	Significado
- on_hand	Cantidad física disponible en almacén (sin reservas)
- reserved	Cantidad apartada para pedidos/ventas no confirmadas
- available	Cantidad real que se puede vender (on_hand - reserved)
- min_stock	Stock mínimo de seguridad (para alertas)
- status	AVAILABLE (disponible), LOW_STOCK, OUT_OF_STOCK
- location_id	Ubicación del stock (ej. almacén principal)

> Módulo	Impacto en inventario
- Ventasl: Al crear una venta, deberías restar stock (OUT).
- Compras:	Al crear una compra, deberías sumar stock (IN).
- Ajustes manuales:	Usar este endpoint para corregir stock por conteo físico, mermas, etc.