<?php

namespace Database\Seeders;

use App\Models\Almacen;
use App\Models\Atributo;
use App\Models\AtributoValor;
use App\Models\Categoria;
use App\Models\Marca;
use App\Models\Producto;
use App\Models\ProductoAlmacenStock;
use App\Models\Proveedor;
use App\Models\SubCategoria;
use App\Models\SubMarca;
use App\Models\UnidadMedida;
use Illuminate\Database\Seeder;

class CatalogSeeder extends Seeder
{
    public function run(): void
    {
        // ── Unidades de Medida ──
        $unidades = [
            ['nombre' => 'Unidad', 'abreviatura' => 'u'],
            ['nombre' => 'Kilogramo', 'abreviatura' => 'kg'],
            ['nombre' => 'Litro', 'abreviatura' => 'l'],
            ['nombre' => 'Bolsa', 'abreviatura' => 'bolsa'],
            ['nombre' => 'Caja', 'abreviatura' => 'caja'],
            ['nombre' => 'Paquete', 'abreviatura' => 'pqte'],
            ['nombre' => 'Galón', 'abreviatura' => 'gal'],
            ['nombre' => 'Gramo', 'abreviatura' => 'g'],
        ];
        foreach ($unidades as $u) {
            UnidadMedida::create($u);
        }
        $uUnidad = UnidadMedida::where('abreviatura', 'u')->first();
        $uKg = UnidadMedida::where('abreviatura', 'kg')->first();
        $uLitro = UnidadMedida::where('abreviatura', 'l')->first();

        // ── Categorías ──
        $catAbarrotes = Categoria::create(['nombre' => 'Abarrotes', 'nivel' => 1]);
        $catBebidas = Categoria::create(['nombre' => 'Bebidas', 'nivel' => 1]);
        $catLimpieza = Categoria::create(['nombre' => 'Limpieza', 'nivel' => 1]);

        SubCategoria::create(['categoria_id' => $catAbarrotes->id, 'nombre' => 'Lácteos']);
        SubCategoria::create(['categoria_id' => $catAbarrotes->id, 'nombre' => 'Enlatados']);
        SubCategoria::create(['categoria_id' => $catAbarrotes->id, 'nombre' => 'Granos y Cereales']);
        SubCategoria::create(['categoria_id' => $catBebidas->id, 'nombre' => 'Gaseosas']);
        SubCategoria::create(['categoria_id' => $catBebidas->id, 'nombre' => 'Jugos']);
        SubCategoria::create(['categoria_id' => $catBebidas->id, 'nombre' => 'Aguas']);
        SubCategoria::create(['categoria_id' => $catLimpieza->id, 'nombre' => 'Lavandería']);
        SubCategoria::create(['categoria_id' => $catLimpieza->id, 'nombre' => 'Cocina']);

        // ── Marcas ──
        $marcaGloria = Marca::create(['nombre' => 'Gloria']);
        $marcaSanFernando = Marca::create(['nombre' => 'San Fernando']);
        $marcaNestle = Marca::create(['nombre' => 'Nestlé']);
        $marcaCocaCola = Marca::create(['nombre' => 'Coca-Cola']);
        $marcaSapolio = Marca::create(['nombre' => 'Sapolio']);

        SubMarca::create(['marca_id' => $marcaGloria->id, 'nombre' => 'Gloria Leche']);
        SubMarca::create(['marca_id' => $marcaGloria->id, 'nombre' => 'Gloria Yogurt']);
        SubMarca::create(['marca_id' => $marcaSanFernando->id, 'nombre' => 'San Fernando Pollo']);
        SubMarca::create(['marca_id' => $marcaNestle->id, 'nombre' => 'Nestlé Cereales']);
        SubMarca::create(['marca_id' => $marcaCocaCola->id, 'nombre' => 'Coca-Cola Original']);
        SubMarca::create(['marca_id' => $marcaCocaCola->id, 'nombre' => 'Coca-Cola Zero']);
        SubMarca::create(['marca_id' => $marcaSapolio->id, 'nombre' => 'Sapolio Lavandería']);

        // ── Atributos ──
        $attrTamanio = Atributo::create(['nombre' => 'Tamaño']);
        $attrColor = Atributo::create(['nombre' => 'Color']);
        $attrSabor = Atributo::create(['nombre' => 'Sabor']);

        $valGrande = AtributoValor::create(['atributo_id' => $attrTamanio->id, 'valor' => 'Grande']);
        $valMediano = AtributoValor::create(['atributo_id' => $attrTamanio->id, 'valor' => 'Mediano']);
        $valPequeno = AtributoValor::create(['atributo_id' => $attrTamanio->id, 'valor' => 'Pequeño']);
        AtributoValor::create(['atributo_id' => $attrColor->id, 'valor' => 'Rojo']);
        AtributoValor::create(['atributo_id' => $attrColor->id, 'valor' => 'Azul']);
        AtributoValor::create(['atributo_id' => $attrColor->id, 'valor' => 'Verde']);
        AtributoValor::create(['atributo_id' => $attrSabor->id, 'valor' => 'Fresa']);
        AtributoValor::create(['atributo_id' => $attrSabor->id, 'valor' => 'Vainilla']);
        AtributoValor::create(['atributo_id' => $attrSabor->id, 'valor' => 'Chocolate']);

        // ── Proveedores ──
        Proveedor::create(['nombre' => 'Distribuidora Gloria S.A.C.', 'codigo' => 'PROV001', 'ruc' => '20123456780', 'direccion' => 'Av. Industrial 500', 'telefono' => '999000111', 'email' => 'ventas@gloria.com.pe', 'contacto_nombre' => 'Carlos López']);
        Proveedor::create(['nombre' => 'San Fernando S.A.', 'codigo' => 'PROV002', 'ruc' => '20123456781', 'direccion' => 'Carretera Central Km 15', 'telefono' => '999000222', 'email' => 'ventas@sanfernando.com.pe', 'contacto_nombre' => 'María García']);
        Proveedor::create(['nombre' => 'Corporación Lindley S.A.', 'codigo' => 'PROV003', 'ruc' => '20123456782', 'direccion' => 'Av. Venezuela 3000', 'telefono' => '999000333', 'email' => 'ventas@lindley.com.pe', 'contacto_nombre' => 'José Martínez']);
        Proveedor::create(['nombre' => 'Distribuidora Nestlé Perú', 'codigo' => 'PROV004', 'ruc' => '20123456783', 'direccion' => 'Av. Elmer Faucett 400', 'telefono' => '999000444', 'email' => 'ventas@nestle.com.pe', 'contacto_nombre' => 'Ana Torres']);
        Proveedor::create(['nombre' => 'Sapolio S.A.C.', 'codigo' => 'PROV005', 'ruc' => '20123456784', 'direccion' => 'Jr. Limpieza 250', 'telefono' => '999000555', 'email' => 'ventas@sapolio.com.pe', 'contacto_nombre' => 'Pedro Ramírez']);

        // ── Almacenes ──
        $almacenPrincipal = Almacen::create(['nombre' => 'Almacén Principal', 'codigo' => 'ALM001', 'tipo' => 'principal', 'direccion' => 'Av. Principal 123', 'activo' => true]);
        Almacen::create(['nombre' => 'Tienda Centro', 'codigo' => 'ALM002', 'tipo' => 'tienda', 'direccion' => 'Jr. Lima 456', 'activo' => true]);
        Almacen::create(['nombre' => 'Almacén de Tránsito', 'codigo' => 'ALM003', 'tipo' => 'transito', 'direccion' => 'Carretera Central Km 10', 'activo' => true]);

        // ── Productos ──
        $productosData = [
            [
                'codigo' => 'PROD001', 'nombre' => 'Leche Gloria Evaporada 400g',
                'marca_id' => $marcaGloria->id, 'categoria_id' => $catAbarrotes->id,
                'unidad_medida_id' => $uUnidad->id, 'precio_base' => 4.50,
            ],
            [
                'codigo' => 'PROD002', 'nombre' => 'Arroz Costeño x 1kg',
                'marca_id' => $marcaSanFernando->id, 'categoria_id' => $catAbarrotes->id,
                'unidad_medida_id' => $uKg->id, 'precio_base' => 3.80,
            ],
            [
                'codigo' => 'PROD003', 'nombre' => 'Aceite Primor x 1L',
                'marca_id' => $marcaNestle->id, 'categoria_id' => $catAbarrotes->id,
                'unidad_medida_id' => $uLitro->id, 'precio_base' => 8.50,
            ],
            [
                'codigo' => 'PROD004', 'nombre' => 'Gaseosa Coca-Cola 3L',
                'marca_id' => $marcaCocaCola->id, 'categoria_id' => $catBebidas->id,
                'unidad_medida_id' => $uLitro->id, 'precio_base' => 10.00,
            ],
            [
                'codigo' => 'PROD005', 'nombre' => 'Detergente Sapolio 1kg',
                'marca_id' => $marcaSapolio->id, 'categoria_id' => $catLimpieza->id,
                'unidad_medida_id' => $uKg->id, 'precio_base' => 6.20,
            ],
            [
                'codigo' => 'PROD006', 'nombre' => 'Leche Gloria Ideal 900g',
                'marca_id' => $marcaGloria->id, 'categoria_id' => $catAbarrotes->id,
                'unidad_medida_id' => $uUnidad->id, 'precio_base' => 8.90,
            ],
            [
                'codigo' => 'PROD007', 'nombre' => 'Fideos Don Vittorio x 500g',
                'marca_id' => $marcaNestle->id, 'categoria_id' => $catAbarrotes->id,
                'unidad_medida_id' => $uKg->id, 'precio_base' => 2.50,
            ],
            [
                'codigo' => 'PROD008', 'nombre' => 'Agua Cielo 2.5L',
                'marca_id' => $marcaCocaCola->id, 'categoria_id' => $catBebidas->id,
                'unidad_medida_id' => $uLitro->id, 'precio_base' => 3.00,
            ],
            [
                'codigo' => 'PROD009', 'nombre' => 'Yogurt Gloria Fresa x 1L',
                'marca_id' => $marcaGloria->id, 'categoria_id' => $catAbarrotes->id,
                'unidad_medida_id' => $uLitro->id, 'precio_base' => 7.50,
            ],
            [
                'codigo' => 'PROD010', 'nombre' => 'Lejía Sapolio x 1L',
                'marca_id' => $marcaSapolio->id, 'categoria_id' => $catLimpieza->id,
                'unidad_medida_id' => $uLitro->id, 'precio_base' => 4.90,
            ],
        ];

        foreach ($productosData as $data) {
            $producto = Producto::create($data);

            ProductoAlmacenStock::create([
                'producto_id' => $producto->id,
                'almacen_id' => $almacenPrincipal->id,
                'stock_actual' => 100,
                'stock_anterior' => 0,
                'stock_reservado' => 0,
                'stock_disponible' => 100,
                'stock_minimo' => 10,
                'stock_maximo' => 500,
            ]);
        }
    }
}
