admin = Usuario.find_or_initialize_by(correo: "admin@techmarket.com")
admin.assign_attributes(
  nombre: "Administrador Principal",
  password: "12345",
  rol: "administrador"
)
admin.save!

usuario = Usuario.find_or_initialize_by(correo: "usuario@techmarket.com")
usuario.assign_attributes(
  nombre: "Usuario de Prueba",
  password: "12345",
  rol: "usuario"
)
usuario.save!

categorias = {
  laptops: Categoria.find_or_create_by!(nombre: "Laptops") do |categoria|
    categoria.descripcion = "Computadoras portátiles para estudio, trabajo y entretenimiento."
  end,
  accesorios: Categoria.find_or_create_by!(nombre: "Accesorios") do |categoria|
    categoria.descripcion = "Periféricos y accesorios para computadora."
  end,
  audio: Categoria.find_or_create_by!(nombre: "Audio") do |categoria|
    categoria.descripcion = "Audífonos, bocinas y dispositivos de audio."
  end
}

laptop = Articulo.find_or_initialize_by(nombre: "Laptop Lenovo IdeaPad")
laptop.assign_attributes(
  descripcion: "Laptop para estudiantes, programación y tareas escolares.",
  precio: 12_500.00,
  stock: 8,
  categoria: categorias[:laptops],
  imagen_url: "https://example.com/laptop.jpg"
)
laptop.save!

mouse = Articulo.find_or_initialize_by(nombre: "Mouse Logitech Inalámbrico")
mouse.assign_attributes(
  descripcion: "Mouse compacto para oficina, escuela y uso diario.",
  precio: 350.00,
  stock: 25,
  categoria: categorias[:accesorios],
  imagen_url: "https://example.com/mouse.jpg"
)
mouse.save!

audifonos = Articulo.find_or_initialize_by(nombre: "Audífonos Gamer")
audifonos.assign_attributes(
  descripcion: "Audífonos con micrófono para videojuegos y videollamadas.",
  precio: 780.00,
  stock: 12,
  categoria: categorias[:audio],
  imagen_url: "https://example.com/audifonos.jpg"
)
audifonos.save!

promocion = Promocion.find_or_initialize_by(codigo: "BIENVENIDA10")
promocion.assign_attributes(
  nombre: "Descuento de bienvenida",
  descripcion: "10% de descuento en artículos seleccionados.",
  tipo_descuento: "porcentaje",
  valor: 10,
  fecha_inicio: Time.current.beginning_of_day,
  fecha_fin: 30.days.from_now.end_of_day,
  activa: true
)
promocion.save!
promocion.articulos = [mouse, audifonos]

puts "Datos de prueba creados o actualizados correctamente"
puts "Admin: admin@techmarket.com / 12345"
puts "Usuario: usuario@techmarket.com / 12345"
