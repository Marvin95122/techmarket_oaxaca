CompraItem.destroy_all
Compra.destroy_all
CarritoItem.destroy_all
Resena.destroy_all
Articulo.destroy_all
Usuario.destroy_all

admin = Usuario.create!(
  nombre: "Administrador Principal",
  correo: "admin@techmarket.com",
  password: "12345",
  rol: "administrador"
)

usuario = Usuario.create!(
  nombre: "Usuario de Prueba",
  correo: "usuario@techmarket.com",
  password: "12345",
  rol: "usuario"
)

Articulo.create!(
  nombre: "Laptop Lenovo IdeaPad",
  descripcion: "Laptop para estudiantes, programación y tareas escolares.",
  precio: 12500.00,
  stock: 8,
  categoria: "Laptops",
  imagen_url: "https://example.com/laptop.jpg"
)

Articulo.create!(
  nombre: "Mouse Logitech Inalámbrico",
  descripcion: "Mouse compacto para oficina, escuela y uso diario.",
  precio: 350.00,
  stock: 25,
  categoria: "Accesorios",
  imagen_url: "https://example.com/mouse.jpg"
)

Articulo.create!(
  nombre: "Audífonos Gamer",
  descripcion: "Audífonos con micrófono para videojuegos y videollamadas.",
  precio: 780.00,
  stock: 12,
  categoria: "Audio",
  imagen_url: "https://example.com/audifonos.jpg"
)

puts "Datos de prueba creados correctamente"
puts "Admin: admin@techmarket.com / 12345"
puts "Usuario: usuario@techmarket.com / 12345"